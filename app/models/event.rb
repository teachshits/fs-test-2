# encoding: UTF-8
class Event < ActiveRecord::Base
  attr_accessible :date_str, :recurring, :schedule_type, :title

  # schedule_type constansts
  DAILY = 'daily'.freeze
  WEEKLY = 'weekly'.freeze
  MONTHLY = 'monthly'.freeze
  YEARLY = 'yearly'.freeze

  default_value_for :date do
    Date.today
  end
  
  validates :date, :title, presence: true

  belongs_to :user

  # select all one-time in specified range + all recurring events whose dates are already in the past
  def self.at_range(start_date, end_date)
    where('(events.date >= :start_date and events.date <= :end_date and events.recurring = :r_false)
           or
           (events.recurring = :r_true and events.date <= :end_date)',
          { start_date: start_date, end_date: end_date,
            r_false: false, r_true: true })
  end

  def date_str
    I18n.l(date)
  end

  def date_str=(date_string)
    self.date = Date.strptime(date_string, I18n.t('date.formats.default'))
  rescue ArgumentError, TypeError
    self.date = Date.today
  end

  def one_time?
    !recurring?
  end

  def classes(other_date = nil)
    klasses = %w(event)
    klasses << "event_#{id}"

    if recurring?
      klasses << 'recurring'
      klasses << schedule_type
      klasses << 'cloned' if other_date.present? && other_date != date
    end

    klasses
  end

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at], methods: :classes))
  end

  def occurs_on?(other_date)
    if recurring?
      # return false if event was created before `other_date`
      return false if other_date < date

      case schedule_type
      when DAILY then true
      when WEEKLY then date.wday == other_date.wday # compare only week days
      when MONTHLY then date.day == other_date.day # compare day of month
      when YEARLY then (date.day == other_date.day) && (date.month == other_date.month) # month + year
      else false
      end
    else
      date == other_date
    end
  end

  def daily?
    recurring? && schedule_type == DAILY
  end

  def weekly?
    recurring? && schedule_type == WEEKLY
  end

  def monthly?
    recurring? && schedule_type == MONTHLY
  end

  def yearly?
    recurring? && schedule_type == YEARLY
  end
end
