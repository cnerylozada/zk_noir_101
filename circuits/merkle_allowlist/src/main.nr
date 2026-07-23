use dep::poseidon::poseidon::bn254;
use dep::trees::merkle::MerkleTree;
use dep::trees::types::{MembershipProver, MT_Creator};

fn main(raw_wallet: Field, indexes: Field, hash_path: [Field; 10], root: pub Field) {
    let leaf = bn254::hash_1([raw_wallet]);

    let tree = MerkleTree::from(root, |inputs| bn254::hash_2(inputs));
    tree.membership(leaf, indexes, hash_path);
}

#[test]
fn test_main() {
    let raw_wallet = 0xDE645d7DC8f33DbC92dd970d408A9f9cF50eCD1B as Field;
    let leaf = bn254::hash_1([raw_wallet]);

    let expected_leaf: Field =
        7294122652945475227447315622612477441561847781302591505036971739230526704607;
    assert(leaf == expected_leaf);
}
