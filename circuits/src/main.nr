fn main(guess_hash: Field, answer_hash: pub Field, user_address: pub Field) {
    
    assert(guess_hash == answer_hash, "Guess hash does not match answer hash");


    // The following lines are not needed to bind the proof to the user's address—
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
