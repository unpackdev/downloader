// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IERC20Metadata.sol";
import "./IFund.sol";
import "./IGovToken.sol";

pragma experimental ABIEncoderV2;

contract LockPosition {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// period count
    uint8 public periodCount;

    /// owner
    address public owner;
    /// Investment payment receiving address
    address public recipient;
    /// Investment token address
    address public target;

    ///@dev list address of investment auditor funds
    address[] public funds;

    /// Sales period configuration
    mapping(uint256 => SalesPeriod) public salesPeriods;
    /// Investment details
    mapping(address => mapping(uint256 => LockedInfo)) public investList;

    /// invest
    event Invest(address indexed investor, uint256 period, uint256 number, uint256 amount);
    //un lock
    event unLocked(address indexed investor, uint256 period, uint256 number);

    /// @notice Investment information
    struct LockedInfo {
        uint256 purchased;
        uint256 lockedAmount;
        uint256 unlockedAmount;
    }

    /// @notice Investment period
    struct SalesPeriod {
        uint256 period;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 maximumSales;
        uint256 maximumPurchase;
        uint256 salesVolume;
        uint256 lockTime;
        uint256 fundLimit;
        address pay;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @notice Is it a fund investor
    modifier onlyFundInvestor(uint256 period) {
        require(isAllowInvest(msg.sender,period), "not fund investor");
        _;
    }

    ///@notice  create
    ///@param _target invest token address
    ///@param _recipient token recipient address
    constructor (address _target, address _recipient) public {
        init(_target, _recipient);
    }

    ///@notice setting init info
    function init(address _target, address _recipient) public {
        require(owner == address(0), 'already init');
        owner = msg.sender;
        target = _target;
        recipient = _recipient;
    }


    ///@notice calc token 10**decimals
    ///@param token token address
    function calcDecimal(address token) public view returns (uint256){
        IERC20Metadata ioToken = IERC20Metadata(token);
        return 10 ** uint256(ioToken.decimals());
    }

    ///@notice update recipient address
    function isAllowInvest(address account,uint256 period)public view returns(bool){
        SalesPeriod memory salesPeriod = salesPeriods[period];
        bool isFundInvestor = false;
        for (uint256 i = 0; i < funds.length; i++) {
            IFund fund = IFund(funds[i]);
            uint256 balance = fund.balanceOf(account);
            uint256 amount = fund.convertToCash(balance);
            uint256 assets = salesPeriod.fundLimit.mul(calcDecimal(fund.ioToken()));
            if (amount >= assets) {
                isFundInvestor = true;
                break;
            }
        }
        return isFundInvestor;
    }

    ///@notice update recipient address
    function updateRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    ///@notice Can only be called by the current owner.
    ///@dev Transfers ownership of the contract to a new account (`newOwner`).
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    ///@notice bind fund
    ///@param _funds Fund address
    function bindFund(address[] memory _funds) external onlyOwner {
        funds = _funds;
    }

    ///@notice save sale period info
    ///@param salesPeriod period info
    function saveSalesPeriod(SalesPeriod memory salesPeriod) external onlyOwner {
        require(salesPeriods[salesPeriod.period].pay == address(0)
            || salesPeriods[salesPeriod.period].startTime >= block.timestamp, 'already active');
        if (salesPeriods[salesPeriod.period].period == 0) {
            periodCount++;
        }
        salesPeriods[salesPeriod.period] = salesPeriod;
    }

    ///@notice invest
    ///@param period period id
    ///@param amount invest amount
    function invest(uint256 period, uint256 amount) external onlyFundInvestor(period) {
        require(amount > 0, 'minimumSales');
        SalesPeriod storage salesPeriod = salesPeriods[period];
        require(salesPeriod.startTime <= block.timestamp
            && salesPeriod.endTime >= block.timestamp, 'not active');
        LockedInfo storage lockedInfo = investList[msg.sender][period];
        uint256 surplusAmount = salesPeriod.maximumPurchase.sub(lockedInfo.purchased);
        require(surplusAmount >= amount, 'maximumPurchase');
        uint256 number = amount.mul(calcDecimal(target)).div(salesPeriod.price);
        uint256 surplusVolume = salesPeriod.maximumSales.sub(salesPeriod.salesVolume);
        require(surplusVolume >= number, 'maximumSales');
        IERC20(salesPeriod.pay).safeTransferFrom(msg.sender, recipient, amount);
        salesPeriod.salesVolume = salesPeriod.salesVolume.add(number);
        lockedInfo.lockedAmount = lockedInfo.lockedAmount.add(number);
        lockedInfo.purchased = lockedInfo.purchased.add(amount);
        emit Invest(msg.sender, period, number, amount);
    }

    ///@notice unlock
    ///@param period period id
    function unlock(uint256 period) external {
        SalesPeriod memory salesPeriod = salesPeriods[period];
        require(salesPeriod.pay != address(0), 'non-existent');
        require(block.timestamp >= salesPeriod.endTime, 'not complete');
        require(block.timestamp.sub(salesPeriod.endTime) >= salesPeriod.lockTime, 'locked');
        LockedInfo storage lockedInfo = investList[msg.sender][period];
        uint256 unlockAmount = lockedInfo.lockedAmount;
        IGovToken(target).mint(msg.sender, unlockAmount);
        lockedInfo.unlockedAmount = lockedInfo.unlockedAmount.add(unlockAmount);
        lockedInfo.lockedAmount = 0;
        emit unLocked(msg.sender, period, unlockAmount);
    }
}
