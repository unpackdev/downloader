//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

interface MPWRStakeFor {
    function depositFor(address user, uint256 _amount) external;
}

contract Airdrop is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    MPWRStakeFor public MPWRStake;
    /// @dev The merkle root hash of whitelisted users
    bytes32 public MERKLE_ROOT;

    /// @dev The MPWR token contract address
    address public immutable MPWR;

    /// @dev The airdrop start time
    uint256 public immutable AIRDROP_START;

    /// @dev The airdrop period
    uint256 public constant AIRDROP_PERIOD = 7 days;

    /// @dev The claimed users
    mapping(address => bool) public claimedUsers;

    /**
     * @dev The airdrop configuration initializer
     * @param _root The merkle root hash
     * @param _mpwr The MPWR token contract address
     * @param _start The airdrop start date
     */
    constructor(
        bytes32 _root,
        address _mpwr,
        MPWRStakeFor _MPWRStake,
        uint256 _start
    ) {
        MERKLE_ROOT = _root;
        MPWR = _mpwr;
        AIRDROP_START = _start;
        MPWRStake = _MPWRStake;
        emit Initialized(_root, _mpwr, _start);
    }

    /**
     * @dev The airdrop reward claiming
     * @param _amount The claimable reward amount
     * @param _merkleProof The verifiable proof
     */
    function claim(
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        bool stake
    ) external onlyInOngoingAirdrop {
        require(!isClaimed(msg.sender), "Already claimed");
        require(verifyProof(_merkleProof, getMerkleRoot(), getNode(msg.sender, _amount)), "Invalid claim");
        if (stake) {
            require(address(MPWRStake) != address(0), "Claim: cannot stake to address(0)");
            IERC20(getMPWR()).approve(address(MPWRStake), _amount);
            MPWRStake.depositFor(msg.sender, _amount);
        } else {
            IERC20(getMPWR()).safeTransfer(msg.sender, _amount);
        }

        _setClaimed(msg.sender);
        emit Claimed(msg.sender, _amount);
    }

    /**
     * @notice Check whether it is possible to claim or not
     * @param _who address of the user
     * @param _amount amount to claim
     * @param _merkleProof array with the merkle proof
     */
    function canClaim(
        address _who,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        if (!isClaimed(_who) && verifyProof(_merkleProof, getMerkleRoot(), getNode(_who, _amount))) {
            return true;
        }

        return false;
    }

    /**
     * @dev The remaining MPWR withdrawing after airdrop
     * @param _who The Clubrare treasury address
     */
    function withdrawMPWR(address _who) external onlyAfterAirdrop onlyOwner {
        require(_who != address(0), "Invalid receiver address");

        IERC20 mpwr = IERC20(getMPWR());
        uint256 balance = mpwr.balanceOf(address(this));
        require(balance > 0, "Insufficient balance");

        mpwr.safeTransfer(_who, balance);
    }

    /**
     * @dev Update merkel Root
     * @param _root Merkel Root hash
     */
    function updateMerkelRoot(bytes32 _root) external onlyOwner {
        MERKLE_ROOT = _root;
    }

    /**
     * @dev Update staking contract
     * @param _MPWRStake Staking contract address
     */
    function updateMPWRStake(MPWRStakeFor _MPWRStake) external onlyOwner {
        MPWRStake = _MPWRStake;
        emit MPWRStakeUpdate(address(_MPWRStake));
    }

    /// --------------- Modifiers ---------------

    modifier onlyInOngoingAirdrop() {
        require(block.timestamp >= getAirdropStartDate(), "Airdrop is not started yet");
        require(block.timestamp <= getAirdropEndDate(), "Airdrop is ended");
        _;
    }

    modifier onlyAfterAirdrop() {
        require(block.timestamp > getAirdropEndDate(), "Airdrop is not ended yet");
        _;
    }

    /// --------------- Private Setters ---------------

    /// @dev The Claimed User setter
    function _setClaimed(address _who) private {
        claimedUsers[_who] = true;
    }

    /// --------------- Getters ---------------

    /// @dev The Merkle Root Hash getter
    function getMerkleRoot() public view returns (bytes32) {
        return MERKLE_ROOT;
    }

    /// @dev The Airdrop Start Date getter
    function getAirdropStartDate() public view returns (uint256) {
        return AIRDROP_START;
    }

    /// @dev The Airdrop End Date getter
    function getAirdropEndDate() public view returns (uint256) {
        return AIRDROP_START + AIRDROP_PERIOD;
    }

    /// @dev The MPWR token contract address getter
    function getMPWR() public view returns (address) {
        return MPWR;
    }

    /**
     * @dev The claimable user verifier
     * @param _who The user wallet address
     */
    function isClaimed(address _who) public view returns (bool) {
        return claimedUsers[_who];
    }

    /**
     * @dev Get Node hash of given data
     * @param _who The whitelisted user address
     * @param _amount The airdrop reward amount
     */
    function getNode(address _who, uint256 _amount) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_who, _amount));
    }

    /**
     * @dev Function to verify the given proof.
     * @param proof Proof to verify
     * @param root Root of the Merkle tree
     * @param leaf Leaf to verify
     */
    function verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) private pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    /// --------------- Events ---------------

    /**
     * @dev The airdrop configuration initialized event
     * @param merkleRoot The merkle root hash of whitelisted users
     * @param mpwr The MPWR token contract address
     * @param startDate The airdrop start date
     */
    event Initialized(bytes32 merkleRoot, address mpwr, uint256 startDate);

    /**
     * @dev The reward claimed event
     * @param who The claimer address
     * @param amount The claimed reward amount
     */
    event Claimed(address who, uint256 amount);

    /**
     * @dev The Staking address update event
     * @param MPWRStake new address of Staking contract
     */
    event MPWRStakeUpdate(address MPWRStake);
}
