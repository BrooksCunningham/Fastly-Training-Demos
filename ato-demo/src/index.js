/// <reference types="@fastly/js-compute" />

addEventListener("fetch", (event) => event.respondWith(handleRequest(event)));

// const usernames_passwords = [
//   { name: 'Name1', guid: 'randomguid1' },
//   { name: 'Name2', guid: 'randomguid2' },
//   many more entries
// ];

const usernames_passwords = [{"name":"Amity","guid":"260BA6F0-9784-CB9C-8EB5-76E5D635E9D7"},{"name":"Eagan","guid":"34D154BC-F9DC-C7F4-5467-5D62A4FBC839"},{"name":"Dillon","guid":"F18A4EC8-2EA3-9B14-C316-01B9CA2A63B2"},{"name":"Grady","guid":"3D14D37E-1AA7-6B5B-5624-7843B6B20D5E"},{"name":"Rhiannon","guid":"35103DBC-B4A9-661A-C4BB-87D7BB83855E"},{"name":"Erasmus","guid":"BA62E47E-03CD-E224-2066-95AFB57D5283"},{"name":"Sasha","guid":"76EAA8A1-760C-A6CE-0BC8-C356257CA10A"},{"name":"Kyle","guid":"7A6BEB2C-8A17-A219-62C6-DCCEF7237E38"},{"name":"Sybil","guid":"4CEF92A3-1252-23E4-48EE-43510AA84DC1"},{"name":"Isabelle","guid":"1597E526-4389-BC99-806F-210C16B3BE9E"},{"name":"Porter","guid":"7ACE3B47-9517-D81B-3E88-BDC8B238A262"},{"name":"Leigh","guid":"437BAD9E-1DC9-E3D8-6C66-B9355F251A62"},{"name":"Richard","guid":"C27BC465-D6FA-B32B-8079-2F335AA434BA"},{"name":"Winter","guid":"1A2D4783-E2D4-7259-9147-94AEE1D44174"},{"name":"Channing","guid":"38D6C525-20E1-5336-6384-9D7229DF2D5B"},{"name":"Desirae","guid":"A34228B8-696C-E24E-FEB3-B37FDB64E3C9"},{"name":"Hayley","guid":"88AA142C-5C3D-F3E1-D95B-1DDEB83682AB"},{"name":"Leo","guid":"BCD14915-DD78-BD1E-A119-9759143F7E58"},{"name":"Xavier","guid":"C91C3174-E827-16E9-0E76-BEA6EA0C2699"},{"name":"Grady","guid":"EFC47229-0CAE-F235-481A-DB8AF766497A"},{"name":"Deacon","guid":"954BBEAD-BA4D-E065-A954-1EDDF6C178D1"},{"name":"Addison","guid":"3DBA9927-C983-7443-D1B0-E2CA11AD9CF2"},{"name":"Sonya","guid":"331DF1BF-C45C-8BD8-4F7E-9DEACC552EC2"},{"name":"Erica","guid":"75996CCD-7F7B-7E0A-97C3-91BE1CC765E8"},{"name":"Kirk","guid":"D9A7835E-0269-612F-587B-224B1932BD46"},{"name":"Aurora","guid":"636C552F-CC60-EAA2-9919-79BEAA8B3955"},{"name":"Aimee","guid":"B117E16A-CBA3-5B5C-EE5A-2EC40717D46C"},{"name":"Dana","guid":"D5E3EDD7-07F9-29C0-34FB-CF56D04C951A"},{"name":"Simon","guid":"C06551C3-84AF-C3BA-7204-554B16E639BB"},{"name":"Hiroko","guid":"D355C73D-6444-2459-B9DB-A82B4D9C3977"},{"name":"Jeanette","guid":"33D31D8E-794B-D086-076D-8C08A9CC8283"},{"name":"Leslie","guid":"79109859-A99A-4FAE-9160-FC64D4A66557"},{"name":"Petra","guid":"23C984A3-9AD3-72D2-9607-A7BD3137C7E3"},{"name":"Megan","guid":"1294E2AC-4772-F1A8-D18E-B1D4717CD6E2"},{"name":"Amir","guid":"85DC47E4-7829-C25B-D437-92C95E129A5C"},{"name":"Xantha","guid":"4BBB118F-7DED-E6EE-C6B7-5AA73B84B9CF"},{"name":"Simone","guid":"44925243-E3E6-47F4-54B2-3D788F4E0C22"},{"name":"Hyacinth","guid":"CF1830DC-559A-FA38-3CE4-A2A2F7AAEB76"},{"name":"Marcia","guid":"3C814979-CEA1-6A58-35EF-45822543B81B"},{"name":"Chava","guid":"7B116A67-76C4-19D4-56A5-81617B24C524"},{"name":"Colleen","guid":"299A94B1-FA3C-4662-AEEB-A1C4C38C2E19"},{"name":"Beck","guid":"D35E9EF8-DAD3-0514-17C2-78FEBB2285D6"},{"name":"Beau","guid":"A32684A9-9CE3-ABD1-7488-3822416D891D"},{"name":"Ronan","guid":"BABBD92C-F176-58B5-4C65-B59E521BC354"},{"name":"Felix","guid":"1612EC9E-9B14-5EEB-AC57-67857854051D"},{"name":"Lois","guid":"59B66062-0AD6-59CC-D86F-B1D238520D89"},{"name":"Timon","guid":"D2902125-399D-1E3E-3F53-C781F08122EA"},{"name":"Zane","guid":"D890851D-D8A3-9EDD-A75D-075A7183BEE2"},{"name":"Martha","guid":"D1598434-DD98-240D-AD87-E00ECA8283CE"},{"name":"Alexander","guid":"C8986DF8-67C7-442E-B7D3-962C3CC35CED"},{"name":"Linus","guid":"89B0DE11-BB26-23D2-688F-7438AD0B8273"},{"name":"Willa","guid":"E94DB2DB-2D9A-2AA4-74E1-DF62FC15434B"},{"name":"Jameson","guid":"1B2559BB-E9CB-FEAE-8814-EF14F78E25C7"},{"name":"Rhea","guid":"F3C5AADE-E22C-BECB-0021-011D75584123"},{"name":"Tad","guid":"1856EE33-7B90-3705-1377-82CD68E99D03"},{"name":"Beverly","guid":"16FB65A6-E083-3B5E-CDC3-2ED6A43C75A1"},{"name":"Cassandra","guid":"81464AB8-60CC-9BF5-744D-C2BE2172E169"},{"name":"Eve","guid":"3FE232C5-7DC2-173A-2257-58A87D33A5DB"},{"name":"Malcolm","guid":"554D7D8F-0324-8E54-A328-D3731954336A"},{"name":"Harper","guid":"C801F5B5-46BD-1894-7B91-DB29EBF4737D"},{"name":"Olga","guid":"26B7FF83-5B95-3D46-B242-BDC6339A5BD2"},{"name":"Ulysses","guid":"6E257D75-85AE-8CB1-3798-FB94792D9915"},{"name":"Tobias","guid":"993F99B2-E0D8-2B54-C524-F336A9862A5F"},{"name":"Florence","guid":"0654AC1D-CCB8-5036-CAD2-67C0A7B75520"},{"name":"Illiana","guid":"E5BA5467-9E36-2D69-9CA2-CCCBEE94DEE9"},{"name":"Darius","guid":"D8590C61-C879-226B-1EC5-EA6E741E81AF"},{"name":"Ainsley","guid":"3BC41142-01E4-4F64-3BFE-13EAB0D97BEE"},{"name":"Hilel","guid":"FDBB3186-5D54-1B28-4919-C6BAA4FEEDB2"},{"name":"Xaviera","guid":"5DD81560-7FE6-7EB3-CEA2-DCECB5ED6424"},{"name":"Xena","guid":"1C8DB479-B910-BDA7-3D9B-C36C78BB11BD"},{"name":"Wylie","guid":"689257E5-4671-D420-D32C-1FB09DD22532"},{"name":"Abel","guid":"6FC33E1D-ADA8-7E89-48EC-C66E2D6CD35E"},{"name":"Moses","guid":"2C1A07A3-664C-885B-9ED9-76B0BA44C895"},{"name":"Octavius","guid":"3271550E-3E63-2C83-C721-141A6611774C"},{"name":"Bree","guid":"3C8B078C-EBA7-A978-8309-D0BF3C7E295B"},{"name":"Brennan","guid":"1C8DAEA9-2A5C-C45C-872F-901DF3D59193"},{"name":"Carol","guid":"10C49327-3120-A0EB-A58E-FB893C666A7C"},{"name":"Chester","guid":"35948E31-D59D-60D6-71EE-E6793C796DA4"},{"name":"Briar","guid":"3AEFDE44-A234-BDEC-B414-E472A9A420EC"},{"name":"Evangeline","guid":"92555D2E-A53D-DE6D-51AC-F1A7818C8AD3"},{"name":"Jarrod","guid":"53ED46B3-87E2-B9BA-D8ED-174783176707"},{"name":"Shelley","guid":"73AAEB5E-9BE8-59A2-E117-482ACEAB1378"},{"name":"Carson","guid":"479FB948-5D7E-A1FB-AC6D-6730D179C845"},{"name":"Armand","guid":"CB44F969-231B-EFB7-0D9C-26A23E82DE7B"},{"name":"Selma","guid":"96EEB11D-2C73-8C01-0862-9660ABAB832E"},{"name":"Teagan","guid":"8F897D17-D9D1-9785-DCA5-54ACC99BF872"},{"name":"Hillary","guid":"3BAC3351-7EE4-CC6D-F4A2-C52DD4C3256C"},{"name":"Samuel","guid":"BD272B12-9353-7202-242A-D834C2A7C423"},{"name":"Jessica","guid":"73BC0223-AC86-B3EF-EECE-C3BD3B8680B1"},{"name":"Maya","guid":"E9B6C138-5442-A6EF-A917-D2B6D4048775"},{"name":"Melvin","guid":"0FAAEEBA-8426-C192-606A-E9869C08856E"},{"name":"Brenna","guid":"61A88C32-E66A-009B-E35F-F734EE5F42AC"},{"name":"Illana","guid":"DE95C422-AF13-9163-8C31-22CADB4CE94A"},{"name":"Dawn","guid":"A8B3C5AA-DB42-7240-A69B-EA81E3D1CDF2"},{"name":"Felix","guid":"A3745F0E-15FC-C6AB-197D-13215A7CC94C"},{"name":"Lucian","guid":"CDE58DD5-AB5E-17AB-9292-AC3E138863B6"},{"name":"Hollee","guid":"8D3EAFD5-E544-0159-C242-59520C30FFEA"},{"name":"Zeus","guid":"AE8C4D9A-E4E3-5329-19CF-D2358AEAD120"},{"name":"Phoebe","guid":"D2158638-8D83-668E-3521-2F96B2CA0BCB"},{"name":"Grant","guid":"9ECD8936-DA9D-90A5-33FB-3072796C6B26"}];


async function handleRequest(event) {

  let req = event.request;

  if (req.headers.get("secret-key") == "mysecret"){
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
      const number = getRandomInt(2) === 0 ? 200 : 401;
  
      // Construct the JSON body
      const jsonBody = JSON.stringify({
        username: usernames_password.name,
        password: usernames_password.guid,
      });
  
      // Send the HTTP POST request
      const url = 'https://http.edgecompute.app/anything/login';
      const reqHeaders = {
        'Content-Type': 'application/json',
        'endpoint': `status=${number}`
      };
  
      // Perform the POST request and check the response
      const response = fetch(url, {
        method: 'POST',
        headers: reqHeaders,
        body: jsonBody,
        backend: 'origin_0',
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