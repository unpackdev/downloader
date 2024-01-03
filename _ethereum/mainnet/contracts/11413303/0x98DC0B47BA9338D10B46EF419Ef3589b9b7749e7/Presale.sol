// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract Presale is Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint;

  // @dev The denominator component for values specified in basis points.
  uint internal constant BASIS_POINTS_DEN = 100;

  // @dev sale token address
  IERC20 public token;
  // @dev treasury wallet to forward invested eth to
  address payable public treasury;
  // @dev block to start presale after
  uint public startBlock;
  // @dev block to end presale (up to)
  uint public endBlock;
  // @dev block to be able to claim value which was not claimed by investors
  uint public endRefundBlock;
  // @dev total supply of tokens available to be sold
  uint public supply;
  // @dev token to ether rate base on `BASIS_POINTS_DEN` denominator
  // calculus: eth * `rate` / `BASIS_POINTS_DEN`
  // example: 1 eth * 10 / 100 = 0.1 token (rate=10...1 eth= 0.1 token)
  uint public rate;
  // @dev how much a whitelist address is able to invest
  uint public maxInvestment;

  // @dev amount of ether invested
  uint public invested = 0;
  // @dev amount of tokens sold
  uint public tokensSold = 0;
  // @dev presale is public or whitelisted addresses
  bool isPublic;
  // @dev whitelisted investor addresses
  mapping (address => bool) investors;
  // @dev investments in ether done by whitelisted investors
  mapping (address => uint) investments;
  // @dev tokens transfered to a whitelisted investors
  mapping (address => uint) receivedTokens;
  // @dev refunds available to an whitelisted investor
  mapping (address => uint) refunds;

  /**
   * @dev Emitted when the presale details update is triggered by `account`.
   */
  event DetailsUpdated(address account);

  /**
   * @dev Emitted when the `investor` is whitelisted by `account`.
   */
  event Whitelisted(address investor, address account);

  /**
   * @dev Emitted when the `investor` is unwhitelisted by `account`.
   */
  event Unwhitelisted(address investor, address account);

  /**
   * @dev Emitted when the `investor` invests `value` ether and received `tokensReceived` tokens on `wallet`
   * as well as gets back a refund of `valueRefunded` ether
   */
  event Invested(address investor, address wallet, uint value, uint tokensReceived, uint valueRefunded);

  /**
   * @dev Emitted when the `investor` claims the refund of `value` ether
   */
  event Refunded(address investor, uint value);

  /**
   * @dev Modifier to make a function callable only when refunds are available
   */
  modifier whenRefundable() {
    require(endRefundBlock >= block.number, "Value is not refundable anymore");
    require(paused() == false, "Presale is paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when refunds are NOT available
   */
  modifier whenNotRefundable() {
    require(endRefundBlock < block.number, "Value is still refundable");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the presale is running
   */
  modifier whenRunning() {
    require(startBlock <= block.number, "Presale has not started yet");
    require(endBlock >= block.number, "Presale has finalized");
    require(paused() == false, "Presale is paused");
    _;
  }

  /**
    * @dev Modifier to make a function callable only when presale has finalized
    */
  modifier afterEnded() {
    require(endBlock < block.number, "Presale has not finalized yet");
    _;
  }

  /**
    * @dev check if presale is public
    */
  modifier isPublicOrWhitelist() {
    if (!isPublic) {
      require(investors[_msgSender()], "Investor is not whitelisted");
    }
    _;
  }

  constructor(
    address _owner,
    address payable _treasury,
    address _token,
    uint _startBlock,
    uint _endBlock,
    uint _endRefundBlock,
    uint _supply,
    uint _rate,
    uint _maxInvestment,
    bool _isPublic
  ) public {
    require(_treasury != address(0), "Not valid treasury wallet address");
    require(_token != address(0), "Not valid token address");

    treasury = _treasury;
    token = IERC20(_token);
    updateDetails(
      _startBlock,
      _endBlock,
      _endRefundBlock,
      _supply,
      _rate,
      _maxInvestment,
      _isPublic
    );
    transferOwnership(_owner);
  }

  /**
   * @dev Calculate investment details
   */
  function calculateInvestment(address investor, uint value) public view
    returns (uint investment, uint tokensToSend, uint refundValue) {
    uint remainingInvestment = availableInvestment(investor);

    if (value <= remainingInvestment) {
      refundValue = 0;
    } else {
      refundValue = value.sub(remainingInvestment);
    }

    investment = value.sub(refundValue);
    tokensToSend = investment.mul(rate).div(BASIS_POINTS_DEN);

    // if there are too few tokens remaining in supply
    if (tokensToSend > supply) {
      uint extraTokens = tokensToSend.sub(supply);
      tokensToSend = supply;
      refundValue += extraTokens.mul(BASIS_POINTS_DEN).div(rate);
      investment = value.sub(refundValue);
    }
  }

  /**
   * @dev Check if an address is whitelisted investor
   */
  function isInvestor(address investor) public view returns (bool) {
    return investors[investor] == true;
  }

  /**
   * @dev Get amount that was already invested by an investor
   */
  function investedAmount(address investor) public view returns (uint) {
    return investments[investor];
  }

  /**
   * @dev Get amount of tokens received by an investor
   */
  function tokensReceived(address investor) public view returns (uint) {
    return receivedTokens[investor];
  }

  /**
   * @dev Check the value of available investment for an investor
   */
  function availableInvestment(address investor) public view returns (uint) {
    return maxInvestment.sub(investedAmount(investor));
  }

  /**
   * @dev Get value available to being refunded to an investor
   */
  function availableRefund(address investor) public view returns (uint) {
    return refunds[investor];
  }

  function claimRefund(address payable investor) public whenRefundable {
    uint refundValue = availableRefund(investor);
    refunds[investor] = 0;
    investor.transfer(refundValue);

    emit Refunded(investor, refundValue);
  }

  /**
   * @dev Invest into presale
   *
   * `investor` is sending ether and receiving tokens on `wallet` address and partial or full refund back on `invesor` address.
   */
  function invest(address wallet) public payable whenRunning nonReentrant isPublicOrWhitelist {
    address investor = _msgSender();

    require(address(wallet) != address(0), "No wallet to transfer tokens to");
    require(msg.value > 0, "There's no value in transaction");
    require(supply > 0, "No remaining supply");

    (uint investment, uint tokensToSend, uint refundValue) = calculateInvestment(investor, msg.value);
    uint presaleTokenAllocation = token.balanceOf(address(this));

    require(presaleTokenAllocation >= tokensToSend, "Presale contract own less tokens than needed");
    require(investment > 0, "Zero amount for investment");

    supply -= tokensToSend;
    invested += investment;
    tokensSold += tokensToSend;
    investments[investor] += investment;
    receivedTokens[investor] += tokensToSend;
    refunds[investor] += refundValue;

    token.transfer(wallet, tokensToSend);
    treasury.transfer(investment);

    emit Invested(investor, wallet, msg.value, tokensToSend, refundValue);
  }

  /**
   * @dev claim back unsold tokens
   */
  function claimUnsoldTokens(address wallet) public afterEnded onlyOwner {
    supply = 0;
    // in case the contract got more tokens than the supply
    token.transfer(wallet, token.balanceOf(address(this)));
  }

  /**
   * @dev claim back unsold tokens
   */
  function claimUnclaimedRefunds(address payable wallet) public whenNotRefundable onlyOwner {
    wallet.transfer(address(this).balance);
  }

  /**
   * @dev whitelist a list of investors
   */
  function whitelistInvestors(address[] memory _investors) public onlyOwner {
    for (uint i = 0; i < _investors.length; i++) {
      address investor = _investors[i];
      investors[investor] = true;
      emit Whitelisted(investor, _msgSender());
    }
  }

  /**
   * @dev unwhitelist a list of investors
   */
  function unwhitelistInvestors(address[] memory _investors) public onlyOwner {
    for (uint i = 0; i < _investors.length; i++) {
      address investor = _investors[i];
      investors[investor] = false;
      emit Unwhitelisted(investor, _msgSender());
    }
  }

  /**
   * @dev Temporary pause the presale
   */
  function updatePaused(bool paused) public onlyOwner {
    if (paused == true) {
      _pause();
    } else {
      _unpause();
    }
  }

  /**
   * @dev Update presale details
   */
  function updateDetails(
    uint _startBlock,
    uint _endBlock,
    uint _endRefundBlock,
    uint _supply,
    uint _rate,
    uint _maxInvestment,
    bool _isPublic
  ) public onlyOwner {
    require(_endBlock > block.number, "End block must be greater than the current one");
    require(_endBlock > _startBlock, "Start block should be less than the end block");
    require(_endRefundBlock >= _endBlock, "Refund block must be greater than the end block");
    require(_rate > 0, "Rate must be greater than 0");
    require(_maxInvestment > 0, "Noone can invest nothing");

    startBlock = _startBlock;
    endBlock = _endBlock;
    endRefundBlock = _endRefundBlock;
    rate = _rate;
    maxInvestment = _maxInvestment;
    isPublic = _isPublic;

    if (_supply > 0) {
      supply = _supply;
    }

    emit DetailsUpdated(_msgSender());
  }

  /**
   * @dev This function is called for all messages sent to
   * this contract, except plain Ether transfers
   * (there is no other function except the receive function).
   * Any call with non-empty calldata to this contract will execute
   * the fallback function (even if Ether is sent along with the call).
   */
  fallback() external payable {
    invest(_msgSender());
  }

  /**
   * @dev This function is called for plain Ether transfers, i.e.
   * for every call with empty calldata.
   */
  receive() external payable {
    invest(_msgSender());
  }
}
