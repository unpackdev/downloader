// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract Airdrop is Ownable {
    /// @notice Merkle root of airdrop tree
    bytes32 public merkleRoot;
    address public token;
    uint256 public claimPeriod;
    uint256 public claimablePercentByPeriod;
    uint256 public initialTimestap;

    mapping(address => uint256) public alreadyClaimed;
    mapping(address => uint256) public lastClaimTimestamp;

    /// ============ Errors ============
    /// @notice Thrown if address has already claimed
    error AlreadyClaimed();
    /// @notice Thrown if address/amount are not part of Merkle tree
    error NotInMerkle();

    /// ============ Events ============
    /// @notice Emitted when merkle root is updated
    event MerkleRootChanged(bytes32 merkleRoot);

    constructor() Ownable(_msgSender()) {
        claimPeriod = 5 minutes;
        initialTimestap = block.timestamp;
        claimablePercentByPeriod = 10;
    }

    /// @notice Emitted after a successful token claim
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event Claim(address indexed to, uint256 amount);

    /// ============ Functions ============

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param amount of tokens owed to claimee
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(uint256 amount, bytes32[] calldata proof) external {
        address account = _msgSender();
        bool valid;
        uint256 claimable;
        (valid, claimable) = canClaim(account, amount, proof);
        if (!valid) revert NotInMerkle();

        require(claimable > 0, "No tokens available to claim yet");

        if (lastClaimTimestamp[account] == 0) {
            lastClaimTimestamp[account] = block.timestamp;
        }
        lastClaimTimestamp[account] = block.timestamp;

        alreadyClaimed[account] += claimable;
        IERC20(token).transfer(account, claimable);

        emit Claim(account, claimable);
    }

    function calculateClaimable(
        address account,
        uint256 totalAmount
    ) public view returns (uint256) {
        if (lastClaimTimestamp[account] == 0) {
            return totalAmount / claimablePercentByPeriod; // 10% for the first claim
        }

        uint256 daysSinceFirstClaim = (block.timestamp - initialTimestap) /
            claimPeriod;
        uint256 totalEligible = (totalAmount * (daysSinceFirstClaim + 1)) /
            claimablePercentByPeriod;
        if (totalEligible > totalAmount) {
            totalEligible = totalAmount;
        }

        return totalEligible - alreadyClaimed[account];
    }

    /*
    function calculateClaimable(
        address account,
        uint256 totalAmount
    ) public view returns (uint256) {
        if (firstClaimTimestamp[account] == 0) {
            return totalAmount / 10; // 10% for the first claim
        }

        uint256 daysSinceFirstClaim = (block.timestamp - firstClaimTimestamp[account]) / claimPeriod;
        uint256 totalEligible = (totalAmount * (daysSinceFirstClaim + 1)) / 10;
        if (totalEligible > totalAmount) {
            totalEligible = totalAmount;
        }

        return totalEligible - alreadyClaimed[account];
    }
    */

    /**
     * @dev Returns true if wallet can claim
     * @param account The address to check if can claim.
     */
    function canClaim(
        address account,
        uint256 amount,
        bytes32[] calldata proof
    ) public view returns (bool, uint256) {
        bytes32 leaf = keccak256(abi.encodePacked(account, amount));
        bool valid = MerkleProof.verify(proof, merkleRoot, leaf);
        uint256 claimable = calculateClaimable(account, amount);
        return (valid && claimable > 0, claimable);
    }

    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _merkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    function setToken(address _token) public onlyOwner {
        require(_token != address(0), "Airdrop: Invalid token address");
        token = _token;
    }

    function setClaimPeriod(uint256 _claimPeriod) public onlyOwner {
        claimPeriod = _claimPeriod;
    }

    function setClaimablePercentByPeriod(
        uint256 _claimablePercentByPeriod
    ) public onlyOwner {
        claimablePercentByPeriod = _claimablePercentByPeriod;
    }

    function withdraw() public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }
}
