// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

interface IOldSupplyTreasury {
    function frozenUnderlyToken() external view returns (uint256);
}

contract SupplyTreasuryFund is ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant FULL_UTILIZATION_RATE = 1000;
    uint256 public constant RATE_DENOMINATOR = 10;
    uint256 public constant PRECISION = 1e18;

    address public oldSupplyTreasury;
    address public underlyToken;
    address public owner;
    address public governance;

    uint256 public frozenUnderlyToken;
    uint256 public baseRate = 9512937595;
    uint256 public x1 = 600;
    uint256 public y1 = 47564687975;
    uint256 public y2 = 95129375951;

    bool public isErc20;
    bool private initialized;

    event Migrate(address _newTreasuryFund, bool _setReward);
    event DepositFor(address _for, uint256 _amount, bool _isErc20);
    event WithdrawFor(address _to, uint256 _amount);
    event Borrow(address _to, uint256 _lendingAmount, uint256 _lendingInterest);
    event RepayBorrow(uint256 _frozenUnderlyToken, uint256 _lendingAmount);
    event SetGovernance(address _governance);

    modifier onlyInitialized() {
        require(initialized, "!initialized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "SupplyTreasuryFund: !authorized");
        _;
    }

    modifier onlyGovernance() {
        require(governance == msg.sender, "SupplyTreasuryFund: caller is not the governance");
        _;
    }

    constructor(
        address _owner,
        address _governance,
        address _oldSupplyTreasury
    ) public {
        owner = _owner;
        oldSupplyTreasury = _oldSupplyTreasury;
        governance = _governance;
    }

    // compatible old pool
    function initialize(
        address _virtualBalance,
        address _underlyToken,
        bool _isErc20
    ) public onlyOwner {
        initialize(_underlyToken, _isErc20);
    }

    function initialize(address _underlyToken, bool _isErc20) public onlyOwner {
        require(!initialized, "initialized");

        underlyToken = _underlyToken;
        isErc20 = _isErc20;

        if (oldSupplyTreasury != address(0)) {
            frozenUnderlyToken = IOldSupplyTreasury(oldSupplyTreasury).frozenUnderlyToken();
        }

        initialized = true;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;

        emit SetGovernance(_governance);
    }

    function migrate(address _newTreasuryFund, bool _setReward) external onlyOwner nonReentrant returns (uint256) {
        uint256 bal;

        if (isErc20) {
            bal = IERC20(underlyToken).balanceOf(address(this));

            sendToken(underlyToken, owner, bal);
        } else {
            bal = address(this).balance;

            if (bal > 0) {
                sendToken(address(0), owner, bal);
            }
        }

        emit Migrate(_newTreasuryFund, _setReward);

        return bal;
    }

    function _depositFor(address _for, uint256 _amount) internal {
        emit DepositFor(_for, _amount, isErc20);
    }

    function depositFor(address _for) public payable onlyInitialized onlyOwner nonReentrant {
        _depositFor(_for, msg.value);
    }

    function depositFor(address _for, uint256 _amount) public onlyInitialized onlyOwner nonReentrant {
        _depositFor(_for, _amount);
    }

    function withdrawFor(address _to, uint256 _amount) public onlyInitialized onlyOwner nonReentrant returns (uint256) {
        if (isErc20) {
            sendToken(underlyToken, _to, _amount);
        } else {
            sendToken(address(0), _to, _amount);
        }

        emit WithdrawFor(_to, _amount);

        return _amount;
    }

    function sendToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) internal {
        if (_token == address(0)) {
            payable(_receiver).sendValue(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    function borrow(
        address _to,
        uint256 _lendingAmount,
        uint256 _lendingInterest
    ) public onlyInitialized nonReentrant onlyOwner returns (uint256) {
        frozenUnderlyToken = frozenUnderlyToken.add(_lendingAmount);

        if (isErc20) {
            sendToken(underlyToken, _to, _lendingAmount.sub(_lendingInterest));

            if (_lendingInterest > 0) {
                sendToken(underlyToken, owner, _lendingInterest);
            }
        } else {
            sendToken(address(0), _to, _lendingAmount.sub(_lendingInterest));

            if (_lendingInterest > 0) {
                sendToken(address(0), owner, _lendingInterest);
            }
        }

        emit Borrow(_to, _lendingAmount, _lendingInterest);

        return _lendingInterest;
    }

    function repayBorrow() public payable onlyInitialized nonReentrant onlyOwner {
        frozenUnderlyToken = frozenUnderlyToken.sub(msg.value);

        emit RepayBorrow(frozenUnderlyToken, msg.value);
    }

    function repayBorrow(uint256 _lendingAmount) public onlyInitialized nonReentrant onlyOwner {
        frozenUnderlyToken = frozenUnderlyToken.sub(_lendingAmount);

        emit RepayBorrow(frozenUnderlyToken, _lendingAmount);
    }

    function claim() public onlyInitialized onlyOwner nonReentrant returns (uint256) {
        return 0;
    }

    function getBalance() public view returns (uint256) {
        if (isErc20) {
            return IERC20(underlyToken).balanceOf(address(this));
        }

        return address(this).balance;
    }

    function getReward(address _for) public onlyOwner nonReentrant {}

    function getUtilizationRate() public view returns (uint256) {
        uint256 totalBal = getBalance().add(frozenUnderlyToken);

        if (totalBal == 0) {
            return 0;
        }

        return frozenUnderlyToken.mul(1e18).div(totalBal);
    }

    function setBaseRate(uint256 _v) external onlyGovernance {
        require(_v < 23782343988, "!_v");
        require(_v > 0, "!_v");

        baseRate = _v;
    }

    function setX1(uint256 _v) external onlyGovernance {
        require(_v < 950, "!_v"); // 95%
        require(_v >= 500, "!_v"); // 5%

        x1 = _v;
    }

    function setY1(uint256 _v) external onlyGovernance {
        require(_v < 95129375952, "!_v");
        require(_v >= 14269406393, "!_v");
        require(_v > baseRate, "!y1 > b");

        y1 = _v;
    }

    function setY2(uint256 _v) external onlyGovernance {
        require(_v < 332952815830, "!_v");
        require(_v >= 71347031964, "!_v");
        require(_v > y1, "!y2 > y1");

        y2 = _v;
    }

    function getBorrowRatePerBlock() public view returns (uint256 borrowRate) {
        // x = utilization rate
        // y = borrow rate

        uint256 utilizationRate = getUtilizationRate().mul(100 * RATE_DENOMINATOR).div(PRECISION);

        if (utilizationRate <= x1) {
            // 0 <= x <= x1
            // y = (y1 - b) / x1 . x + b
            borrowRate = y1.sub(baseRate).mul(PRECISION).div(x1).mul(utilizationRate).div(PRECISION).add(baseRate);
        } else {
            // x1 <= x <= 1
            // y = (y2-y1) / (1 - x1) . x + y1 - (y2 - y1) / (1 - x1) .x1
            borrowRate = y2.sub(y1).mul(PRECISION).div(FULL_UTILIZATION_RATE.sub(x1)).mul(utilizationRate).div(PRECISION).add(y1).sub(
                y2.sub(y1).mul(PRECISION).div(FULL_UTILIZATION_RATE.sub(x1)).mul(x1).div(PRECISION)
            );
        }
    }
}
