Rails.application.routes.draw do
  root "csv_importer#index"

  post '/import', to: 'csv_importer#import'
  get '/download', to: 'csv_importer#download'
end
