import Config

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

# Use shoehorn to start the main application. See the shoehorn
# library documentation for more control in ordering how OTP
# applications are started and handling failures.

config :shoehorn, init: [:nerves_runtime, :nerves_pack]

# Erlinit can be configured without a rootfs_overlay. See
# https://github.com/nerves-project/erlinit/ for more information on
# configuring erlinit.

# Advance the system clock on devices without real-time clocks.
config :nerves, :erlinit, update_clock: true

# Configure the device for SSH IEx prompt access and firmware updates
#
# * See https://hexdocs.pm/nerves_ssh/readme.html for general SSH configuration
# * See https://hexdocs.pm/ssh_subsystem_fwup/readme.html for firmware updates

config :nerves_ssh,
  authorized_keys: [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIQPECDVXZ12V2Wuv09VVQJvJ/jBkBrI7EIhjZ0ayyuJqixag5ycpTPhsW1xUMgzu78m8OWJFWZgUdeegxbsHBlMWoTsGKwhOF5hoVoTtvWSTAe3vdkzxPptiKOlDPNgq3D0zkyuHL+nYEvkVnta0OsIZgjdqZrzJ+ci+fM7HdGHKyMLAuJGx0hDdROKr/5J/22oRcw/Lp78nbVHza4QAlFcRU56e3kO+l7hLgMIccOEs9tFOXZ29W1Kr6PYPAw5SB1tL5Up10TrfNDClD1sHQrRSoi0oZfgo7rFCFLgW8xQxXqDXm9O+Zh12RcBUfgBKL3o/xdVG1W+dyffTy1uH7ExolZM2BgwhA9istYADsX+pXwomdKHGpgki55ojn3+2NQnMik0ug+lX3G1Dm+iwWoKoiW1CIuFU1GilBcP0q1oa/qriI5MhD84xYjYrUFGVQgRYBQ+FEm7fooh5ZqkAw3XXJuEjbdB+YMtoGQVuyRvbHgJ44LlgmqFIAGHZXwms= ke@Q0H6M77WWM"
  ],
  daemon_option_overrides: [
    {:pwdfun, &NameBadge.ssh_check_pass/2},
    {:auth_method_kb_interactive_data, &NameBadge.ssh_show_prompt/3}
  ]

# Configure the network using vintage_net
#
# Update regulatory_domain to your 2-letter country code E.g., "US"
#
# See https://github.com/nerves-networking/vintage_net for more information
config :vintage_net,
  regulatory_domain: "00",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{method: :dhcp}
     }},
    {"wlan0", %{type: VintageNetWiFi}}
  ]

config :mdns_lite,
  # The `hosts` key specifies what hostnames mdns_lite advertises.  `:hostname`
  # advertises the device's hostname.local. For the official Nerves systems, this
  # is "nerves-<4 digit serial#>.local".  The `"nerves"` host causes mdns_lite
  # to advertise "nerves.local" for convenience. If more than one Nerves device
  # is on the network, it is recommended to delete "nerves" from the list
  # because otherwise any of the devices may respond to nerves.local leading to
  # unpredictable behavior.

  hosts: [:hostname, "wisteria"],
  ttl: 120,

  # Advertise the following services over mDNS.
  services: [
    %{
      protocol: "ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "sftp-ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "epmd",
      transport: "tcp",
      port: 4369
    }
  ]

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"

product_key = System.get_env("NH_PRODUCT_KEY")
product_secret = System.get_env("NH_PRODUCT_SECRET")

if product_key && product_secret do
  config :nerves_hub_link,
    host: "manage.nervescloud.com",
    shared_secret: [
      product_key: product_key,
      product_secret: product_secret
    ],
    geo: [
      resolver: NervesHubLink.Extensions.Geo.DefaultResolver
    ]
end
