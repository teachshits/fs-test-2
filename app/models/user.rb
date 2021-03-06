class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :rememberable, :trackable, :validatable

  attr_accessible :name, :locale, :email, :password, :password_confirmation, :remember_me

  has_many :events

  default_value_for :locale do
    I18n.locale || :en
  end

  def display_name
    name.blank? ? 'Anonymous' : name
  end
end
