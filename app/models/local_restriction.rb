class LocalRestriction
  attr_reader :gss_code

  def initialize(gss_code)
    @gss_code = gss_code
    @time_zone = Time.find_zone("London")
  end

  def all_restrictions
    @all_restrictions ||= YAML.load_file(file_name)
  end

  def restriction
    all_restrictions[gss_code] || {}
  end

  def file_name
    "lib/local_restrictions/local-restrictions.yaml"
  end

  def area_name
    restriction["name"]
  end

  def current_alert_level
    current["alert_level"] if current.present?
  end

  def future_alert_level
    future["alert_level"] if future.present?
  end

  def current
    restrictions = restriction["restrictions"]
    current_restrictions = restrictions.select do |rest|
      start_date = @time_zone.parse("#{rest['start_date']} #{rest['start_time']}")
      start_date.past?
    end

    current_restrictions.max_by { |rest| rest["start_date"] }
  end

  def future
    restrictions = restriction["restrictions"]
    future_restrictions = restrictions.select do |rest|
      start_date = @time_zone.parse("#{rest['start_date']} #{rest['start_time']}")
      start_date.future?
    end

    future_restrictions.min_by { |rest| rest["start_date"] }
  end
end
