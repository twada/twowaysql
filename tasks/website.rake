remove_task :website
desc 'Generate and upload website files'
task :website => [:rcov_report, :ditz_report, :website_generate, :website_upload, :publish_docs]
