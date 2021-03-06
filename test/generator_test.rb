# frozen_string_literal: true

require 'fileutils'
require 'test_helper'

class GeneratorTest < Minitest::Test
  def setup
    @permanent_test_files = SafePath.new('permanent_test_files')
  end

  def teardown
    FileUtils.rm 'ABC_Collection-June-2020_03.hash.mapped.avro', force: true
    FileUtils.rm 'ABC_Collection-June-2020_03.hash.mapped.avsc', force: true

    FileUtils.rm 'ABC_Collection-June-2020_03.hash.raw.avro', force: true
    FileUtils.rm 'ABC_Collection-June-2020_03.hash.raw.avsc', force: true

    FileUtils.rm 'cross_worksheet_spreadsheet.hash.mapped.avro', force: true
    FileUtils.rm 'cross_worksheet_spreadsheet.hash.mapped.avsc', force: true

    FileUtils.rm 'cross_worksheet_spreadsheet.hash.raw.avro', force: true
    FileUtils.rm 'cross_worksheet_spreadsheet.hash.raw.avsc', force: true
  end

  def test_the_output_schemas
    generate_avro('ABC_Collection-June-2020_03.xlsm', 'national_collection.yml')

    read_avro('ABC_Collection-June-2020_03.hash.mapped.avro') do |datum_reader, data_file_reader|
      expected_schema = {
        type: 'record',
        name: 'Hash',
        fields: [
          { name: 'providercode', type: %w[string null] },
          { name: 'SQU03_5_3_1', type: %w[int null] },
          { name: 'SQU03_5_3_2', type: %w[int null] },
          { name: 'SQU03_6_2_1', type: [{ type: 'bytes', logicalType: 'decimal', precision: 6, scale: 4 }, 'null'] },
          { name: 'SQU03_6_2_2', type: [{ type: 'array', items: 'int' }, 'null'] },
          { name: 'K1N', type: %w[boolean null] },
          { name: 'K1M', type: [{ type: 'int', logicalType: 'date' }, 'null'] },
          { name: 'K150', type: %w[string null] },
          { name: 'K190', type: %w[string null] },
          { name: 'F1N', type: %w[string null] },
          { name: 'F1T', type: %w[string null] },
          { name: 'F1M', type: %w[string null] },
          { name: 'F190', type: %w[string null] },
          { name: 'P1B', type: %w[string null] },
          { name: 'P1N', type: %w[string null] }
        ]
      }.to_json

      assert_equal expected_schema, datum_reader.writers_schema.to_s
      assert_equal 1, data_file_reader.to_a.length
    end

    read_avro('ABC_Collection-June-2020_03.hash.raw.avro') do |datum_reader, data_file_reader|
      expected_schema = {
        type: 'record',
        name: 'Hash',
        fields: [
          { name: 'filename', type: %w[string null] },
          { name: 'squ03_5_3_1:n', type: %w[string null] },
          { name: 'squ03_5_3_2:n', type: %w[string null] },
          { name: 'squ03_6_2_1:n', type: %w[string null] },
          { name: 'squ03_6_2_2:n', type: %w[string null] },
          { name: 'k1n:n', type: %w[string null] },
          { name: 'k1m:d', type: %w[string null] },
          { name: 'k150:n', type: %w[string null] },
          { name: 'k190:n', type: %w[string null] },
          { name: 'f1n:n', type: %w[string null] },
          { name: 'f1t:n', type: %w[string null] },
          { name: 'f1m:n', type: %w[string null] },
          { name: 'f190:n', type: %w[string null] },
          { name: 'p1b:n', type: %w[string null] },
          { name: 'p1n:n', type: %w[string null] }
        ]
      }.to_json

      assert_equal expected_schema, datum_reader.writers_schema.to_s
      assert_equal 1, data_file_reader.to_a.length
    end
  end

  def test_a_tmpdir_output_path
    assert_equal Dir.tmpdir, SafePath.new('tmpdir').to_s

    Dir.mktmpdir do |dir|
      source_file = @permanent_test_files.join('ABC_Collection-June-2020_03.xlsm')
      table_mappings = @permanent_test_files.join('national_collection.yml')
      output_path = Pathname.new(dir)

      generator = NdrAvro::Generator.new(source_file, table_mappings, output_path)
      generator.process

      assert_equal [
        {
          path: output_path.join('ABC_Collection-June-2020_03.hash.mapped.avro'),
          schema: output_path.join('ABC_Collection-June-2020_03.hash.mapped.avsc'),
          total_rows: 1
        },
        {
          path: output_path.join('ABC_Collection-June-2020_03.hash.raw.avro'),
          schema: output_path.join('ABC_Collection-June-2020_03.hash.raw.avsc'),
          total_rows: 1
        }
      ], generator.output_files
    end
  end

  def test_complex_data_types
    generate_avro('ABC_Collection-June-2020_03.xlsm', 'national_collection.yml')

    read_avro('ABC_Collection-June-2020_03.hash.mapped.avro') do |_datum_reader, data_file_reader|
      first_row = data_file_reader.to_a.first
      # :decimal data type
      assert_kind_of BigDecimal, first_row['SQU03_6_2_1']
      # :array data type
      assert_equal [14, 15, 16], first_row['SQU03_6_2_2']
    end

    read_avro('ABC_Collection-June-2020_03.hash.raw.avro') do |_datum_reader, data_file_reader|
      first_row = data_file_reader.to_a.first
      # :decimal data type
      assert_equal '13.2134', first_row['squ03_6_2_1:n']
      # :array data type
      assert_equal '14,15,16', first_row['squ03_6_2_2:n']
    end
  end

  def tst_cross_worksheet_klass
    generate_avro('cross_worksheet_spreadsheet.xlsx', 'cross_worksheet_mapping.yml')

    read_avro('cross_worksheet_spreadsheet.hash.mapped.avro') do |datum_reader, data_file_reader|
      expected_schema = {
        type: 'record',
        name: 'Hash',
        fields: [
          { name: 'COMMON1', type: %w[string null] },
          { name: 'COMMON2', type: %w[string null] },
          { name: 'FIRST', type: %w[string null] },
          { name: 'SECOND', type: %w[string null] },
          { name: 'THIRD', type: %w[string null] }
        ]
      }.to_json

      assert_equal expected_schema, datum_reader.writers_schema.to_s
      assert_equal 7, data_file_reader.to_a.length
    end

    read_avro('cross_worksheet_spreadsheet.hash.raw.avro') do |datum_reader, data_file_reader|
      expected_schema = {
        type: 'record',
        name: 'Hash',
        fields: [
          { name: 'common1', type: %w[string null] },
          { name: 'common2', type: %w[string null] },
          { name: 'sheet1_first', type: %w[string null] },
          { name: 'sheet1_second', type: %w[string null] },
          { name: 'sheet2_third', type: %w[string null] }
        ]
      }.to_json
      rows = data_file_reader.to_a

      assert_equal expected_schema, datum_reader.writers_schema.to_s
      assert_equal %w[Sheet1_2A_Common Sheet1_2A_Common Sheet1_3A_Common Sheet1_3A_Common
                      Sheet2_2A_Common Sheet2_3A_Common Sheet2_4A_Common],
                   (rows.map { |row| row['common1'] })

      assert_equal [nil, nil, nil, nil, 'Sheet2_2C_Third', 'Sheet2_3C_Third', 'Sheet2_4C_Third'],
                   (rows.map { |row| row['sheet2_third'] })
    end
  end

  private

    def read_avro(filename)
      # Open items.avro file in read mode
      file = File.open(filename, 'rb')

      # Create an instance of DatumReader
      datum_reader = Avro::IO::DatumReader.new

      # Equivalent to DataFileReader instance creation in Java
      data_file_reader = Avro::DataFile::Reader.new(file, datum_reader)

      yield datum_reader, data_file_reader

      # Close the input file
      data_file_reader.close
      file.close
    end

    def generate_avro(source_file, table_mappings)
      generator = NdrAvro::Generator.new(@permanent_test_files.join(source_file),
                                         @permanent_test_files.join(table_mappings))
      generator.process
    end
end
