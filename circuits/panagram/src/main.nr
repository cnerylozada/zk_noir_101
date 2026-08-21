use dep::poseidon::poseidon::bn254;

fn main(
    user_wallet: Field,
    raw_guess: Field,
    answer_hash: pub Field,
    round_id: pub Field,
) -> pub Field {
    assert(bn254::hash_1([raw_guess]) == answer_hash);

    let nullifier = bn254::hash_2([user_wallet, round_id]);
    nullifier
}

#[test]
fn test_main() {}
