// contracts/claim/SuperRareTokenMerkleDrop.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract CollectorRoyaltiesClaim is Initializable, OwnableUpgradeable {
    bytes32 public claimRoot;
    mapping(address => mapping(uint256 => bool)) public rewardClaimedForClaim;
    uint256 public currentClaimId;
    bool public paused;

    event RoyaltyClaimed(
        bytes32 indexed root,
        address indexed addr,
        uint256 indexed claimId,
        uint256 amt
    );

    event NewClaim(uint256 indexed claimId, bytes32 indexed root);

    modifier notPaused() {
        require(!paused, "Cannot call when contract is paused.");
        _;
    }

    function initialize(bytes32 merkleRoot) public initializer {
        require(merkleRoot != bytes32(0), "MerkleRoot cant be empty.");

        __Ownable_init();
        claimRoot = merkleRoot;
        currentClaimId = 0;
        paused = false;
    }

    function claim(uint256 amount, bytes32[] calldata proof) public notPaused {
        require(
            verifyEntitled(_msgSender(), amount, proof),
            "The proof could not be verified."
        );
        require(
            !rewardClaimedForClaim[_msgSender()][currentClaimId],
            "You have already withdrawn your entitled token."
        );

        rewardClaimedForClaim[_msgSender()][currentClaimId] = true;

        address payable sender = _msgSender();

        sender.transfer(amount);
        emit RoyaltyClaimed(claimRoot, _msgSender(), currentClaimId, amount);
    }

    function verifyEntitled(
        address recipient,
        uint256 value,
        bytes32[] memory proof
    ) public view returns (bool) {
        // We need to pack the 20 bytes address to the 32 bytes value
        // to match with the proof
        bytes32 leaf = keccak256(abi.encodePacked(recipient, value));
        return verifyProof(leaf, proof);
    }

    function verifyProof(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        bytes32 currentHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            currentHash = parentHash(currentHash, proof[i]);
        }

        return currentHash == claimRoot;
    }

    function parentHash(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return
            a <= b
                ? keccak256(abi.encodePacked(a, b))
                : keccak256(abi.encodePacked(b, a));
    }

    function updateMerkleRoot(bytes32 newRoot) external onlyOwner {
        claimRoot = newRoot;
    }

    function createNewClaim(bytes32 newRoot) external onlyOwner {
        currentClaimId = currentClaimId + 1;
        claimRoot = newRoot;
        paused = false;
        emit NewClaim(currentClaimId, claimRoot);
    }

    function setClaimMappingToFalse(address[] memory addrs, uint256 claimId)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            rewardClaimedForClaim[addrs[i]][claimId] = false;
        }
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    receive() external payable {}
}
