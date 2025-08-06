use dep::keccak256;
fn main(guess_hash: Field, answer_double_hash: pub Field, user_address: pub Field) {


    // 1. Decompose the guess_hash (which is a Field) into its byte representation.
    // A Field element representing a hash is typically 32 bytes.
    let guess_hash_decomposed: [u8; 32] = guess_hash.to_be_bytes();

    // 2. Hash the decomposed guess_hash again using Keccak256.
    // The keccak256 function from the library expects an array of u8
    // and the message size (number of bytes to hash).
    // Since guess_hash_decomposed is a [u8; 32] array, the message_size is 32.
    let guess_double_hash_decomposed: [u8; 32] = keccak256::keccak256(guess_hash_decomposed, 32);

    // 3. Convert the resulting byte array (the double hash) back into a Field element.
    let guess_double_hash = Field::from_be_bytes(guess_double_hash_decomposed);

    // 4. Assert that the internally calculated double_hash of the guess
    // matches the publicly provided answer_double_hash.
    assert(guess_double_hash == answer_double_hash);

    // The following lines are not needed to bind the proof to the user's address
    // declaring user_address as 'pub' already ensures the proof is address-dependent.
    // These lines only add an explicit constraint on user_address, which is unnecessary
    // unless you want to enforce a specific property of the address in the circuit.
    let user_address_pow = user_address.pow_32(2);
    assert(user_address_pow == user_address.pow_32(2), "User address does not match its square");

}

// #[test]
// fn test_main() {
//     main(1, 2);

//     // Uncomment to make test fail
//     // main(1, 1);
// }
