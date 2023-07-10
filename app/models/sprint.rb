class Sprint < ApplicationRecord
  belongs_to :project, optional: true
  has_many :pairings
  has_many :developers
  has_many :pto_requests, :through => :developers

  def generate_pair_rotation_schedule
    developers = self.developers
    developers.each_slice(2) do |developers|
      Pairing.create!(sprint: self, developer1: developers.first, developer2: developers.second)
    end
  end


  def generate_pairings(developers)
    developers.combination(2).each do |developer1, developer2|
      Pairing.create(developer1: developer1, developer2: developer2, sprint: self)
    end
  end


  def create_pairings
    developers = self.developers
    # Sort developers by the number of unique developers they've paired with
    developers.sort_by! do |developer|
      developer.pairings.map { |pairing| [pairing.developer1_id, pairing.developer2_id] }.flatten.uniq.count
    end

    # Handle the case where there's an odd number of developers
    if developers.count.odd?
      # Find the developer who has been solo the least
      solo_developer = developers.min_by do |developer|
        developer.pairings.where(developer2_id: nil).count
      end
      Pairing.create!(sprint_id: self.id, developer1: solo_developer)
      # Remove the solo developer from the array
      developers.delete(solo_developer)
    end

    # Pair the remaining developers
    developers.each_slice(2) do |developer1, developer2|
      Pairing.create!(sprint_id: self.id, developer1: developer1, developer2: developer2)
    end
  end

  def self.create_pairings(developers, sprint_id)
    # Sort developers by the number of unique developers they've paired with
    developers.sort_by! do |developer|
      developer.pairings.map { |pairing| [pairing.developer1_id, pairing.developer2_id] }.flatten.uniq.count
    end

    # Handle the case where there's an odd number of developers
    if developers.count.odd?

      # Find the developer who has been solo the least
      solo_developer = developers.min_by do |developer|
        developer.pairings.where(developer2_id: nil).count
      end

      # Remove the solo developer from the array
      developers.delete(solo_developer)

      # Create a solo pairing for the solo developer
      Pairing.create!(sprint_id: sprint_id, developer1_id: solo_developer.id)
    end

    # Pair the remaining developers
    developers.each_slice(2) do |developer1, developer2|
      Pairing.create!(sprint_id: sprint_id, developer1_id: developer1.id, developer2_id: developer2.id)
    end
  end

end
