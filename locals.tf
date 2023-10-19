locals {
  current_time           = timestamp()
  start_wallclock_time   = "3.55"
  current_wallclock_time = formatdate("h.mm", local.current_time)
  schedule_tomorrow      = (local.current_wallclock_time >= local.start_wallclock_time)
  today                  = formatdate("YYYY-MM-DD", local.current_time)
  tomorrow               = formatdate("YYYY-MM-DD", timeadd(local.current_time, "24h"))
  start_time             = "${local.schedule_tomorrow ? local.tomorrow : local.today}T03:55:00Z"
}

