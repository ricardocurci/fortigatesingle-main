data "ibm_is_ssh_key" "ssh_key" {
  name = var.ssh_public_key
}

resource "ibm_is_volume" "logDisk" {
  // Name must be lower case
  name    = "${var.cluster_name}-logdisk-${random_string.random_suffix.result}"
  profile = "10iops-tier"
  zone    = var.zone1
}

resource "ibm_is_floating_ip" "publicip" {
  name   = "${var.cluster_name}-publicip-${random_string.random_suffix.result}"
  target = ibm_is_instance.fgt1.primary_network_interface[0].id
}

resource "ibm_is_instance" "fgt1" {
  name    = "${var.cluster_name}-fortigate-${random_string.random_suffix.result}"
  image   = ibm_is_image.vnf_custom_image.id
  profile = var.profile
  resource_group = var.resource_group_fortigate

  primary_network_interface {
    name            = "${var.cluster_name}-port1-${random_string.random_suffix.result}"
    subnet          = data.ibm_is_subnet.subnet1.id
    security_groups = [data.ibm_is_security_group.fgt_security_group.id]
  }

  network_interfaces {
    name            = "${var.cluster_name}-port2-${random_string.random_suffix.result}"
    subnet          = data.ibm_is_subnet.subnet2.id
    security_groups = [data.ibm_is_security_group.fgt_security_group.id]
  }

  volumes = [ibm_is_volume.logDisk.id]

  vpc       = data.ibm_is_vpc.vpc1.id
  zone      = var.zone1
  user_data = data.template_file.userdata.rendered
  keys      = [data.ibm_is_ssh_key.ssh_key.id]
}
// Use for bootstrapping cloud-init
data "template_file" "userdata" {
  template = file(var.user_data)
}
