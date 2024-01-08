
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// Openzeppelin imports
import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/// Local imports
import "./GovernanceToken.sol";



/**
 * @title Governance token initial distribution
 *
 */
contract GovernanceDistribution is AccessControl {

    using SafeERC20 for GovernanceToken;
    using SafeERC20 for IERC20;

    /// Constant member variables
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256('DISTRIBUTOR_ROLE');

    uint256 public constant INITIALSUPPLY = 2000000000 * DECIMALFACTOR;
    uint256 private constant DECIMALFACTOR = 10 ** 18;

    uint256 private constant MONTH = 30 days;
    uint256 private constant YEAR = 365 days;


    /// Public variables
    GovernanceToken public token;
    uint256 public availableTotalSupply = INITIALSUPPLY;

    /// Types of available supplies
    uint256 public availableProductUsage1Supply             = 200000000 * DECIMALFACTOR;    // 10%
    uint256 public availableProductUsage2Supply             = 800000000 * DECIMALFACTOR;    // 40%
    uint256 public availableBuildersSupply                  = 140000000 * DECIMALFACTOR;    // 7%
    uint256 public availableAffiliateSupply                 = 120000000 * DECIMALFACTOR;    // 6%
    uint256 public availableTeamSupply                      = 250000000 * DECIMALFACTOR;    // 12.50%
    uint256 public availableAdvisorsSupply                  = 50000000 * DECIMALFACTOR;     // 2.50%
    uint256 public availableAngelsSupply                    = 224887556 * DECIMALFACTOR;    // 11.24%
    uint256 public availablePresaleSupply                   = 101063830 * DECIMALFACTOR;    // 5.05%
    uint256 public availablePublicSupply                    = 19342360 * DECIMALFACTOR;     // 0.97%
    uint256 public availableReserveSupply                   = 94706254 * DECIMALFACTOR;     // 4.74%

    uint256 public grandTotalClaimed = 0;


    // Private variables
    mapping (address => Allocation) private _allocations;
    address[] private _allocatedAddresses;


    /// Allocation Types
    enum AllocationType {
        ProductUsage1,
        ProductUsage2,
        Builders,
        Affiliate,
        Team,
        Advisors,
        Angels,
        Presale,
        Public,
        Reserve
    }

    /// Allocation State
    enum State {
        NotAllocated,
        Allocated,
        Canceled
    }

    enum UnlockStyle {
        Linear,
        Monthly
    }

    /// Allocation with vesting information
    struct Allocation {

        AllocationType allocationType;          // Type of allocation
        uint256 allocationTime;                 // Locking calculated from this time
        uint256 lockupPeriod;                   // After this period tokens can be claimed
        uint256 releasedImmediately;            // Percentage of tokens that will be released immediately
        uint256 vesting;                        // After this period all tokens can be claimed
        UnlockStyle unlockStyle;                // Style of unlocking it can be liner or monthly
        uint256 totalAllocated;                 // Total tokens allocated
        uint256 amountClaimed;                  // Total tokens claimed
        State state;                            // Allocation state
        bool instantRelease;
    }


    /// Events
    event NewAllocation(address indexed recipient, AllocationType indexed allocationType, uint256 amount);
    event TokenClaimed(address indexed recipient,
                        AllocationType indexed allocationType,
                        uint256 amountClaimed);
    event CancelAllocation(address indexed recipient);


    /// Constructor
    constructor() {

        require(availableTotalSupply == availableProductUsage1Supply
                                            + availableProductUsage2Supply
                                            + availableBuildersSupply
                                            + availableAffiliateSupply
                                            + availableTeamSupply
                                            + availableAdvisorsSupply
                                            + availableAngelsSupply
                                            + availablePresaleSupply
                                            + availablePublicSupply
                                            + availableReserveSupply);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        token = new GovernanceToken(_msgSender());
    }

    /// Gets allocated addresses array
    function getAllocatedAddresses()
        view
        external
        returns(address[] memory) {

        return _allocatedAddresses;
    }

    /// Gets allocation
    function getAllocation(address address_)
        view
        external
        returns(AllocationType allocationType,
                bool instantRelease,
                uint256 allocationTime,
                uint256 lockupPeriod,
                uint256 releasedImmediately,
                uint256 vesting,
                uint256 totalAllocated,
                uint256 amountClaimed,
                UnlockStyle unlockStyle,
                State state) {

        allocationType = _allocations[address_].allocationType;
        instantRelease = _allocations[address_].instantRelease;
        allocationTime = _allocations[address_].allocationTime;
        lockupPeriod = _allocations[address_].lockupPeriod;
        releasedImmediately = _allocations[address_].releasedImmediately;
        vesting = _allocations[address_].vesting;
        totalAllocated = _allocations[address_].totalAllocated;
        amountClaimed = _allocations[address_].amountClaimed;
        unlockStyle = _allocations[address_].unlockStyle;
        state = _allocations[address_].state;
    }

    /// Allow distributor of the contract to assign a new allocation
    function setAllocation (address recipient_, uint256 amount_, AllocationType
                            allocationType_, bool instantRelease_) external onlyRole(DISTRIBUTOR_ROLE) {

        require(address(0x0) != recipient_, 'Recipient address cannot be 0x0');
        require(0 < amount_, 'Allocated amount must be greater than 0');
        Allocation storage a = _allocations[recipient_];
        if (State.NotAllocated == a.state) {
            a.allocationTime = block.timestamp;
            a.totalAllocated = amount_;
            _allocatedAddresses.push(recipient_);
        } else if (State.Canceled == a.state) {
            a.allocationTime = block.timestamp;
            a.totalAllocated = amount_;
        } else {
            require(allocationType_ == a.allocationType, 'Cannot change already allocated allocation type');
            require(instantRelease_ == a.instantRelease, 'Cannot change already allocated instant release');
            a.totalAllocated += amount_;
        }
        a.state = State.Allocated;
        a.allocationType = allocationType_;
        a.instantRelease = instantRelease_;
        if (AllocationType.ProductUsage1 == allocationType_) {
            availableProductUsage1Supply -= amount_;
            a.unlockStyle = UnlockStyle.Linear;
            a.releasedImmediately = 0;
            a.lockupPeriod = 0;
            a.vesting = 3 * MONTH;
        } else if (AllocationType.ProductUsage2 == allocationType_) {
            availableProductUsage2Supply -= amount_;
            a.unlockStyle = UnlockStyle.Linear;
            a.releasedImmediately = 0;
            a.lockupPeriod = 3 * MONTH;
            a.vesting = 4 * YEAR;
        } else if (AllocationType.Builders == allocationType_) {
            availableBuildersSupply -= amount_;
            a.unlockStyle = UnlockStyle.Linear;
            a.releasedImmediately = 0;
            a.lockupPeriod = 0;
            a.vesting = 8 * YEAR;
        } else if (AllocationType.Affiliate == allocationType_) {
            availableAffiliateSupply -= amount_;
            a.unlockStyle = UnlockStyle.Linear;
            a.releasedImmediately = 0;
            a.lockupPeriod = 0;
            a.vesting = 8 * YEAR;
        } else if (AllocationType.Team == allocationType_) {
            availableTeamSupply -= amount_;
            a.unlockStyle = UnlockStyle.Linear;
            a.releasedImmediately = 0;
            a.lockupPeriod = 6 * MONTH;
            a.vesting = 30 * MONTH;
        } else if (AllocationType.Advisors == allocationType_) {
            availableAdvisorsSupply -= amount_;
            a.unlockStyle = UnlockStyle.Linear;
            a.releasedImmediately = 0;
            a.lockupPeriod = 1 * MONTH;
            a.vesting = 24 * MONTH;
        } else if (AllocationType.Angels == allocationType_) {
            availableAngelsSupply -= amount_;
            a.unlockStyle = UnlockStyle.Linear;
            a.releasedImmediately = 250;
            a.lockupPeriod = 0;
            a.vesting = 9 * MONTH;
        } else if (AllocationType.Presale == allocationType_) {
            availablePresaleSupply -= amount_;
            a.unlockStyle = UnlockStyle.Monthly;
            a.releasedImmediately = 1000;
            a.lockupPeriod = 0;
            a.vesting = 3 * MONTH;
        } else if (AllocationType.Public == allocationType_) {
            availablePublicSupply -= amount_;
            a.unlockStyle = UnlockStyle.Monthly;
            a.releasedImmediately = 0;
            a.lockupPeriod = 0;
            a.vesting = 2 * MONTH;
        } else { // Reserve
            availableReserveSupply -= amount_;
            a.unlockStyle = UnlockStyle.Linear;
            a.releasedImmediately = 1525;
            a.lockupPeriod = 0;
            a.vesting = 9 * MONTH;
        }
        availableTotalSupply -= amount_;
        emit NewAllocation(recipient_, allocationType_, amount_);
    }

    /// Cancels allocation for given recipient
    function cancelAllocation (address recipient_)
        external onlyRole(DISTRIBUTOR_ROLE) {

        Allocation storage a = _allocations[recipient_];
        require(State.Allocated == a.state, 'There is no allocation');
        require(0 == a.amountClaimed, 'Cannot canceled allocation with claimed tokens');
        a.state = State.Canceled;

        availableTotalSupply += a.totalAllocated;
        if (AllocationType.ProductUsage1 == a.allocationType) {
            availableProductUsage1Supply += a.totalAllocated;
        } else if (AllocationType.ProductUsage2 == a.allocationType) {
            availableProductUsage2Supply += a.totalAllocated;
        } else if (AllocationType.Builders == a.allocationType) {
            availableBuildersSupply += a.totalAllocated;
        } else if (AllocationType.Affiliate == a.allocationType) {
            availableAffiliateSupply += a.totalAllocated;
        } else if (AllocationType.Team == a.allocationType) {
            availableTeamSupply += a.totalAllocated;
        } else if (AllocationType.Advisors == a.allocationType) {
            availableAdvisorsSupply += a.totalAllocated;
        } else if (AllocationType.Angels == a.allocationType) {
            availableAngelsSupply += a.totalAllocated;
        } else if (AllocationType.Presale == a.allocationType) {
            availablePresaleSupply += a.totalAllocated;
        } else if (AllocationType.Public == a.allocationType) {
            availablePublicSupply += a.totalAllocated;
        } else { // Reserve
            availableReserveSupply += a.totalAllocated;
        }
        emit CancelAllocation(recipient_);
    }

    /// Transfer a recipient's available allocation to their address
    function claimTokens (address recipient_) external returns(uint256) {

        Allocation storage a = _allocations[recipient_];
        require(State.Allocated == a.state, 'There is no allocation for the recipient');
        require(a.amountClaimed < a.totalAllocated, 'Allocations have already been transferred');
        uint256 p100 = 10000;
        uint256 newPercentage = a.releasedImmediately;
        if (a.instantRelease) {
            newPercentage = p100;
        } else if (block.timestamp > a.allocationTime + a.lockupPeriod) {
            if (a.unlockStyle == UnlockStyle.Linear) {
                newPercentage += (block.timestamp - (a.allocationTime + a.lockupPeriod)) *
                                                    (p100 - a.releasedImmediately) / a.vesting;
            } else {
                uint256 m = a.vesting % MONTH > 0 ? 1 : 0;
                uint256 n = a.vesting / MONTH + m; // 0 !== a.vesting
                newPercentage += ((block.timestamp - (a.allocationTime + a.lockupPeriod)) / MONTH) *
                                                    (p100 - a.releasedImmediately) / n;
            }
        }
        uint256 newAmountClaimed = a.totalAllocated;
        if (newPercentage < p100) {
            newAmountClaimed = a.totalAllocated * newPercentage / p100;
        }
        require(newAmountClaimed > a.amountClaimed, 'Tokens for this period are already transferred');
        uint256 tokensToTransfer = newAmountClaimed - a.amountClaimed;
        token.safeTransfer(recipient_, tokensToTransfer);
        grandTotalClaimed += tokensToTransfer;
        a.amountClaimed = newAmountClaimed;
        emit TokenClaimed(recipient_, a.allocationType, tokensToTransfer);
        return tokensToTransfer;
    }

    /// Allow transfer of accidentally sent IERC20 tokens
    function refundTokens(address recipientAddress_, address erc20Address_)
        external onlyRole(DISTRIBUTOR_ROLE) {

        require(erc20Address_ != address(token), 'Cannot refund GovernanceToken');
        IERC20 erc20 = IERC20(erc20Address_);
        uint256 balance = erc20.balanceOf(address(this));
        erc20.safeTransfer(recipientAddress_, balance);
    }
}
