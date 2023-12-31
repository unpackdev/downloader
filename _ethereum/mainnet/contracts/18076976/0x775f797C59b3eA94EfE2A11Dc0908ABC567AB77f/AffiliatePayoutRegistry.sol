// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC165Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";

import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IAffiliatePayoutRegistry.sol";

/**
 * @title Affiliate Payout Registry
 *
 * The contract which handles tracking of the presale round buys and allows
 * to later claim the rewards by affiliates. Each buy can be registered only
 * from authorized party (Voucher Contract) as a affiliate wallet address,
 * presale round number and amount in stable coin token. Rewards related to
 * each round would not be paid until the round ends. Then operator will
 * deposit exact amount of rewards linked to specified round and then rewards
 * claiming would be unlocked.
 *
 * @dev A smart contract for on-chain tracking affiliate payouts and rewards distribution.
 */
contract AffiliatePayoutRegistry is
    IAffiliatePayoutRegistry,
    EIP712Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using SafeERC20 for IERC20;

    // Verified affiliate type hash. Affiliate gets the signature when passing KYC to be able to claim rewards
    bytes32 internal constant VERIFIED_AFFILIATE_TYPE_HASH = keccak256("VerifiedAffiliate(address wallet)");

    // operator role which handle funds management
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // presale voucher role which handle registering deposit 
    bytes32 public constant VITREUS_PRESALE_ROLE = keccak256("VITREUS_PRESALE_ROLE");

    /// Presale round struct
    struct PresaleRound {
        // round start time 
        uint64 start;
        // round end time
        uint64 end;
        // flag which reflects if the rewards were unlocked
        bool rewardsUnlocked;
    }

    // Address of the prover which signed EIP712 signature during affiliate approval process
    address private _proverAddress;

    // Minimum accumulated deposit required per affiliate to be rewarded
    uint256 private _minAccumulatedDeposit;

    // The percentage of the affiliate reward in basis points
    uint256 private _affiliateRewardPercentage;

    // The token which is used for deposit and rewards payment
    IERC20 private _rewardToken;

    // Affiliate => accumulated value in specified ERC20 token
    mapping(address => uint256) public accumulatedDeposits;

    // Round number => accumulated rewards in reward ERC20 token
    mapping(uint256 => uint256) public accumulatedRewards;

    // Round number => affiliate deposits
    mapping(uint256 => uint256) public affiliateDeposits;

    // Affiliate => round number => accumulated rewards in reward ERC20 token
    mapping(address => mapping(uint256 => uint256)) public affiliateRewards;

    // Affiliate => round number => claimed flag
    mapping(address => mapping(uint256 => bool)) public rewardsClaimed;

    // Affiliate => claimed rewards
    mapping(address => uint256) public claimedAmount;

    // Total claimed amount
    uint256 public totalClaimed;

    // Array to store round information
    PresaleRound[] public rounds;

    /**
     * @notice Deposit registered event
     * @dev Emitted when user deposit registered
     *
     * @param affiliate the wallet address of the affiliate
     * @param roundId the number of presale round
     * @param amount the amount of deposited tokens in reward ERC20 token
     */
    event DepositRegistered(address indexed affiliate, uint256 indexed roundId, uint256 indexed amount);

    /**
     * @notice Rewards claimed event
     * @dev Emitted when affiliate claims available rewards
     *
     * @param affiliate the wallet address of the affiliate
     * @param amount the amount of rewards in reward ERC20 token
     */
    event RewardsClaimed(address indexed affiliate, uint256 indexed amount);

    /**
     * @notice Operator deposit event
     * @dev Emitted when operator deposit reward funds
     *
     * @param operator the wallet address of the operator
     * @param amount the amount of rewards in reward ERC20 token
     */
    event OperatorDeposited(address indexed operator, uint256 indexed amount);

    /**
     * @notice Operator withdraw event
     * @dev Emitted when operator withdrawn reward funds
     *
     * @param operator the wallet address of the operator
     * @param amount the amount of funds in ERC20 token withdrawn by operator
     */
    event OperatorWithdrawn(address indexed operator, uint256 indexed amount);

    /**
     * @notice Presale Round Create event
     * @dev Emitted when owner specifies the new presale round during initialization.
     *
     * @param round the number of presale round
     * @param presaleRound the presale round info struct
     */
    event PresaleRoundCreated(uint256 indexed round, PresaleRound presaleRound);

    /**
     * @notice Minimum accumulated deposit change event
     * @dev Emitted when owner changed the minimum accumulated deposit
     *
     * @param minAccumulatedDeposit the minimum accumulated deposit
     */
    event MinAccumulatedDepositChanged(uint256 indexed minAccumulatedDeposit);

    /**
     * @notice Affiliate reward percentage change event
     * @dev Emitted when owner changed the affiliate percentage
     *
     * @param affiliateRewardPercentage the affiliate reward percentage
     */
    event AffiliateRewardPercentageChanged(uint256 indexed affiliateRewardPercentage);

    /// @dev Contract is expected to be used as proxy implementation.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }    

    /**
     * @dev Initializes the contract with the required parameters.
     * @param rewardTokenAddress_ Address of the reward token contract.
     * @param minAccumulatedDeposit_ Minimum accumulated deposit required per affiliate
     * @param proverAddress_ Address of prover wallet
     * @param operator_ Address of operator wallet
     */
    function initialize(
        address rewardTokenAddress_,
        uint256 minAccumulatedDeposit_,
        uint256 affiliateRewardPercentage_,
        address proverAddress_,
        address operator_
    ) external initializer {
        require(rewardTokenAddress_ != address(0), "Invalid reward token address");
        require(proverAddress_ != address(0), "Invalid prover address");
        require(operator_ != address(0), "Invalid operator address");
        require(minAccumulatedDeposit_ != 0, "Invalid minimum deposit amount");

        __Ownable_init();
        __Pausable_init();
        __AccessControl_init();
        __EIP712_init("Affiliate Payout Registry", "1");

        _rewardToken = IERC20(rewardTokenAddress_);
        _minAccumulatedDeposit = minAccumulatedDeposit_;
        _affiliateRewardPercentage = affiliateRewardPercentage_;
        _proverAddress = proverAddress_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, operator_);
    }

    /**
     * @dev Creates the round information. Can only be run by the owner of contract
     *
     * @param startTime_ start time of the presale round
     * @param endTime_ end time of the presale round
     */
    function createPresaleRound(uint64 startTime_, uint64 endTime_) external onlyOwner {
        rounds.push(PresaleRound(startTime_, endTime_, false));
        emit PresaleRoundCreated(rounds.length - 1, rounds[rounds.length - 1]);
    }

    /**
     * @dev Changes the affiliate reward percentage
     *
     * @param affiliateRewardPercentage_ affiliate reward percentage
     */
    function updateAffiliateRewardPercentage(uint256 affiliateRewardPercentage_) external onlyOwner {
        require(affiliateRewardPercentage_ <= 5_000, "Rewards more than 50%");
        _affiliateRewardPercentage = affiliateRewardPercentage_;
        emit AffiliateRewardPercentageChanged(affiliateRewardPercentage_);
    }

    /**
     * @dev Changes the minimum accumulated deposit.
     * Will be applied only to new registered deposits
     *
     * @param minAccumulatedDeposit_ new minimum accumulated deposit
     */
    function updateMinAccumulatedDeposit(uint256 minAccumulatedDeposit_) external onlyOwner {
        _minAccumulatedDeposit = minAccumulatedDeposit_;
        emit MinAccumulatedDepositChanged(_minAccumulatedDeposit);
    }

    /**
     * @dev Registers a deposit for an affiliate.
     *
     * @param affiliate The affiliate's address.
     * @param roundId The round ID.
     * @param amount The deposit amount.
     */
    function registerDeposit(
        address affiliate,
        uint256 roundId,
        uint256 amount
    ) external override onlyRole(VITREUS_PRESALE_ROLE) whenNotPaused {
        require(affiliate != address(0), "Invalid affiliate address");
        require(amount != 0, "Invalid deposit amount");

        uint256 previousAffiliateAmount = accumulatedDeposits[affiliate];

        accumulatedDeposits[affiliate] += amount;
        affiliateDeposits[roundId] += amount;

        // if we hit the minimum deposit limit we should include previous deposits as well
        if (previousAffiliateAmount < _minAccumulatedDeposit &&
            previousAffiliateAmount + amount >= _minAccumulatedDeposit) {
            _putRewards(affiliate, roundId, accumulatedDeposits[affiliate]);
        } else if (previousAffiliateAmount >= _minAccumulatedDeposit) {
            _putRewards(affiliate, roundId, amount);
        }

        emit DepositRegistered(affiliate, roundId, amount);
    }

    /**
     * @dev Claims rewards for an affiliate in a specific round.
     * @param signature The EIP712 signature.
     */
    function claimRewards(bytes calldata signature) external override whenNotPaused {
        require(signature.length > 0, "Empty signature");
        require(verifySignature(msg.sender, signature), "Incorrect prover");

        uint256 rewardAmount;

        for (uint256 i = 0; i < rounds.length; ) {
            if (rounds[i].rewardsUnlocked && !rewardsClaimed[msg.sender][i]) {
                rewardAmount += affiliateRewards[msg.sender][i];
                rewardsClaimed[msg.sender][i] = true;
            }

            unchecked {
                ++i;
            }
        }

        require(rewardAmount != 0, "Empty claimable rewards");
        claimedAmount[msg.sender] += rewardAmount;
        totalClaimed += rewardAmount;

        _rewardToken.safeTransfer(msg.sender, rewardAmount);

        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    /**
     * @dev Deposits funds for a specific round.
     */
    function depositFunds() external onlyRole(OPERATOR_ROLE) whenNotPaused {
        uint256 rewards;

        for (uint256 i = 0; i < rounds.length; ) {
            if (block.timestamp > rounds[i].end && !rounds[i].rewardsUnlocked) {
                rewards += accumulatedRewards[i];
                rounds[i].rewardsUnlocked = true;
            }

            unchecked {
                ++i;
            }
        }

        require(rewards != 0, "Empty pending rewards");
        _rewardToken.safeTransferFrom(msg.sender, address(this), rewards);

        emit OperatorDeposited(msg.sender, rewards);
    }

    /**
     * @dev Performs an emergency withdrawal from the smart contract
     */
    function withdraw() external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(_rewardToken.balanceOf(address(this)) > 0, "No funds to withdraw");

        // Withdraw the whole balance from this smart contract
        _rewardToken.safeTransfer(msg.sender, _rewardToken.balanceOf(address(this)));

        emit OperatorWithdrawn(msg.sender, _rewardToken.balanceOf(address(this)));
    }


    /**
     * @dev get total affiliate deposits
     *
     * @return deposits The total affiliate deposits registered
     */
    function getTotalAffiliateDeposits() external view returns (uint256 deposits) {
        for (uint256 i = 0; i < rounds.length; ) {
            if (affiliateDeposits[i] != 0) {
                deposits += affiliateDeposits[i];
            }

            unchecked {
                ++i;
            }
        }

        return deposits;
    }

    /**
     * @dev get total affiliate rewards
     *
     * @return rewards The total affiliate rewards
     */
    function getTotalAffiliateRewards() external view returns (uint256 rewards) {
        for (uint256 i = 0; i < rounds.length; ) {
            if (accumulatedRewards[i] != 0) {
                rewards += accumulatedRewards[i];
            }

            unchecked {
                ++i;
            }
        }

        return rewards;
    }

    /**
     * @dev Shows all the pending rewards.
     * @return rewards The amount of pending rewards.
     */
    function getPendingRewards() external view returns (uint256 rewards) {
        for (uint256 i = 0; i < rounds.length; ) {
            if (accumulatedRewards[i] != 0 && block.timestamp > rounds[i].end && !rounds[i].rewardsUnlocked) {
                rewards += accumulatedRewards[i];
            }

            unchecked {
                ++i;
            }
        }

        return rewards;
    }

    /**
     * @dev Shows the rewards that can be claimed.
     * @return rewards The amount of rewards.
     */
    function getAffiliateRewards(address affiliate) external view returns (uint256 rewards) {
        for (uint256 i = 0; i < rounds.length; ) {
            if (affiliateRewards[affiliate][i] != 0 && rounds[i].rewardsUnlocked && !rewardsClaimed[affiliate][i]) {
                rewards += affiliateRewards[affiliate][i];
            }

            unchecked {
                ++i;
            }
        }

        return rewards;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAffiliatePayoutRegistry).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Verifies the EIP712 signature.
     *
     * @param affiliate The affiliate's address.
     * @param signature The EIP712 signature.
     *
     * @return Whether the signature is valid.
     */
    function verifySignature(address affiliate, bytes calldata signature) internal view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(VERIFIED_AFFILIATE_TYPE_HASH, affiliate))).recover(signature);
        return signer == _proverAddress;
    }

    /**
     * @dev Calculate and add rewards for the affiliate
     * 
     * @param affiliate the affiliate wallet address
     * @param roundId the presale round number
     * @param amount the amount of deposited money for calculation
     */
    function _putRewards(address affiliate, uint256 roundId, uint256 amount) private {
        uint256 rewardAmount = amount * _affiliateRewardPercentage / 10_000;
        affiliateRewards[affiliate][roundId] += rewardAmount;
        accumulatedRewards[roundId] += rewardAmount;
    }
}
