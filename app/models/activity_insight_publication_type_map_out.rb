class ActivityInsightPublicationTypeMapOut
  def self.map(string)
    case string
    when 'Academic Journal Article', 'Professional Journal Article', 'Trade Journal Article'
      'Journal Article'
    when 'In-house Journal Article'
      'Journal Article, In House'
    when 'Abstract'
      'Abstract'
    when 'Blog'
      'Blog'
    when 'Book'
      'Book'
    when 'Chapter'
      'Book Chapter'
    when 'Book/Film/Article Review'
      'Book Review'
    when 'Conference Proceeding'
      'Conference Proceeding'
    when 'Encyclopedia/Dictionary Entry'
      'Encyclopedia Entry'
    when 'Extension Publication'
      'Extension Publication'
    when 'Magazine/Trade Publication'
      'Magazine/Trade Publication'
    when 'Manuscript'
      'Manuscript'
    when 'Newsletter'
      'Newsletter'
    when 'Newspaper Article'
      'Newspaper Article'
    else
      'Other'
    end
  end
end