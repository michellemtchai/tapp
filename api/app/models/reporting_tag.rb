# frozen_string_literal: true

# A class representing a reporting tag for tables such as
#   wage_chunk and position.
class ReportingTag < ApplicationRecord
    has_and_belongs_to_many :wage_chunks
    has_and_belongs_to_many :positions
end

# == Schema Information
#
# Table name: reporting_tags
#
#  id         :bigint(8)        not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
