# Have I Been Pwned on Fastly

This is a re-implementation of the (HaveIBeenPwned Pwned Password API)[https://haveibeenpwned.com/API/v3#PwnedPasswords] using Fastly Compute@Edge and Object Store.

# Quickstart

1. Clone the repo
2. Run `fastly compute serve`
3. Once the service is running locally run `curl http://127.0.0.1:7676/range/12345`

