local mirror_host = os.getenv("MIRROR_HOSTNAME")
assert(mirror_host, "MIRROR_HOSTNAME env variable is not set")

local mirror_ssh_port = os.getenv("MIRROR_SSH_PORT")
assert(mirror_ssh_port, "MIRROR_SSH_PORT env variable is not set")

local connector_path = os.getenv("CONNECTOR_PATH")
assert(connector_path, "CONNECTOR_PATH env variable is not set")

local storage_path = os.getenv("STORAGE_PATH")
assert(storage_path, "STORAGE_PATH env variable is not set")

local overlay_path = os.getenv("OVERLAY_PATH")
assert(overlay_path, "OVERLAY_PATH env variable is not set")

local config_path = os.getenv("CONFIG_BASE_PATH")
assert(config_path, "CONFIG_BASE_PATH env variable is not set")
fsi_config_path = config_path .. "/fsi-server"

settings {
  logfile = "/var/log/lsyncd.log",
  statusFile = "/var/log/lsyncd-status.log",
  statusInterval = 20,
  insist = true
}

sync {
  default.rsync,
  source = connector_path,
  target = mirror_host .. ":" .. connector_path,
  delay = 120,
  maxProcesses = 1,
  rsync = {
    compress = false,
    archive = true,
    perms = true,
    owner = true,
    _extra = {"-a", "--itemize-changes", "--temp-dir=/tmp"},
    rsh = "ssh -q -p " .. mirror_ssh_port .. " -i /sync.key -o StrictHostKeyChecking=no"
  }
}

sync {
  default.rsync,
  source = storage_path .. "/metadata",
  target = mirror_host .. ":" .. storage_path .. "/metadata",
  delay = 120,
  maxProcesses = 1,
  rsync = {
    compress = false,
    archive = true,
    perms = true,
    owner = true,
    _extra = {"-a", "--itemize-changes", "--temp-dir=/tmp"},
    rsh = "ssh -q -p " .. mirror_ssh_port .. " -i /sync.key -o StrictHostKeyChecking=no"
  }
}

sync {
  default.rsync,
  source = overlay_path,
  target = mirror_host .. ":" .. overlay_path,
  delay = 120,
  maxProcesses = 1,
  rsync = {
    compress = false,
    archive = true,
    perms = true,
    owner = true,
    _extra = {"-a", "--itemize-changes", "--temp-dir=/tmp"},
    rsh = "ssh -q -p " .. mirror_ssh_port .. " -i /sync.key -o StrictHostKeyChecking=no"
  }
}

--[[
sync {
  default.rsync,
  source = fsi_config_path,
  target = mirror_host .. ":" .. fsi_config_path,
  delay = 120,
  maxProcesses = 1,
  exclude = {'licence.xml'},
  rsync = {
    compress = false,
    archive = true,
    perms = true,
    owner = true,
    _extra = {"-a", "--itemize-changes", "--temp-dir=/tmp"},
    rsh = "ssh -q -p " .. mirror_ssh_port .. " -i /sync.key -o StrictHostKeyChecking=no"
  }
}
--]]
