// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract NovaMax is ERC20, Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bool private _initialized;

    uint256 public totalAmountCap; // 总募集金额上限
    uint256 public totalAmountActual; // 实际总募集金额
    uint256 public minAmount;  // 最小购买金额
    uint256 public annualizedRateOfReturn; // 年化收益率，18 位小数
    uint256 public rateOfReturn; // 计算出来的到期收益率，18 位小数

    uint256 public startTimestamp; // 募集期开始时间、单位 秒
    uint256 public endTimestamp; // 募集期结束时间、单位 秒
    uint256 public lockDuration; // 锁定期时长、单位 秒

    bool private _targetIsETH; // 募集目标是否是 ETH
    IERC20 private _targetToken; // 目标 ERC20 合约
    uint256 private _exchangeRate; // 当前合约和目标合约的 decimal() 差异

    event Subscription(address indexed subscriber, uint256 amount); // 申购事件
    event Redemption(address indexed redeemer, uint256 amount); // 赎回事件

    constructor() ERC20("", "") {}

    function init(
        address owner_,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenTotalSupply,
        uint256 totalAmountCap_,
        uint256 minAmount_,
        uint256 startTimestamp_,
        uint256 endTimestamp_,
        uint256 lockDuration_,
        uint256 annualizedRateOfReturn_,
        address targetTokenAddress_
    ) external {
        require(!_initialized, "Contract already initialized");
        require(startTimestamp_ < endTimestamp_ , "The start time of fundraising is greater than end time of fundraising");
        require(block.timestamp < endTimestamp_ , "The current time is greater than end time of subscription");

        _name = tokenName;
        _symbol = tokenSymbol;
        _mint(address(this), tokenTotalSupply);

        _transferOwnership(owner_);

        totalAmountCap = totalAmountCap_;
        minAmount = minAmount_;

        startTimestamp = startTimestamp_;
        endTimestamp = endTimestamp_;
        lockDuration = lockDuration_;

        annualizedRateOfReturn = annualizedRateOfReturn_;
        rateOfReturn = annualizedRateOfReturn_.div(365).mul(lockDuration.div(86400));

        if (targetTokenAddress_ == address(0)) {
            _targetIsETH = true;
            _exchangeRate = 1;
        } else {
            _targetIsETH = false;
            _targetToken = IERC20(targetTokenAddress_);
            _exchangeRate = tokenTotalSupply.div(totalAmountCap_);
        }

        _initialized = true;
    }

    receive() external payable {
        require(_targetIsETH, "ETH is not supported");
    }

    /**
    *
    * 0: Waiting
    * 1: Fundraising
    * 2: Lock-in
    * 3: Redemption
    *
     */
    function status() public view returns(uint256 status_) {
        if (block.timestamp >= endTimestamp.add(lockDuration)) {
            status_ = 3;
        } else if (block.timestamp >= endTimestamp) {
            status_ = 2;
        } else if (block.timestamp >= startTimestamp) {
            status_ = 1;
        } else {
            status_ = 0;
        }
    }

    function getBalance() public view returns (uint256) {
        if(_targetIsETH) {
            return address(this).balance;
        } else {
            return _targetToken.balanceOf(address(this));
        }
    }


    function withdraw(address to) external onlyOwner {
        uint256 status_ = status();
        require(status_ == 2 || status_ == 3, "Can only be withdrawn after the fundraising is completed");

        // 销毁剩余代币
        uint256 shares = balanceOf(address(this));
        if (shares > 0) {
            _burn(address(this), shares);
        }

        // 默认可以提取全部资产
        uint256 withdrawAmount = getBalance();
        require(withdrawAmount > 0, "The balance is zero");

        // 如果状态是赎回期，则只能提取多付的金额
        if (status_ == 3) {
            withdrawAmount -= _calRedemptionAmountWithProfit(totalSupply());
            require(withdrawAmount > 0, "There is no overpayment");
        }

        if(_targetIsETH) {
            payable(to).transfer(withdrawAmount);
        } else {
            _targetToken.safeTransfer(to, withdrawAmount);
        }
    }

    function subscriptionByETH() external payable {
        require(_targetIsETH, "ETH is not supported");
        require(status() == 1, "Currently not in the subscription period");
        require(msg.value >= minAmount, "Stake Failed, subcription quantity is not avaliable");
        require(msg.value.add(totalAmountActual) <= totalAmountCap, "Stake Failed, subcription quantity is not avaliable");

        uint256 shares_ = msg.value.mul(_exchangeRate);
        _transfer(address(this), msg.sender, shares_);

        totalAmountActual += msg.value;
        emit Subscription(msg.sender, msg.value);
    }

    function subscriptionByToken(uint256 amount) external {
        require(!_targetIsETH, "Only ETH is supported");
        require(status() == 1, "Currently not in the subscription period");
        require(amount >= minAmount, "Stake Failed, subcription quantity is not avaliable");
        require(amount.add(totalAmountActual) <= totalAmountCap, "Stake Failed, subcription quantity is not avaliable");

        _targetToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 shares_ = amount.mul(_exchangeRate);
        _transfer(address(this), msg.sender, shares_);

        totalAmountActual += amount;
        emit Subscription(msg.sender, amount);
    }

    function redemption() external {
        require(status() == 3, "Not redeemable before the redemption period");

        uint256 shares = balanceOf(msg.sender);
        require(shares > 0, "Insufficient balance");

        _burn(msg.sender, shares);

        uint256 amountWithProfit = _calRedemptionAmountWithProfit(shares);
        require(getBalance() >= amountWithProfit, "There are many operators in line, please try again later");

        if (_targetIsETH) {
            payable(msg.sender).transfer(amountWithProfit);
        } else {
            _targetToken.safeTransfer(msg.sender, amountWithProfit);
        }

        emit Redemption(msg.sender, amountWithProfit);
    }

    function _calRedemptionAmountWithProfit(uint256 shares) internal view returns (uint256) {
        return shares.div(_exchangeRate).mul(rateOfReturn.add(1e18)).div(1e18);
    }
}