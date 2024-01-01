//SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Clones.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

import "./Types.sol";
import "./Venture.sol";
import "./SignatureValidation.sol";

/**
 * @title ERC20MAnualAllocator
 * @author Jubi
 * @notice This contract allows a Venture to create an allocation of Venture tokens,
 * and will allocate the tokens to the relevant accounts according to a distribution schedule
 * This is a partner to ERC20FixedPriceAllocator, but assumes that contracts and funds exchange happened off-chain
 * so it only manages the distribution of tokens
 */
contract ERC20ManualAllocator is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    /// @notice The name used to identify this Allocator in dApps
    string public name;

    /// @notice A description about this Allocator for dApps
    string public description;

    /// @notice Is the allocator open/active
    bool public isOpen;

    /// @notice Token price
    uint256 public tokenPrice;

    /// @notice Total amount of Venture tokens that can be allocated via this allocator
    uint256 public totalTokensForAllocation;

    /// @notice The timestamp at which the distribution schedule to release tokens for claiming, starts.
    /// Typically happens after the Venture Token is minted and can be set using setVentureToken
    uint256 public releaseScheduleStartTimeStamp;

    /// @notice The number of seconds after starting the distribution schedule, that tokens will be locked from claiming
    uint256 public tokenLockDuration;

    /// @notice The duration over which tokens are released for claiming after the tokenLockDuration
    uint256 public releaseDuration;

    /// @notice The Venture Token that allocated
    IERC20 public allocationToken;

    /// @notice the Venture that manages this contract
    Venture public venture;

    /// @notice Tokens that have been allocated to a specific address
    mapping(address => uint256) public allocation;

    /// @notice Total tokens allocated from this allocator
    uint256 public totalAllocationTokenAllocated;

    /// @notice Number of allocationToken claimed by a specific address
    mapping(address => uint256) public accountClaimed;

    /// @notice Total allocationToken claimed from this allocator
    uint256 public totalClaimed;

    /**
     * @notice This event is emitted when an allocation is made
     * @param account The account that was allocated tokens
     * @param allocatedAmount The amount of allocationToken that will be allocated to the account
     */
    event TokensAllocated(
        address account,
        uint256 allocatedAmount
    );


    /**
     * @notice This event is emitted a Claim is made
     * @param account The account that claimed allocationToken
     * @param amount The amount that was claimed
     */
    event Claimed(address account, uint256 amount);

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
     * @dev PLEASE NOTE, this contract supports prices with the decimals specific to the purchase token, i.e. $USDC 1 as 1000000
     * Allocation token is only supported with 18 decimals
     * @param _config The configuration for this allocator
     */
    function initialize(
        Types.AllocatorConfig memory _config
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_config.venture.owner());
        name = _config.name;
        description = _config.description;
        venture = _config.venture;
        tokenPrice = _config.tokenPrice;
        allocationToken = _config.allocationToken;
        totalTokensForAllocation = _config.tokensForAllocation;
        releaseScheduleStartTimeStamp = _config.releaseScheduleStartTimeStamp;
        tokenLockDuration = _config.tokenLockDuration;
        releaseDuration = _config.releaseDuration;

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
    function allocate(
        uint256 tokenAllocationAmount,
        address account
    ) external {
        require(
            venture.isAdminOrAllocatorManager(msg.sender),
            "Allocator: only allocator manager can allocate tokens"
        );
        require(isOpen, "Allocator: Allocation Closed");
        uint256 remainingGlobalTokenAllocation = totalTokensForAllocation -
            totalAllocationTokenAllocated;
        if (remainingGlobalTokenAllocation < tokenAllocationAmount) {
            revert(
                "Allocator: Insufficient tokens available for allocation"
            );
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
        require(tokenAllocationAmounts.length == accounts.length, "Allocator: Each recipient must have an amount");
        uint256 remainingGlobalTokenAllocation;
        for (uint256 i; i < accounts.length; ++i) {
            remainingGlobalTokenAllocation = totalTokensForAllocation -
            totalAllocationTokenAllocated;
            if (remainingGlobalTokenAllocation < tokenAllocationAmounts[i]) {
                revert(
                    "Allocator: Insufficient tokens available for allocation"
                );
            }
            _allocate(tokenAllocationAmounts[i], accounts[i]);
        }
    }

    /**
     * @dev This function is used to allocate allocationToken, `tokenAllocationAmount` specifying the number of tokens being allocted as long as:
     * @param tokenAllocationAmount The amount of allocationToken to allocate
     * @param account The account that will receive the allocationToken
     */
    function _allocate(
        uint256 tokenAllocationAmount,
        address account
    ) private {
        allocation[account] += tokenAllocationAmount;
        totalAllocationTokenAllocated += tokenAllocationAmount;

        if (totalAllocationTokenAllocated == totalTokensForAllocation) {
            _close();
        }

        emit TokensAllocated(account, tokenAllocationAmount);
    }

    /**
     * @notice Allows an account to claim tokens that have been released and not yet claimed
     */
    function claim() external nonReentrant {
        require(
            !isOpen,
            "Allocator: Can only claim once allocator is closed"
        );
        if (allocation[msg.sender] == 0){
            revert(
                "Allocator: This account has not been allocated tokens, 0 claimable"
            );

        }
        uint256 claimableAmount = calculateReleased(msg.sender) -
        accountClaimed[msg.sender];
        require(claimableAmount != 0, "Allocator: Nothing to claim");
        accountClaimed[msg.sender] += claimableAmount;
        totalClaimed += claimableAmount;
        SafeERC20.safeTransfer(
            allocationToken,
            msg.sender,
            claimableAmount
        );
        emit Claimed(msg.sender, claimableAmount);

    }

    /**
     * @notice Closes the allocator so that no further allocations can be made, and transfers any remaining tokens back to the venture
     */
    function close() external {
        require(
            venture.isAdminOrAllocatorManager(msg.sender),
            "Allocator: only allocator manager can close allocator"
        );
        require(
            isOpen,
            "Allocator: Allocator is already closed"
        );
        uint256 remainingAllocation =
                totalTokensForAllocation -
                totalAllocationTokenAllocated;

        _close();
            // return any unallocated venture tokens to venture wallet or venture contract.
            if(address(allocationToken) != address(0) && remainingAllocation != 0){
                    SafeERC20.safeTransfer(
                    allocationToken,
                    venture.fundsAddress(),
                    remainingAllocation
                );
            }
                venture.markUnallocatedTokensReturned(address(this) ,remainingAllocation);

    }

    function _close() internal {
        isOpen = false;
        emit AllocatorClosed(msg.sender);
    }


    /**
     * @notice Calculates the amount of allocated tokens that has been released according to the release schedule
     * @param account The account to calculate the released amount for
     */
    function calculateReleased(
        address account
    ) public view returns (uint256 releasedAmount) {
        // TODO This is true with 0 sold also
        if (allocation[account] == 0)
            revert(
                "Allocator: This account has not been allocated tokens, 0 claimable"
            );
        if (
            totalAllocationTokenAllocated == totalClaimed ||
            allocation[account] == accountClaimed[account]
        ) {
            revert("Allocator: All tokens have been claimed");
        }
        if (address(allocationToken) == address(0)) {
            revert(
                "Allocator: Allocation Token has not been set yet"
            );
        }

        uint256 timestamp = block.timestamp;

        uint256 releaseStartTimestamp = releaseScheduleStartTimeStamp +
            tokenLockDuration;
        if (timestamp < releaseStartTimestamp) {
            return 0;
        }

        uint256 elapsedReleaseSeconds = timestamp - releaseStartTimestamp;
        // minimum claimDuration to 1 sec to prevent /0
        uint256 _releaseDuration = 1;
        if (releaseDuration != 0) {
            _releaseDuration = releaseDuration;
        }

        if (elapsedReleaseSeconds > _releaseDuration) {
            return allocation[account];
        }

        releasedAmount =
            (allocation[account] * elapsedReleaseSeconds) /
            _releaseDuration;
    }

    /**
     * @notice Sets the token address for the token that was sold and transfers the amount required to fulfill all claims to this contract
     * @param _allocationToken The token that was sold using this contract, the required amount will be transferred to the contract
     * @param _setReleaseScheduleStart If set to true, starts the distribution schedule
     * @dev Use '_setClaimableScheduleStart' if token minting did not happen on schedule, to start the schedule since the token is now available
     * @dev PLEASE NOTE, only 18 decimal tokens are supported
     */
    function setAllocationToken(
        IERC20 _allocationToken,
        bool _setReleaseScheduleStart
    ) external {
        require(
            !isOpen,
            "Allocator: Cannot set token while allocator is open"
        );
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
            SafeERC20.safeTransferFrom(
                _allocationToken,
                msg.sender,
                address(this),
                totalAllocationTokenAllocated
            );
        if (_setReleaseScheduleStart) {
            releaseScheduleStartTimeStamp = block.timestamp;
        }
        allocationToken = _allocationToken;
    }

    /**
     * @notice Migrates this contract from being managed by current venture to a new venture `_newVenture`
     * All access control and admin rights are managed by the venture.
     * @param _newVenture The new venture contract that will manage this allocator
     */
    function migrateVenture(address _newVenture) external {
        require(
            _newVenture != address(0),
            "Allocator: invalid new venture"
        );
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

}
