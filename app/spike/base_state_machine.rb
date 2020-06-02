class BaseStateMachine < ApplicationRecord

  self.table_name = 'state_machine_proxies'



  belongs_to :thing

  include AASM


end
