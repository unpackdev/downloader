//SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Clones.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

import "./Types.sol";
import "./Venture.sol";
import "./SignatureValidation.sol";

/**
 * @title ERC20OptionsAllocator
 * @author Jubi
 * @notice This contract allows a Venture to Venture token options to addresses,
 * and will allow accounts to execute options according to a vesting schedule
 */
contract ERC20OptionsAllocator is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    string public constant version = "1.0.0";
    string public constant contractType = "ERC20OptionsAllocator";

    /// @notice The name used to identify this Allocator in dApps
    string public name;

    /// @notice Is the allocator open/active
    bool public isOpen;

    /// @notice Token price in 18 decimals
    uint256 public strikePrice;

    /// @notice Total amount of Venture tokens that can be allocated via this allocator
    uint256 public totalTokensForAllocation;

    /// @notice The timestamp at which the distribution schedule to release tokens for claiming, starts.
    /// Typically happens after the Venture Token is minted and can be set using setVentureToken
    uint256 public vestingScheduleStartTimeStamp;

    /// @notice The number of seconds after starting the distribution schedule, that tokens will be locked from claiming
    uint256 public vestingCliffDuration;

    /// @notice The duration over which tokens are vested, only claimable after cliff vestingCliffDuration
    uint256 public vestingDuration;

    /// @notice Date at which all allocations are vested
    /// @dev  vestingScheduleStartTimeStamp + vestingDuration
    uint256 public vestingEndDateTimeStamp;

    /// @notice The token accepted for purchasing the Venture Token
    IERC20 public purchaseToken;

    /// @notice The Venture Token that allocated
    IERC20 public allocationToken;

    /// @notice the Venture that manages this contract
    Venture public venture;

    /// @notice Tokens that have been allocated to a specific address
    mapping(address => uint256) public allocation;

    /// @notice A list of accounts that did not vest the entire schedule
    mapping(address => uint256) public vestingStopped;

    /// @notice Total tokens allocated from this allocator
    uint256 public totalAllocationTokenAllocated;

    /// @notice Number of allocationToken claimed by a specific address
    mapping(address => uint256) public accountOptionsExercised;

    /// @notice Total allocationToken claimed from this allocator
    uint256 public totalClaimed;

    /**
     * @notice This event is emitted when an allocation is made
     * @param account The account that was allocated tokens
     * @param allocatedAmount The amount of allocationToken that will be allocated to the account
     */
    event TokensAllocated(address account, uint256 allocatedAmount);

    /**
     * @dev Emitted when an account's vesting period has been terminated.
     * @param account The address of the account whose vesting period has been terminated.
     * @param vestingEndDate The end date of the accounts vesting period.
     */
    event AccountVestingTerminated(address account, uint256 vestingEndDate);

    /**
     * @notice This event is emitted when an Option to purchase is executed
     * @param account The account that exeuted the option
     * @param amount The amount that was purchased
     * @param paidAmount The cost of the purchase
     */
    event OptionExecuted(address account, uint256 amount, uint256 paidAmount);

    /**
     * @notice This event is emitted when an `admin` migrates the venture that manages this allocator
     * from `oldVenture` to `newVenture`
     * @param oldVenture The venture that is been deprecated
     * @param newVenture The venture that is assigned as the new manager
     * @param admin The admin account that perform the migration
     */
    event VentureMigrated(
        address indexed oldVenture,
        address indexed newVenture,
        address admin
    );

    /**
     * @dev Emitted when the allocator is closed and no more allocations can be made.
     * @param account The account that closed the allocator.
     */
    event AllocatorClosed(address account);

    /**
     * @notice This function is used to initialize the contract
     * @dev This contract only supports allocation tokens with 18 decimals.
     * The token price is also in 18 decimals, and will be converted to purchase token decimals via contract call
     * to determine decimals
     * @param _config The configuration for this allocator
     */
    function initialize(
        Types.AllocatorConfig memory _config
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_config.venture.owner());
        name = _config.name;
        venture = _config.venture;
        strikePrice = _config.tokenPrice;
        allocationToken = _config.allocationToken;
        purchaseToken = _config.venture.treasuryToken();
        totalTokensForAllocation = _config.tokensForAllocation;
        vestingScheduleStartTimeStamp = _config.releaseScheduleStartTimeStamp;
        vestingCliffDuration = _config.tokenLockDuration;
        vestingDuration = _config.releaseDuration;
        vestingEndDateTimeStamp = vestingScheduleStartTimeStamp + vestingDuration;

        if (address(allocationToken) != address(0)) {
            allocationToken.safeTransferFrom(
                msg.sender,
                address(this),
                totalTokensForAllocation
            );
        }

        isOpen = true;
    }

    /**
     * @notice This function is used to allocate allocationToken, `tokenAllocationAmount` specifying the number of tokens being allocted as long as:
     * 1. The allocator is open
     * 2. There is sufficient unsold allocationToken to fulfill the allocation
     * @param tokenAllocationAmount The amount of allocationToken to allocate
     * @param account The account that will receive the allocationToken
     */
    function allocate(uint256 tokenAllocationAmount, address account) external {
        require(
            venture.isAdminOrAllocatorManager(msg.sender),
            "Allocator: only allocator manager can allocate tokens"
        );
        require(isOpen, "Allocator: Allocation Closed");
        uint256 remainingGlobalTokenAllocation = totalTokensForAllocation -
            totalAllocationTokenAllocated;
        if (remainingGlobalTokenAllocation < tokenAllocationAmount) {
            revert("Allocator: Insufficient tokens available for allocation");
        }
        _allocate(tokenAllocationAmount, account);
    }

    /**
     * @notice This function is used to allocate allocationToken, `tokenAllocationAmount` specifying the number of tokens being allocted as long as:
     * 1. The allocator is open
     * 2. There is sufficient unsold allocationToken to fulfill the allocation
     * @param tokenAllocationAmounts The amount of allocationToken to allocate
     * @param accounts The account that will receive the allocationToken
     */
    function allocateBulk(
        uint256[] memory tokenAllocationAmounts,
        address[] memory accounts
    ) external {
        require(
            venture.isAdminOrAllocatorManager(msg.sender),
            "Allocator: only allocator manager can allocate tokens"
        );
        require(isOpen, "Allocator: Allocation Closed");
        require(
            tokenAllocationAmounts.length == accounts.length,
            "Allocator: Each recipient must have an amount"
        );
        uint256 remainingGlobalTokenAllocation = totalTokensForAllocation -
            totalAllocationTokenAllocated;
        for (uint256 i; i < accounts.length; ++i) {
            if (remainingGlobalTokenAllocation < tokenAllocationAmounts[i]) {
                revert(
                    "TokenAllocator: Insufficient tokens available for allocation"
                );
            }
            remainingGlobalTokenAllocation -= tokenAllocationAmounts[i];
            _allocate(tokenAllocationAmounts[i], accounts[i]);
        }
    }

    /**
     * @dev This function is used to allocate allocationToken, `tokenAllocationAmount` specifying the number of tokens being allocted as long as:
     * @param tokenAllocationAmount The amount of allocationToken to allocate
     * @param account The account that will receive the allocationToken
     */
    function _allocate(uint256 tokenAllocationAmount, address account) private {
        allocation[account] += tokenAllocationAmount;
        totalAllocationTokenAllocated += tokenAllocationAmount;

        if (totalAllocationTokenAllocated == totalTokensForAllocation) {
            _close();
        }

        emit TokensAllocated(account, tokenAllocationAmount);
    }

    /**
     * @notice Stop vesting for an account
     * @param account The account to stop vesting for
     */
    function terminateVesting(address account) external {
        require(
            venture.isAdminOrAllocatorManager(msg.sender),
            "Allocator: only allocator manager"
        );
        require(
            allocation[account] != 0,
            "Allocator: Account has no allocation"
        );
        require(
            vestingEndDateTimeStamp > block.timestamp,
            "Allocator: Vesting period ended"
        );
        require(
            vestingStopped[account] == 0,
            "Allocator: Vesting already terminated"
        );
        vestingStopped[account] = block.timestamp;
        emit AccountVestingTerminated(account, block.timestamp);
        if (address(allocationToken) != address(0)) {
            SafeERC20.safeTransfer(
                allocationToken,
                venture.fundsAddress(),
                calculateWillNotVest(account)
            );
        }
        venture.markUnallocatedTokensReturned(
            address(this),
            calculateWillNotVest(account)
        );
    }

    /**
     * @notice Allows an account to execute the vested options to purchase tokens
     */
    function executeOption() external nonReentrant {
        if (address(allocationToken) == address(0)) {
            revert("Allocator: Allocation Token has not been set yet");
        }
        if (allocation[msg.sender] == 0) {
            revert("Allocator: Account not allocated tokens");
        }
        if (allocation[msg.sender] == accountOptionsExercised[msg.sender]) {
            revert("Allocator: All options executed");
        }
        uint256 releasedAmount = calculateVested(msg.sender) -
            accountOptionsExercised[msg.sender];
        require(releasedAmount != 0, "Allocator: No options available");
        accountOptionsExercised[msg.sender] += releasedAmount;
        totalClaimed += releasedAmount;
        SafeERC20.safeTransferFrom(
            purchaseToken,
            msg.sender,
            venture.fundsAddress(),
            allocationToPurchaseToken(releasedAmount)
        );
        SafeERC20.safeTransfer(allocationToken, msg.sender, releasedAmount);
        emit OptionExecuted(msg.sender, releasedAmount, allocationToPurchaseToken(releasedAmount));
    }

    /**
     * @notice Closes the allocator so that no further allocations can be made, and transfers any remaining tokens back to the venture
     */
    function close() external {
        require(
            venture.isAdminOrAllocatorManager(msg.sender),
            "Allocator: only allocator manager can close allocator"
        );
        require(isOpen, "Allocator: Allocator is already closed");
        uint256 remainingAllocation = totalTokensForAllocation -
            totalAllocationTokenAllocated;

        _close();
        // return any unallocated venture tokens to venture wallet or venture contract.
        if (address(allocationToken) != address(0)) {
            SafeERC20.safeTransfer(
                allocationToken,
                venture.fundsAddress(),
                remainingAllocation
            );
        }
        venture.markUnallocatedTokensReturned(
            address(this),
            remainingAllocation
        );
    }

    function _close() internal {
        isOpen = false;
        emit AllocatorClosed(msg.sender);
    }

    /**
     * @notice Calculates the amount of allocated tokens that has been vested according to the vesting schedule
     * @param account The account to calculate the vested amount for
     */
    function calculateVested(
        address account
    ) public view returns (uint256 releasedAmount) {
        uint256 vestingTimestamp = block.timestamp;
        if (vestingStopped[account] != 0) {
            vestingTimestamp = vestingStopped[account];
        }
        return calculateVestedAt(account, vestingTimestamp);
    }

    /**
     * @notice Calculates the amount of tokens that will be released at a specific timestamp for an account
     * @param account The account to calculate the released amount for
     * @param timestamp The timestamp to calculate the released amount at
     */
    function calculateVestedAt(
        address account,
        uint256 timestamp
    ) public view returns (uint256 vestedAmount) {
        uint256 vestingStartTimestamp = vestingScheduleStartTimeStamp +
            vestingCliffDuration;
        if (timestamp <= vestingStartTimestamp) {
            return 0;
        }
        uint256 elapsedReleaseSeconds = timestamp -
            vestingScheduleStartTimeStamp;
        // minimum claimDuration to 1 sec to prevent /0
        uint256 _vestingDuration = 1;
        if (vestingDuration != 0) {
            _vestingDuration = vestingDuration;
        }

        if (elapsedReleaseSeconds > _vestingDuration) {
            return allocation[account];
        }

        return (allocation[account] * elapsedReleaseSeconds) / _vestingDuration;
    }

    /**
     * @notice Calculates the amount of allocated tokens that will never vest
     * @param account The account to calculate the unvested amount for
     */
    function calculateWillNotVest(
        address account
    ) public view returns (uint256 unvestedAmount) {
        if (allocation[account] == 0) {
            revert("Allocator: Account has not been allocated tokens");
        }
        if (
            vestingStopped[account] == 0 ||
            vestingStopped[account] >= vestingEndDateTimeStamp
        ) {
            return 0;
        }
        // If vesting stopped before cliff, then all tokens are forfeit
        if (
            vestingStopped[account] <
            vestingScheduleStartTimeStamp + vestingCliffDuration
        ) {
            return allocation[account];
        }

        return
            allocation[account] -
            calculateVestedAt(account, vestingStopped[account]);
    }

    /**
     * @notice Sets the token address for the token that was sold and transfers the amount required to fulfill all claims to this contract
     * @param _allocationToken The token that was sold using this contract, the required amount will be transferred to the contract
     * @dev Use '_setClaimableScheduleStart' if token minting did not happen on schedule, to start the schedule since the token is now available
     */
    function setAllocationToken(IERC20 _allocationToken) external {
        require(
            venture.isAdminOrAllocatorManager(msg.sender),
            "Allocator: only allocator manager can set the token"
        );
        require(
            address(allocationToken) == address(0),
            "Allocator: Venture token already set"
        );
        require(
            address(_allocationToken) != address(0),
            "Allocator: Token address invalid"
        );
        if (isOpen) {
            SafeERC20.safeTransferFrom(
                _allocationToken,
                msg.sender,
                address(this),
                totalTokensForAllocation
            );
        } else {
            SafeERC20.safeTransferFrom(
                _allocationToken,
                msg.sender,
                address(this),
                totalAllocationTokenAllocated
            );
        }
        allocationToken = _allocationToken;
    }

    /**
     * @notice Migrates this contract from being managed by current venture to a new venture `_newVenture`
     * All access control and admin rights are managed by the venture.
     * @param _newVenture The new venture contract that will manage this allocator
     */
    function migrateVenture(address _newVenture) external {
        require(_newVenture != address(0), "Allocator: invalid new venture");
        Venture newVenture = Venture(_newVenture);
        require(
            newVenture.tokenSupply() > totalTokensForAllocation,
            "Allocator: Venture has insufficient token supply"
        );
        require(
            newVenture != venture,
            "Allocator: Can not update to same venture"
        );
        require(
            venture.isAdmin(msg.sender),
            "Allocator: only venture admin can update allocator"
        );
        require(
            newVenture.isAdmin(msg.sender),
            "Allocator: only venture admin can update allocator"
        );
        address oldVenture = address(venture);
        venture = newVenture;
        emit VentureMigrated(oldVenture, address(newVenture), msg.sender);
    }

    /**
     * @notice Calculates the amount of purchase token required to purchase the given allocation of options.
     * @dev calculates the number of purchase tokens, accounts for the 18 decimals of both numbers, and then converts to decimals of purchase token.
     * @param _allocation The allocation of options to be purchased.
     * @return The amount of purchase token required to purchase the given allocation of options.
     */
    function allocationToPurchaseToken(
        uint256 _allocation
    ) internal view returns (uint256) {
        uint256 purchaseTokenDecimals = 10 **
            IERC20Metadata(address(purchaseToken)).decimals();
        return ((_allocation * strikePrice * purchaseTokenDecimals) / 1e36);
    }
}
