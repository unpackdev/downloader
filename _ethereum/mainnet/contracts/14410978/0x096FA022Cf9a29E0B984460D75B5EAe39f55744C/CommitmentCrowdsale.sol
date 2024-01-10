// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./Context.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

/**
 * @title CommitmentCrowdsale
 * @dev CommitmentCrowdsale is a contract for managing token crowdsale,
 * allowing investors to purchase the tokens with native coin.
 */
contract CommitmentCrowdsale is AccessControl, ReentrancyGuard {
  using SafeERC20 for IERC20;

  enum State { None, Opened, Closed }

  uint256 public constant TOKEN_DECIMALS = 18;
  uint256 public constant PRECISION = 10 ** 18;

  bool private _paused;
  State private _state;
  uint256 private _price;
  uint256 private _min;
  uint256 private _max;
  uint256 private _timeout;
  uint256 private _tokensSold;
  uint256 private _totalSupply;
  
  // Wallet for commitment treasury
  address private _wallet;

  // Commitment storage
  mapping(address => uint256) private _commitment;

  event PauseUpdated(bool paused);
  event SaleOpened(address account);
  event SaleClosed(address account);
  event SaleSetup(uint256 price, uint256 min, uint256 max, uint256 totalSupply);
  event Committed(address indexed beneficiary, uint256 amount);
  event Unstaked(address indexed beneficiary, uint256 amount);
  event CommitmentFulfilled(address indexed beneficiary, uint256 commitment, uint256 amount);

  constructor(address wallet_) {
    _wallet = wallet_;
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /**
   * @dev returns true if the crowdsale is paused.
   */
  function isPaused()
    public
    view
    returns (bool)
  {
    return _paused;
  }

  /**
   * @dev updates pause state of the crowdsale.
   * @param paused_  new state.
   */
  function setPaused(bool paused_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _paused = paused_;

    emit PauseUpdated(_paused);
  }

  /**
   * @dev returns setup parameters.
   */
  function getSetup()
    external
    view 
    returns (State state, uint256 price, uint256 min, uint256 max, uint256 timeout, uint256 tokensSold, uint256 totalSupply) 
  {
    state = _state;
    price = _price;
    min = _min;
    max = _max;
    timeout = _timeout;
    tokensSold = _tokensSold;
    totalSupply = _totalSupply;
  }

  /**
   * @dev setup of sale.
   * @param price_  price per token unit.
   * @param min_  min commitment.
   * @param max_  max commitment.
   * @param totalSupply_  max amount of tokens available in the sale.
   */
  function setup(uint256 price_, uint256 min_, uint256 max_, uint256 totalSupply_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!isPaused(), "setup: sale is paused");

    _price = price_;
    _min = min_;
    _max = max_;
    _totalSupply = totalSupply_;

    emit SaleSetup(price_, min_, max_, totalSupply_);
  }

  /**
   * @dev opens sale for investment.
   * @param timeout_  sale timeout.
   */
  function openSale(uint256 timeout_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!isPaused(), "openSale: sale is paused");
    require(_state == State.None, "openSale: sale is already opened or closed");
    require(timeout_ > block.timestamp, "openSale: invalid timeout");

    _state = State.Opened;
    _timeout = timeout_;

    emit SaleOpened(_msgSender());
  }

  /**
   * @dev closes sale for investment.
   */
  function closeSale()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!isPaused(), "closeSale: sale is paused");
    require(_state == State.Opened, "closeSale: sale is not opened");

    _state = State.Closed;

    emit SaleClosed(_msgSender());
  }

  /**
   * @dev returns commitment balance of beneficiary.
   * @param beneficiary_  address performing the token purchase.
   */
  function commitmentOf(address beneficiary_)
    public
    view
    returns (uint256)
  {
    return _commitment[beneficiary_];
  }

  /**
   * @dev commit native token.
   */
  function commit()
    external
    payable
    nonReentrant()
  {
    address beneficiary = _msgSender();
    uint256 amount = msg.value;

    require(!isPaused(), "commit: sale is paused");
    require(_state == State.Opened, "commit: sale is not opened");
    require(_min <= amount, "commit: min condition not satisfied");
    require(_max >= commitmentOf(beneficiary) + amount, "commit: max condition not satisfied");
    require(block.timestamp < _timeout, "commit: sale timeout");

    _commitment[beneficiary] += amount;

    emit Committed(beneficiary, amount);
  }

  /**
   * @dev withdraw committed native coins.
   */
  function withdraw()
    external
    nonReentrant()
  {
    address beneficiary = _msgSender();
    require(!isPaused(), "withdraw: sale is paused");
    require(_commitment[beneficiary] >= 0, "withdraw: amount exceeded commitment balance");

    if(_state == State.Opened) {
      require(block.timestamp > _timeout, "withdraw: commitment not elapsed");
    } else {
      require(_state == State.Closed, "withdraw: sale is not closed");
    }
    
    uint256 amount = _commitment[beneficiary];
    _commitment[beneficiary] = 0;
    (bool success, ) = beneficiary.call{value: amount}("");
    require(success, "withdraw: transfer failed");

    emit Unstaked(beneficiary, amount);
  }

  /**
   * @dev runs sale for winners
   * @param beneficiaries_  pre-committed winners.
   */
  function run(address[] calldata beneficiaries_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_state == State.Opened, "run: sale is not opened");
    require(block.timestamp < _timeout, "run: sale timeout");

    uint256 totalCommitment;
    for(uint256 i = 0; i < beneficiaries_.length; i++) {
      totalCommitment += _commitment[beneficiaries_[i]];
    }

    uint256 totalTokens = _getTokenAmount(totalCommitment);
    require(totalTokens + _tokensSold <= _totalSupply, "run: total supply exceeded");
    _tokensSold = totalTokens;

    (bool success, ) = _wallet.call{value: totalCommitment}("");
    require(success, "run: transfer failed");

    for(uint256 i = 0; i < beneficiaries_.length; i++) {
      address beneficiary = beneficiaries_[i];
      uint256 commitment = _commitment[beneficiary];
      if(commitment > 0) {
        totalCommitment += commitment;
        emit CommitmentFulfilled(beneficiary, commitment, _getTokenAmount(commitment));
      }
    }
  }

  /**
   * @dev returns amount of purchased tokens with specified commitment.
   * @param commitment_  amount of commitment.
   */
  function _getTokenAmount(uint256 commitment_)
    internal
    view
    returns (uint256)
  {
    return (commitment_ * PRECISION) / _price;
  }

  /**
   * @dev allows to recover ERC20 from contract.
   * @param token_  ERC20 token address.
   * @param amount_  ERC20 token amount.
   */
  function recoverERC20(address token_, uint256 amount_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    IERC20(token_).safeTransfer(_wallet, amount_);
  }

  /**
   * @dev allows to recover native coin from contract.
   * @param amount_  native coin amount.
   */
  function recover(uint256 amount_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    (bool success, ) = _wallet.call{value: amount_}("");
    require(success, "recover: transfer failed");
  }

  receive()
    external
    payable 
  {
    // solhint-disable-previous-line no-empty-blocks
  }
}
