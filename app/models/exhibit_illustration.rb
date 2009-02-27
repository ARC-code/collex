##########################################################################
# Copyright 2009 Applied Research in Patacriticism and the University of Virginia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

class ExhibitIllustration < ActiveRecord::Base
  belongs_to :exhibit_element
  acts_as_list :scope => :exhibit_element
  
  def before_save
    if illustration_type == 'Internet Image'
      illustration_type = 0
    elsif illustration_type == 'Textual Illustration'
      illustration_type = 1
    elsif illustration_type == 'NINES Object'
      illustration_type = 2
    else
      illustration_type = -1
    end
  end
  
  def after_ﬁnd
    if illustration_type == 0
      illustration_type = 'Internet Image'
    elsif illustration_type == 1
      illustration_type = 'Textual Illustration'
    elsif illustration_type == 2
      illustration_type = 'NINES Object'
    else
      illustration_type = 'Unknown'
    end
  end
  
  def self.get_illustration_type_array
    return "['NINES Object', 'Internet Image', 'Textual Illustration' ]"
  end
  
  def self.get_illustration_type_array_with_exhibit
    return "['NINES Object', 'NINES Exhibit', 'Internet Image' ]"
  end
  
  def self.get_illustration_type_image
    return 'Internet Image';
  end
  
  def self.get_illustration_type_nines_obj
    return 'NINES Object';
  end
  
  def self.get_illustration_type_text
    return 'Textual Illustration';
  end
  
  def self.get_exhibit_type_text
    return 'NINES Exhibit';
  end
  
  def self.factory(element_id, pos)
    illustration = ExhibitIllustration.create(:exhibit_element_id => element_id, :illustration_type => self.get_illustration_type_nines_obj, :illustration_text => "", :caption1 => "", :caption2 => "", :image_width => 100, :link => "" )
    illustration.insert_at(pos)
    return illustration
  end
end
