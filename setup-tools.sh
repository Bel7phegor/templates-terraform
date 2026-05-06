# Cài dependencies
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# Thêm HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com noble main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

# Cài đặt
sudo apt update && sudo apt-get install terraform

# Kiểm tra version
terraform -version