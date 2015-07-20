#coding: utf-8

# all limits are in seconds
t = Time.now.month*100 + Time.now.day
if t >= 528 && t <= 902
  # summer
  DAILY_LIMIT_WORKDAYS = 3600*4
  DAILY_LIMIT_WEEKENDS = 3600*4
else
  # all other year
  DAILY_LIMIT_WORKDAYS = 3600*2
  DAILY_LIMIT_WEEKENDS = 3600*3
end

def limit
  t1 = Time.now
  (t1.sunday? || t1.saturday?) ? DAILY_LIMIT_WEEKENDS : DAILY_LIMIT_WORKDAYS
end

