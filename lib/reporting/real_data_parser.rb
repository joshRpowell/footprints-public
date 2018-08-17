class RealDataParser

  def initialize(crafters, apprentices)
    @crafters = crafters
    @apprentices = apprentices
  end

  def software_apprentices_for(month, year)
    apprentices = @apprentices.select { |apprentice|
      apprentice[:position] == "developer"
    }

    apprentice_count = apprentices.select { |apprentice|
      (apprentice[:start_date]..apprentice[:end_date]).cover?(Date.parse("#{month}/#{year}"))
    }.count

    {"Software Apprentices"=> apprentice_count}
  end

  def all_crafters
    { "Software Crafters" => all_crafters_for_skill_level(2),
    "UX Crafters" => all_crafters_for_skill_level(1) }
  end

  def all_crafters_for_skill_level(skill_level)
    @crafters.select do |crafter|
      crafter[:skill] == skill_level
    end
  end

  def active_crafters_for(month, year)
    result = {"Software Crafters" => 0, "UX Crafters" => 0}

    active_crafters = @crafters.select do |crafter| 
      (crafter[:start_date]..end_of_employment(crafter)).cover?(Date.parse("#{month}/#{year}"))
    end

    active_crafters.each do |crafter|
      if crafter[:skill] == 2
        result["Software Crafters"] += 1
      elsif crafter[:skill] == 1
        result["UX Crafters"] += 1
      end
    end

    result
  end

  def end_of_employment(employee)
    employee[:end_date].nil? ? Date.parse("9999-12-31") : employee[:end_date]
  end
end