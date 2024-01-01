// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract SimpleFairLaunch is Ownable, ReentrancyGuard {
  using Address for address payable;
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  bool public isInit;
  bool public isRefund;
  bool public isFinish;
  address payable public dev;
  uint public ethRaised;

  struct Pool {
    uint startTime;
    uint endTime;
    uint softCap;
    uint maxBuy;
    uint minBuy;
    uint tokenAmount;
    uint percentageOnTge;
    uint vestingPeriod;
  }

  Pool public pool;
  IERC20 public token;
  mapping(address => uint) public ethContribution;
  mapping(address => uint) public tokensReleased;

  modifier onlyActive {
    require(block.timestamp >= pool.startTime, "Presale must be active.");
    require(block.timestamp <= pool.endTime, "Presale must be active.");
    _;
  }

  modifier onlyRefund {
    require(
      isRefund == true || 
      (block.timestamp > pool.endTime && ethRaised < pool.softCap), "Refund unavailable."
    );
    _;
  }

  constructor() {
    isInit = false;
    isFinish = false;
    isRefund = false;
    ethRaised = 0;

    dev = payable(_msgSender());
  }

  receive() external payable {
    if (block.timestamp >= pool.startTime && block.timestamp <= pool.endTime) {
      purchase();
    } else {
      revert("Presale is closed");
    }
  }

  function getTokenPrice() external view returns (uint) {
    return _getTokenPrice();
  }

  function getUserInfo(address beneficiary) external view returns (uint ethAmount, uint tokenAmount, uint claimedAmount, uint vestedAmount) {
    ethAmount = ethContribution[beneficiary];
    tokenAmount = _getTokenAmount(beneficiary);
    claimedAmount = tokensReleased[beneficiary];
    vestedAmount = _getUserVested(beneficiary, tokenAmount);
  }

  function purchase() public payable onlyActive {
    require (!isRefund, "Presale has been cancelled.");
    require (!isFinish, "Presale has been finalized.");

    uint weiAmount = msg.value;
    _checkSaleRequirements(_msgSender(), weiAmount);
    ethRaised += weiAmount;
    ethContribution[_msgSender()] += weiAmount;
    emit Bought(_msgSender(), weiAmount);
  }

  function refund() external onlyRefund {
    uint refundAmount = ethContribution[_msgSender()];

    if (address(this).balance >= refundAmount) {
      if (refundAmount > 0) {
        ethContribution[_msgSender()] = 0;
        address payable recipient = payable(_msgSender());
        Address.sendValue(recipient, refundAmount);
        emit Refunded(recipient, refundAmount);
      }
    }
  }

  function claim() external nonReentrant {
    require (isFinish, "Can only claim if presale is finished");
    require (!isRefund, "Can not claim if refund is active");
    require (ethContribution[_msgSender()] > 0, "Nothing to claim");

    uint vestedAmount = _getUserVested(_msgSender(), _getTokenAmount(_msgSender()));

    if (vestedAmount > 0) {
      tokensReleased[_msgSender()] += vestedAmount;
      SafeERC20.safeTransfer(token, _msgSender(), vestedAmount);
      emit Claimed(_msgSender(), vestedAmount);
    }
  }

  function _getTokenPrice() internal view returns (uint) {
    return ethRaised * 1e18 / pool.tokenAmount;
  }

  function _getTokenAmount(address beneficiary) internal view returns (uint amount) {
    if (ethRaised > 0) amount = ethContribution[beneficiary] * 1e18 / _getTokenPrice();
  }

  function _getUserVested(address beneficiary, uint tokenAmount) internal view returns (uint releasableAmount) {
    if (tokenAmount > 0) {
      uint tokensOnTge = tokenAmount * pool.percentageOnTge / 100;
      uint tokensToVest = tokenAmount - tokensOnTge;
      uint alreadyReleased = tokensReleased[beneficiary];
      if (tokensToVest > 0) {
        uint vestedAmount = _getVestedAmount(tokensToVest, block.timestamp);
        releasableAmount = tokensOnTge + vestedAmount - alreadyReleased;
      } else {
        if (alreadyReleased == 0) {
          releasableAmount = tokensOnTge;
        } else {
          releasableAmount = 0;
        }
      }
    } else {
      releasableAmount = 0;
    }
  }

  function _getVestedAmount(uint _totalAmount, uint _timestamp) internal view returns (uint) {
    if (_timestamp < pool.endTime) {
      return 0;
    } else if (_timestamp > pool.endTime + pool.vestingPeriod) {
      return _totalAmount;
    } else {
      return (_totalAmount * (_timestamp - pool.endTime)) / pool.vestingPeriod;
    }
  }

  function _checkSaleRequirements(address _beneficiary, uint _amount) internal view { 
    require (_beneficiary != address(0), "Transfer to 0 address.");
    require (_amount != 0, "Wei Amount is 0");
    require (_amount >= pool.minBuy, "Min buy is not met.");
    require (_amount % pool.minBuy == 0, "Please only buy in increments of the minimum buy");
    require (_amount + ethContribution[_beneficiary] <= pool.maxBuy, "Max buy limit exceeded.");
    this;
  }

  function initSale(
    uint _startTime,
    uint _endTime,
    uint _softCap,
    uint _maxBuy,
    uint _minBuy,
    uint _tokenAmount,
    uint _percentageOnTge,
    uint _vestingPeriod
  ) external onlyOwner {        
    require (isInit == false, "Presale is not initialized");
    require (_startTime >= block.timestamp, "Invalid start time.");
    require (_endTime > block.timestamp, "Invalid end time.");
    require (_softCap % _minBuy == 0, "Soft cap must be multiple of min buy.");
    require (_minBuy <= _maxBuy, "Min buy must not be greater than max buy.");
    require (_minBuy > 0, "Min buy must exceed 0.");
    require (_percentageOnTge <= 100, "Percentage on tge must be lower or equal to 100");

    Pool memory newPool = Pool(
      _startTime,
      _endTime, 
      _softCap, 
      _maxBuy, 
      _minBuy,
      _tokenAmount,
      _percentageOnTge,
      _vestingPeriod
    );

    pool = newPool;
    isInit = true;
  }

  function setToken(
    address _token
  ) external onlyOwner {
    uint balanceBefore = IERC20(_token).balanceOf(address(this));
    SafeERC20.safeTransferFrom(IERC20(_token), _msgSender(), address(this), pool.tokenAmount);
    uint deltaBalance = IERC20(_token).balanceOf(address(this)) - balanceBefore;
    require (deltaBalance == pool.tokenAmount, "Please exclude the contract first");

    token = IERC20(_token);
  }

  function finishSale() external onlyOwner {
    require (ethRaised >= pool.softCap, "Soft Cap is not met.");
    require (block.timestamp > pool.startTime, "Can not finish before start");
    require (!isFinish, "Presale is already closed.");
    require (!isRefund, "Presale is in refund process.");

    isFinish = true;
    pool.endTime = block.timestamp;
    Address.sendValue(dev, address(this).balance);
  }

  function cancelSale() external onlyOwner onlyActive {
    require (!isFinish, "Sale is finished.");
    pool.endTime = 0;
    isRefund = true;

    emit Cancelled(_msgSender(), address(this));
  }

  event Cancelled(
    address indexed _inititator, 
    address indexed _presale
  );

  event Bought(
    address indexed _buyer, 
    uint _ethAmount
  );

  event Refunded(
    address indexed _refunder, 
    uint _ethAmount
  );
  
  event Claimed(
    address indexed _beneficiary,
    uint _tokenAmount
  );
}   