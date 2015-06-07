require 'time'

class Time

  module Abbrevs
    module German

      def self.format
        "Vor %i %s"
      end
      
      Second   = ["Sekunde", "Sekunden"]
      Minute   = ["Minute",  "Minuten"]
      Hour     = ["Stunde",  "Stunden"]
      Day      = ["Tag",     "Tagen"]
      Week     = ["Woche",   "Wochen"]
      Month    = ["Monat",   "Monate"]
      Year     = ["Jahr",    "Jahre"]
      Decade   = ["Dekade",  "Dekaden"]
      Century  = ["Jahrhundert", "Jahrhunderten"]
    end
  end
  
  module Units
    Second     = 1
    Minute     = Second  * 60
    Hour       = Minute  * 60
    Day        = Hour    * 24
    Week       = Day     * 7
    Month      = Week    * 4
    Year       = Day     * 365
    Decade     = Year    * 10
    Century    = Decade  * 10
    Millennium = Century * 10
    Eon        = 1.0/0

    def self.use_ago_abbrev=(obj)
      @ago_abbrev = obj
    end

    def self.ago_abbrev
      @ago_abbrev
    end
  end

  def time_ago_in_words
    time_difference = Time.now.to_i+1 - self.to_i
    unit = get_unit(time_difference)
    unit_difference = time_difference / Units.const_get(unit.capitalize)

    abbrev_unit(unit, unit_difference)
  end

  def time_ago_in_html
    %Q'<span class="timeago" title="#{iso8601}">#{time_ago_in_words}</span>'
  end

  private
  def abbrev_unit(unt, diff)
    ret = unt.to_s.downcase
    if abm = Units.ago_abbrev
      variants = abm.const_get(unt)
      str = if diff > 1 then variants.last else variants.first end
      abm.format % [diff, str]
    else
      ret
    end
  end

  def get_unit(time_difference)
    Units.constants.each_cons(2) do |con|
      return con.first if (Units.const_get(con[0])...Units.const_get(con[1])) === time_difference
    end
  end
end
