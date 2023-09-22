# Steps for this tutorial

0. Create a file `terraform.tfvars` with a variable with the name `USER_DOMAIN_NAME` and a value of a domain of your choice. (hint use something postfixed with `.global.ssl.fastly.net` for a valid cert)
1. Add the file extension `.tf` to the file main.step1
2. Run `terraform apply`
3. remove the file extension `.tf` to the file main.step1

Repeat steps 1 through 3 for files `main.step2` and `main.step3`

Enjoy NGWAF!