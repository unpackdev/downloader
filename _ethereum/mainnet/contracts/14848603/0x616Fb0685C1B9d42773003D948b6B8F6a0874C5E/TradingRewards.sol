// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MerkleProof.sol";

/**
 * @title TradingRewards
 * @notice It distributes MPWR tokens with rolling Merkle airdrops.
 */
contract TradingRewards is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant BUFFER_ADMIN_WITHDRAW = 3 days;

    IERC20Upgradeable public mpwrToken;

    // Current reward round (users can only claim pending rewards for the current round)
    uint256 public currentRewardRound;

    // Last paused timestamp
    uint256 public lastPausedTimestamp;

    // merkel root owner address
    address public rootOwnerAddress;

    // Max amount per user in current tree
    // uint256 public maximumAmountPerUserInCurrentTree;

    //start time of closing hours
    uint256 public startTime;

    //end time of closing hours
    uint256 public endTime;

    // Total amount claimed by user (in MPWR)
    mapping(address => uint256) public amountClaimedByUser;

    // Merkle root for a reward round
    mapping(uint256 => bytes32) public merkleRootOfRewardRound;

    // Checks whether a merkle root was used
    mapping(bytes32 => bool) public merkleRootUsed;

    // Keeps track on whether user has claimed at a given reward round
    mapping(uint256 => mapping(address => bool)) public hasUserClaimedForRewardRound;

    event RewardsClaim(address indexed user, uint256 indexed rewardRound, uint256 amount);
    event UpdateTradingRewards(uint256 indexed rewardRound);
    event TokenWithdrawnOwner(uint256 amount);

    /**
     * @notice Initializer
     *
     * @param _mpwrToken MPWR token address
     * @param _startTime closing hour start time
     * @param _endTime closing hour end time
     */
    function initialize(
        address _mpwrToken,
        uint256 _startTime,
        uint256 _endTime
    ) external initializer {
        require(_mpwrToken != address(0), "Invalid token address");

        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        mpwrToken = IERC20Upgradeable(_mpwrToken);
        rootOwnerAddress = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
    }

    modifier validateTime(uint256 _startTime, uint256 _endTime) {
        require(_endTime != _startTime, "startTime and endTime should not be equal");
        require(_startTime >= 0 && _startTime <= 23, "starttime should be between 0 and 23");
        require(_endTime >= 0 && _endTime <= 23, "endtime should be between 0 and 23");
        _;
    }

    modifier isCloseHours() {
        uint256 currentTime = getHour(block.timestamp);
        require(!(currentTime >= startTime && currentTime <= endTime), "Claim is unavailable");
        _;
    }

    function getHour(uint256 timestamp) internal pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function setStartAndEndTime(uint256 _startTime, uint256 _endTime)
        public
        validateTime(_startTime, _endTime)
        onlyOwner
    {
        startTime = _startTime;
        endTime = _endTime;
    }

    /**
     * @notice Initializer
     * @param _rootOwnerAddress _rootOwnerAddress address
     */
    function updateRootOwnerAddress(address _rootOwnerAddress) external nonReentrant onlyOwner {
        require(_rootOwnerAddress != address(0), "Invalid rootOwnerAddress address");
        rootOwnerAddress = _rootOwnerAddress;
    }

    /**
     * @notice only _root Owner or OnlyOwner
     */
    modifier onlyRootOwnerAddress() {
        require(
            owner() == _msgSender() || rootOwnerAddress == _msgSender(),
            "Ownable: caller is not the owner or root owner"
        );
        _;
    }

    /**
     * @notice Claim pending rewards
     * @param amount to claim
     * @param merkleProof array containing the merkle proof
     */
    function claim(uint256 amount, bytes32[] calldata merkleProof) external whenNotPaused isCloseHours nonReentrant {
        // Verify the reward round is not claimed already
        require(!hasUserClaimedForRewardRound[currentRewardRound][msg.sender], "Rewards: Already claimed");

        (bool claimStatus, uint256 adjustedAmount) = _canClaim(msg.sender, amount, merkleProof);

        require(claimStatus, "Rewards: Invalid proof");
        // require(maximumAmountPerUserInCurrentTree >= amount, "Rewards: Amount higher than max");

        // Set mapping for user and round as true
        hasUserClaimedForRewardRound[currentRewardRound][msg.sender] = true;

        // Adjust amount claimed
        amountClaimedByUser[msg.sender] += adjustedAmount;

        // Transfer adjusted amount
        mpwrToken.safeTransfer(msg.sender, adjustedAmount);

        emit RewardsClaim(msg.sender, currentRewardRound, adjustedAmount);
    }

    /**
     * @notice Update trading rewards with a new merkle root
     * @dev It automatically increments the currentRewardRound
     * @param merkleRoot root of the computed merkle tree
     */
    function updateTradingRewards(bytes32 merkleRoot) external onlyRootOwnerAddress {
        // require(!merkleRootUsed[merkleRoot], "Owner: Merkle root already used");

        currentRewardRound++;
        merkleRootOfRewardRound[currentRewardRound] = merkleRoot;
        // merkleRootUsed[merkleRoot] = true;
        // maximumAmountPerUserInCurrentTree = newMaximumAmountPerUser;

        emit UpdateTradingRewards(currentRewardRound);
    }

    /**
     * @notice Pause distribution
     */
    function pauseDistribution() external onlyOwner whenNotPaused {
        lastPausedTimestamp = block.timestamp;
        _pause();
    }

    /**
     * @notice Unpause distribution
     */
    function unpauseDistribution() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Transfer MPWR tokens back to owner
     * @dev It is for emergency purposes
     * @param amount amount to withdraw
     */
    function withdrawTokenRewards(uint256 amount) external onlyOwner whenPaused {
        require(block.timestamp > (lastPausedTimestamp + BUFFER_ADMIN_WITHDRAW), "Owner: Too early to withdraw");
        mpwrToken.safeTransfer(msg.sender, amount);

        emit TokenWithdrawnOwner(amount);
    }

    /**
     * @notice Check whether it is possible to claim and how much based on previous distribution
     * @param user address of the user
     * @param amount amount to claim
     * @param merkleProof array with the merkle proof
     */
    function canClaim(
        address user,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool, uint256) {
        return _canClaim(user, amount, merkleProof);
    }

    /**
     * @notice Check whether it is possible to claim and how much based on previous distribution
     * @param user address of the user
     * @param amount amount to claim
     * @param merkleProof array with the merkle proof
     */
    function _canClaim(
        address user,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal view returns (bool, uint256) {
        // Compute the node and verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(user, amount));
        bool canUserClaim = MerkleProof.verify(merkleProof, merkleRootOfRewardRound[currentRewardRound], node);

        if ((!canUserClaim) || (hasUserClaimedForRewardRound[currentRewardRound][user])) {
            return (false, 0);
        } else {
            return (true, amount);
        }
    }
}
