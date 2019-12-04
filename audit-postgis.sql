CREATE OR REPLACE FUNCTION audit.get_geometry_columns(schema_name text, table_name text)
RETURNS TABLE (column_name text, geometry_type text) AS $$
begin
    RETURN QUERY
    SELECT f_geometry_column::text as column_name, type::text as geometry_type
    FROM geometry_columns
    WHERE f_table_schema = schema_name
    AND f_table_name = table_name;
end
$$
language plpgsql
SET search_path = pg_catalog, public;

COMMENT ON FUNCTION audit.get_geometry_columns(text, text) IS 'Get geometry columns for a given table if any exist.';

CREATE OR REPLACE FUNCTION audit.cast_geojson_to_text(json_data jsonb, geometry_columns TEXT[] DEFAULT ARRAY['geometry']) RETURNS jsonb as $$
DECLARE
    geometry_column text;
    geometry_json jsonb := '{}'::jsonb;
begin
    FOREACH geometry_column IN ARRAY geometry_columns
    LOOP
        IF json_data->>geometry_column IS NOT NULL THEN
            geometry_json = geometry_json || jsonb_build_object(
                geometry_column,
                CAST(ST_GeomFromGeoJSON(json_data->>geometry_column) AS TEXT)
            );
        END IF;
    END LOOP;
    return json_data || geometry_json;
end
$$
language plpgsql;

COMMENT ON FUNCTION audit.cast_geojson_to_text(jsonb, TEXT[]) IS 'Convert GeoJSON back into WKB and cast it to text. This is because trying to copy the row of converted JSON into a table row will give an error if left as-is.';

-- Create trigger for convenience, don't have to modify audit functions if we add this trigger after
CREATE OR REPLACE FUNCTION audit.convert_geojson() RETURNS trigger AS $$
DECLARE
    geometry_columns text[];
BEGIN
    SELECT ARRAY_AGG(column_name) INTO geometry_columns FROM audit.get_geometry_columns(NEW.schema_name, NEW.table_name);
    -- If there are geometry columns, then convert all GeoJSON to text
    IF array_length(geometry_columns, 1) > 0 THEN
        NEW.row_data = audit.cast_geometry_to_text(NEW.row_data, geometry_columns);
        NEW.changed_fields = audit.cast_geometry_to_text(NEW.changed_fields, geometry_columns);
    END IF;
    RETURN NEW;
END
$$
language plpgsql
SECURITY DEFINER;

COMMENT ON FUNCTION audit.convert_geojson() IS 'Trigger to convert GeoJSON into WKB automatically when log is created';

CREATE TRIGGER convert_geojson BEFORE INSERT ON audit.logged_action FOR EACH ROW
EXECUTE PROCEDURE audit.convert_geojson();
