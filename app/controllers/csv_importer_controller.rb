class CsvImporterController < ApplicationController
  def index
  end

  def import
    items = []
    CSV.foreach(params[:filename].tempfile, headers: true) do |row|
      r = row.to_h
      timezone = DateTime.parse(r['timezone'])
      timezone_formatted = Time.at((timezone.to_time.to_i / 900).round * 900)
      r['timezone'] = timezone_formatted
      items << r
    end

    @a = items.group_by { |item| item['timezone'] }
    keys = @a.keys

    grouped_by = keys.map do |key|
      @a[key].group_by { |element| element['proc_user_classification'] }
    end

    items_to_write = []
    grouped_by.each_with_index do |hour, index|
      lines = hour.count
      classifications = hour.keys
      hash = {
        hour: hour.values.first.first['timezone'].strftime('%Y-%m-%d %H:%M:%S'),
        lines: lines,
        starting_from: 1,
        classifications: []
      }

      classifications.each do |classification|
        hash[:classifications] << {
          classification: classification,
          quantity: hour[classification].count
        }
      end

      if index.nonzero?
        h = items_to_write[0..index - 1].sum { |e| e[:lines] } + 1
        hash[:starting_from] = h
      end

      items_to_write << hash
    end

    workbook = WriteXLSX.new('report.xlsx')
    worksheet = workbook.add_worksheet

    format = workbook.add_format
    format.set_bold
    format.set_color('black')
    format.set_bg_color('grey')
    format.set_align('center')

    format2 = workbook.add_format
    format.set_align('center')

    worksheet.write(0, 0, 'DATA', format)
    worksheet.write(0, 1, 'CLASSIFICAÇÃO', format)
    worksheet.write(0, 2, 'QUANTIDADE', format)

    items_to_write.each do |item|
      item[:classifications].each_with_index do |element, i|
        worksheet.write(item[:starting_from] + i, 0, item[:hour], format2)
        worksheet.write(item[:starting_from] + i, 1, element[:classification], format2)
        worksheet.write(item[:starting_from] + i, 2, element[:quantity], format2)
      end
    end

    workbook.close
  end

  def download
    send_file("#{Rails.root}/report.xlsx", filename: "report.xlsx", type: "application/xlsx")
  end
end