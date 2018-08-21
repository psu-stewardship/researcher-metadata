namespace :import do
  desc 'Import Activity Insight users'
  task :ai_users, [:filename] => :environment do |_task, args|
    args.with_defaults(
      filename: filename_for(:ai_users)
    )
    ActivityInsightUserImporter.new(filename: args.filename).call
  end

  desc 'Import Activity Insight publications'
  task :ai_publications, [:filename] => :environment do |_task, args|
    args.with_defaults(
      filename: filename_for(:ai_publications)
    )
    ActivityInsightPublicationImporter.new(filename: args.filename).call
  end

  desc 'Import Activity Insight authorships'
  task :ai_authorships, [:filename] => :environment do |_task, args|
    args.with_defaults(
      filename: filename_for(:ai_authorships)
    )
    ActivityInsightAuthorshipImporter.new(filename: args.filename).call
  end

  desc 'Import Activity Insight contributors'
  task :ai_contributors, [:filename] => :environment do |_task, args|
    args.with_defaults(
      filename: filename_for(:ai_authorships)
    )
    ActivityInsightContributorImporter.new(filename: args.filename).call
  end

  desc 'Import Pure Users'
  task :pure_users, [:filename] => :environment do |_task, args|
    args.with_defaults(
      filename: filename_for(:pure_users)
    )
    PureUserImporter.new(filename: args.filename).call
  end

  desc 'Import Pure publications'
  task :pure_publications, [:dirname] => :environment do |_task, args|
    args.with_defaults(
      dirname: dirname_for(:pure_publications)
    )
    PurePublicationImporter.new(dirname: args.dirname).call
  end

  desc 'Import Pure publication tags'
  task :pure_publication_tags, [:filename] => :environment do |_task, args|
    args.with_defaults(
      filename: filename_for(:pure_publication_tags)
    )
    PurePublicationTagImporter.new(filename: args.filename).call
  end

  desc 'Import all data'
  task :all => :environment do
    PureUserImporter.new(
      filename: filename_for(:pure_users)
    ).call

    PurePublicationImporter.new(
      dirname: dirname_for(:pure_publications)
    ).call

    PurePublicationTagImporter.new(
      filename: filename_for(:pure_publication_tags)
    ).call

    ActivityInsightUserImporter.new(
      filename: filename_for(:ai_users)
    ).call

    ActivityInsightPublicationImporter.new(
      filename: filename_for(:ai_publications)
    ).call

    ActivityInsightAuthorshipImporter.new(
      filename: filename_for(:ai_authorships)
    ).call

    ActivityInsightContributorImporter.new(
      filename: filename_for(:ai_authorships)
    ).call
  end
end

def filename_for(key)
  case key
  when :pure_users then Rails.root.join('db/data/pure_users.json')
  when :pure_publication_tags then Rails.root.join('db/data/pure_publication_fingerprints.json')
  when :ai_users then Rails.root.join('db/data/ai_users.csv')
  when :ai_publications then Rails.root.join('db/data/ai_publications.csv')
  when :ai_authorships then Rails.root.join('db/data/ai_authorships.csv')
  end
end

def dirname_for(key)
  case key
  when :pure_publications then Rails.root.join('db/data/pure_publications')
  end
end
