pragma solidity ^0.8.11;
import "./Auth.sol";
import "./MerkleProof.sol"; // OZ: MerkleProof
import "./ERC20.sol";
import "./veAPHRA.sol";

contract AirdropClaim is Auth {

    /// ============ Immutable storage ============

    bytes32 public immutable merkleRoot;

    veAPHRA public _ve;
    ERC20 public immutable aphra;

    /// ============ Mutable storage ============

    mapping(address => bool) public hasClaimed;

    error AlreadyClaimed();
    error NotInMerkle();

    event Claim(address indexed to, uint256 amount);
    uint internal constant AIRDROP_LOCK = 2 * 365 * 86400;

    constructor(
        address GOVERNANCE_,
        bytes32 MERKLE_ROOT_,
        address veAPHRA_ADDR_
    ) Auth(GOVERNANCE_, Authority(address(0))) {
        merkleRoot = MERKLE_ROOT_;
        _ve = veAPHRA(veAPHRA_ADDR_);
        aphra = ERC20(_ve.token());
        aphra.approve(veAPHRA_ADDR_, type(uint).max);
    }

    //should the ve get updated before the system is crystalized ensure airdrop claimers can get their portion always
    function setNewVe(address veAPHRA_ADDR_) requiresAuth external {
        _ve = veAPHRA(veAPHRA_ADDR_);
        aphra.approve(veAPHRA_ADDR_, type(uint).max);
    }

    function claim(address to, uint256 amount, bytes32[] calldata proof) external {
        // Throw if address has already claimed tokens
        if (hasClaimed[to]) revert AlreadyClaimed();

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        // Set address to claimed
        hasClaimed[to] = true;

        // push tokens into veAPHRA lock expiring after 2 years,
        //congrats on the responsibility
        _ve.create_lock_for(amount, AIRDROP_LOCK, to);

        // Emit claim event
        emit Claim(to, amount);
    }
}
