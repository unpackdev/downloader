// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ILiqLocker.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./AuraMath.sol";

/**
 * @title   LiqVestedEscrow
 * @author  Aura, adapted from ConvexFinance (convex-platform/contracts/contracts/VestedEscrow)
 * @notice  Vests tokens over a given timeframe to an array of recipients.
 *          Allows locking of these tokens directly to staking contract.
 * @dev     Adaptations:
 *           - One time initialisation
 *           - Consolidation of fundAdmin/admin
 *           - Lock in LiqLocker by default
 *           - Start and end time
 */
contract LiqVestedEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;

    address public admin;
    address public immutable funder;
    ILiqLocker public liqLocker;

    uint256 public immutable startTime;
    uint256 public immutable endTime;
    uint256 public immutable totalTime;

    bool public initialised = false;

    mapping(address => uint256) public totalLocked;
    mapping(address => uint256) public totalClaimed;

    event Funded(address indexed recipient, uint256 reward);
    event Cancelled(address indexed recipient);
    event Claim(address indexed user, uint256 amount, bool locked);

    /**
     * @param rewardToken_    Reward token (LIQ)
     * @param admin_          Admin to cancel rewards
     * @param liqLocker_      Contract where rewardToken can be staked
     * @param startTime_      Timestamp when claim starts
     * @param endTime_        When vesting ends
     */
    constructor(
        address rewardToken_,
        address admin_,
        address liqLocker_,
        uint256 startTime_,
        uint256 endTime_
    ) {
        require(startTime_ >= block.timestamp, "start must be future");
        require(endTime_ > startTime_, "end must be greater");

        rewardToken = IERC20(rewardToken_);
        admin = admin_;
        funder = msg.sender;
        liqLocker = ILiqLocker(liqLocker_);

        startTime = startTime_;
        endTime = endTime_;
        totalTime = endTime - startTime;
        require(totalTime >= 16 weeks, "!short");
    }

    /***************************************
                    SETUP
    ****************************************/

    /**
     * @notice Change contract admin
     * @param _admin New admin address
     */
    function setAdmin(address _admin) external {
        require(msg.sender == admin, "!auth");
        admin = _admin;
    }

    /**
     * @notice Change locker contract address
     * @param _liqLocker Aura Locker address
     */
    function setLocker(address _liqLocker) external {
        require(msg.sender == admin, "!auth");
        liqLocker = ILiqLocker(_liqLocker);
    }

    /**
     * @notice Fund recipients with rewardTokens
     * @param _recipient  Array of recipients to vest rewardTokens for
     * @param _amount     Array of amount of rewardTokens to vest
     */
    function fund(address[] calldata _recipient, uint256[] calldata _amount) external nonReentrant {
        require(_recipient.length == _amount.length, "!arr");
        require(!initialised, "initialised already");
        require(msg.sender == funder, "!funder");
        require(block.timestamp < startTime, "already started");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _recipient.length; i++) {
            uint256 amount = _amount[i];

            totalLocked[_recipient[i]] += amount;
            totalAmount += amount;

            emit Funded(_recipient[i], amount);
        }
        rewardToken.safeTransferFrom(msg.sender, address(this), totalAmount);
        initialised = true;
    }

    /**
     * @notice Cancel recipients vesting rewardTokens
     * @param _recipient Recipient address
     */
    function cancel(address _recipient) external nonReentrant {
        require(msg.sender == admin, "!auth");
        require(totalLocked[_recipient] > 0, "!funding");

        _claim(_recipient, false);

        uint256 delta = remaining(_recipient);
        rewardToken.safeTransfer(admin, delta);

        totalLocked[_recipient] = 0;

        emit Cancelled(_recipient);
    }

    /***************************************
                    VIEWS
    ****************************************/

    /**
     * @notice Available amount to claim
     * @param _recipient Recipient to lookup
     */
    function available(address _recipient) public view returns (uint256) {
        uint256 vested = _totalVestedOf(_recipient, block.timestamp);
        return vested - totalClaimed[_recipient];
    }

    /**
     * @notice Total remaining vested amount
     * @param _recipient Recipient to lookup
     */
    function remaining(address _recipient) public view returns (uint256) {
        uint256 vested = _totalVestedOf(_recipient, block.timestamp);
        return totalLocked[_recipient] - vested;
    }

    /**
     * @notice Get total amount vested for this timestamp
     * @param _recipient  Recipient to lookup
     * @param _time       Timestamp to check vesting amount for
     */
    function _totalVestedOf(address _recipient, uint256 _time) internal view returns (uint256 total) {
        if (_time < startTime) {
            return 0;
        }
        uint256 locked = totalLocked[_recipient];
        uint256 elapsed = _time - startTime;
        total = AuraMath.min((locked * elapsed) / totalTime, locked);
    }

    /***************************************
                    CLAIM
    ****************************************/

    function claim(bool _lock) external nonReentrant {
        _claim(msg.sender, _lock);
    }

    /**
     * @dev Claim reward token (Aura) and lock it.
     * @param _recipient  Address to receive rewards.
     * @param _lock       Lock rewards immediately.
     */
    function _claim(address _recipient, bool _lock) internal {
        uint256 claimable = available(_recipient);

        totalClaimed[_recipient] += claimable;

        if (_lock) {
            require(address(liqLocker) != address(0), "!liqLocker");
            rewardToken.safeApprove(address(liqLocker), claimable);
            liqLocker.lock(_recipient, claimable);
        } else {
            rewardToken.safeTransfer(_recipient, claimable);
        }

        emit Claim(_recipient, claimable, _lock);
    }
}
