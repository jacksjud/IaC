/*
To use the module we made `v2module`, we setup our environment the same,
with a terraform block, our providers, variables we want to use, etc.
but then, we add a 'module' block:
*/



module "web_app_1" {
    source = "../v2module"

    # Input variables

    app_name = "web-app-1"
    instance_name = "site-web-app-1"
    env_name = "production"
    
}

module "web_app_1" {
    source = "../v2module"

    # Input variables

    app_name = "web-app-2"
    instance_name = "site-web-app-2"
    env_name = "production"
    
}