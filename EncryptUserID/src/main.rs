use fastly::http::{Method, StatusCode};
use fastly::{Error, SecretStore, Request, Response};

extern crate crypto;
use crypto::{ symmetriccipher, buffer, aes, blockmodes };
use crypto::buffer::{ ReadBuffer, WriteBuffer, BufferResult };

extern crate rand;

use hex::FromHex;

use serde;

const BACKEND_APP_SERVER: &str = "httpme";

// Encrypt a buffer with the given key and iv using
// AES-256/CBC/Pkcs encryption.
fn encrypt(data: &[u8], key: &[u8], iv: &[u8]) -> Result<Vec<u8>, symmetriccipher::SymmetricCipherError> {

    // Create an encryptor instance of the best performing
    // type available for the platform.
    let mut encryptor = aes::cbc_encryptor(
            aes::KeySize::KeySize256,
            key,
            iv,
            blockmodes::PkcsPadding);

    // Each encryption operation encrypts some data from
    // an input buffer into an output buffer. Those buffers
    // must be instances of RefReaderBuffer and RefWriteBuffer
    // (respectively) which keep track of how much data has been
    // read from or written to them.
    let mut final_result = Vec::<u8>::new();
    let mut read_buffer = buffer::RefReadBuffer::new(data);
    let mut buffer = [0; 4096];
    let mut write_buffer = buffer::RefWriteBuffer::new(&mut buffer);

    // Each encryption operation will "make progress". "Making progress"
    // is a bit loosely defined, but basically, at the end of each operation
    // either BufferUnderflow or BufferOverflow will be returned (unless
    // there was an error). If the return value is BufferUnderflow, it means
    // that the operation ended while wanting more input data. If the return
    // value is BufferOverflow, it means that the operation ended because it
    // needed more space to output data. As long as the next call to the encryption
    // operation provides the space that was requested (either more input data
    // or more output space), the operation is guaranteed to get closer to
    // completing the full operation - ie: "make progress".
    //
    // Here, we pass the data to encrypt to the enryptor along with a fixed-size
    // output buffer. The 'true' flag indicates that the end of the data that
    // is to be encrypted is included in the input buffer (which is true, since
    // the input data includes all the data to encrypt). After each call, we copy
    // any output data to our result Vec. If we get a BufferOverflow, we keep
    // going in the loop since it means that there is more work to do. We can
    // complete as soon as we get a BufferUnderflow since the encryptor is telling
    // us that it stopped processing data due to not having any more data in the
    // input buffer.
    loop {
        let result = encryptor.encrypt(&mut read_buffer, &mut write_buffer, true)?;

        // "write_buffer.take_read_buffer().take_remaining()" means:
        // from the writable buffer, create a new readable buffer which
        // contains all data that has been written, and then access all
        // of that data as a slice.
        final_result.extend(write_buffer.take_read_buffer().take_remaining().iter().map(|&i| i));

        match result {
            BufferResult::BufferUnderflow => break,
            BufferResult::BufferOverflow => { }
        }
    }

    Ok(final_result)
}

// Decrypts a buffer with the given key and iv using
// AES-256/CBC/Pkcs encryption.
//
// This function is very similar to encrypt(), so, please reference
// comments in that function. In non-example code, if desired, it is possible to
// share much of the implementation using closures to hide the operation
// being performed. However, such code would make this example less clear.
fn decrypt(encrypted_data: &[u8], key: &[u8], iv: &[u8]) -> Result<Vec<u8>, symmetriccipher::SymmetricCipherError> {
    let mut decryptor = aes::cbc_decryptor(
            aes::KeySize::KeySize256,
            key,
            iv,
            blockmodes::PkcsPadding);

    let mut final_result = Vec::<u8>::new();
    let mut read_buffer = buffer::RefReadBuffer::new(encrypted_data);
    let mut buffer = [0; 4096];
    let mut write_buffer = buffer::RefWriteBuffer::new(&mut buffer);

    loop {
        let result = decryptor.decrypt(&mut read_buffer, &mut write_buffer, true)?;
        final_result.extend(write_buffer.take_read_buffer().take_remaining().iter().map(|&i| i));
        match result {
            BufferResult::BufferUnderflow => break,
            BufferResult::BufferOverflow => { }
        }
    }

    Ok(final_result)
}

#[derive(serde::Deserialize)]
struct UserIdData {
    userid: String,
    password: String,
}

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    // let message = "Secret Message from Fastly";

    // In a real program, the key and iv may be determined
    // using some other mechanism. If a password is to be used
    // as a key, an algorithm like PBKDF2, Bcrypt, or Scrypt (all
    // supported by Rust-Crypto!) would be a good choice to derive
    // a password. For the purposes of this example, the key and
    // iv are just random values.

    // Generate a key and IV with a similar command as the following.
    // openssl enc -nosalt -aes-256-cbc -pbkdf2 -k example -P
    // let enc_key_hex = "7ECEA90030826D5326D2C61341B0C1FD02AEE6B58C2FC4D5C9552C50FCB0E44D";
    // let enc_iv_hex = "F2F8B61408F67638B6FBEEB2348F0B5B";

    // Open the SecretStore and get the encryption key and iv for symmetric encryption.
    let mut secrets = SecretStore::open("encryption-key-store")?;
    let enc_key_vec = <[u8; 32]>::from_hex(secrets.get("enc_key_hex").unwrap().plaintext())?;
    let enc_iv_vec = <[u8; 16]>::from_hex(secrets.get("enc_iv_hex").unwrap().plaintext())?;

    // println!("{}", "Trying to decrypt and encrypt");
    // encrypt the data
    // let encrypted_data = encrypt(message.as_bytes(), &enc_key_vec, &enc_iv_vec).ok().unwrap();

    // println!("ciphertext as hex {:?}", hex::encode(&encrypted_data));
    // Use the following command to check the decryption locally.
    // echo -n 945cd26352c167c07170e1ea4ced2fffa63455221a9f65968ebf866a2d63ac24 \
    // | xxd -r -p \
    // | openssl enc -nosalt -aes-256-cbc -d \
    //     -K 7ECEA90030826D5326D2C61341B0C1FD02AEE6B58C2FC4D5C9552C50FCB0E44D \
    //     -iv F2F8B61408F67638B6FBEEB2348F0B5B 
    // let decrypted_data = decrypt(&encrypted_data[..], &enc_key_vec, &enc_iv_vec).ok().unwrap();
    // let decrypted_data_string = String::from_utf8_lossy(&decrypted_data);

    // println!("Decrypted Data: {}", decrypted_data_string);

    // add the encrypted userid as a request header.
    // req.set_header("enc-data", hex::encode(&encrypted_data));

    // To locally test, send a request like the following `curl http://127.0.0.1:7676/anything/ -i -d "userid=foo&password=mybar"`
    if req.get_method() == Method::POST && req.get_path() == "/anything/" {
        let mut form_req = req.clone_with_body();
        let form_data = form_req.take_body_form::<UserIdData>().unwrap();
        let encrypted_userid = encrypt(&form_data.userid.as_bytes(), &enc_key_vec, &enc_iv_vec).ok().unwrap();
        

        println!("form_data.userid: {:?}", &form_data.userid);
        println!("form_data.password: {:?}", &form_data.password);
        println!("encrypted_userid: {:?}", hex::encode(&encrypted_userid));

        // Add the encrypted userid as a header before sending the request to the origin
        req.set_header("enc-userid", hex::encode(&encrypted_userid));
        req.set_header("host", "http-me.glitch.me");
        return Ok(req.send(BACKEND_APP_SERVER)?)

    }

    Ok(Response::from_status(StatusCode::OK))
}
