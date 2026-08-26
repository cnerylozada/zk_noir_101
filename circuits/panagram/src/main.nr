use dep::poseidon::poseidon::bn254;

fn main(
    raw_guess: Field,
    user_wallet: pub Field,
    answer_hash: pub Field,
    round_id: pub Field,
) -> pub Field {
    assert(bn254::hash_1([raw_guess]) == answer_hash);

    let nullifier = bn254::hash_2([user_wallet, round_id]);
    nullifier
}

#[test]
fn test_main() {
    let raw_guess = 7815262006992268911;
    let user_wallet = 1269634169887741580881979353044297637055233523712;
    let answer_hash = bn254::hash_1([7815262006992268911]);
    let round_id = 100;

    let expected_nullifier = bn254::hash_2([user_wallet, round_id]);

    let nullfier = main(raw_guess, user_wallet, answer_hash, round_id);
    println(f"nullfier: {nullfier}");

    assert(expected_nullifier == nullfier);
}
