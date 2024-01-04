// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract PToken is ERC20UpgradeSafe, OwnableUpgradeSafe {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice ERC20 that is used for purchasing pTokens
  IERC20 public acceptedToken;

  /// @notice Price per pToken, denominated in units of `acceptedToken`
  uint256 public price;

  /// @dev Emitted when pToken is initialized
  event Initialized(uint256 price, uint256 supply);

  /// @dev Emitted when pTokens are purchased
  event Purchased(address buyer, uint256 cost, uint256 amount);

  /// @dev Emitted when pTokens are redeemed
  event Redeemed(address seller, uint256 amount);

  /// @dev Emitted when pToken price is changed
  event PriceUpdated(address owner, uint256 newPrice);

  /**
   * @dev Modifier that implements transfer restrictions
   */
  modifier restricted(address _from, address _to) {
    // This contract can send tokens to anyone. If the sender is anyone except this contract, the
    // only allowed recipient is this contract
    bool isToOrFromContract = _from == address(this) || _to == address(this);
    require(isToOrFromContract, "PToken: Invalid recipient");
    _;
  }

  /**
   * @notice Replaces contructor since pTokens are deployed as minimal proxies
   * @param _name Token name
   * @param _symbol Token symbol
   * @param _price Price per token, denominated in _acceptedERC20 units
   * @param _initialSupply Initial token supply
   * @param _acceptedERC20 Address of token used to purchase these tokens
   */
  function initializePtoken(
    string memory _name,
    string memory _symbol,
    uint256 _price,
    uint256 _initialSupply,
    address _acceptedERC20
  ) external initializer {
    // Initializers
    __Ownable_init();
    __ERC20_init(_name, _symbol);

    // Set contract state
    acceptedToken = IERC20(_acceptedERC20);
    price = _price;

    // Mint initial supply to owner
    _mint(address(this), _initialSupply);
    emit Initialized(_price, _initialSupply);
  }

  /**
   * @notice Purchase pTokens from owner
   * @param _amount Amount of pTokens to purchase
   */
  function purchase(uint256 _amount) external {
    uint256 _allowance = acceptedToken.allowance(msg.sender, address(this));
    uint256 _cost = price.mul(_amount).div(10**18);
    require(_allowance >= _cost, "PToken: Not enough token allowance");

    acceptedToken.safeTransferFrom(msg.sender, owner(), _cost);
    require(this.transfer(msg.sender, _amount), "PToken: Transfer during purchase failed");
    emit Purchased(msg.sender, _cost, _amount);
  }

  /**
   * @notice Redeem pTokens
   * @param _amount Amount of pTokens to redeem
   */
  function redeem(uint256 _amount) external {
    require(transfer(address(this), _amount), "PToken: Transfer during redemption failed");
    emit Redeemed(msg.sender, _amount);
  }

  /**
   * @notice Update purchase price of pTokens
   * @param _newPrice New pToken price, denominated in _acceptedERC20 units
   */
  function updatePrice(uint256 _newPrice) external onlyOwner {
    price = _newPrice;
    emit PriceUpdated(msg.sender, _newPrice);
  }

  /**
   * @notice Allows owner to mint more pTokens to this contract
   * @param _amount Amount of pTokens to mint
   */
  function mint(uint256 _amount) external onlyOwner {
    _mint(address(this), _amount);
  }

  /**
   * @notice Allows owner to burn pTokens from this contract
   * @param _amount Amount of pTokens to burn
   */
  function burn(uint256 _amount) external onlyOwner {
    _burn(address(this), _amount);
  }

  /**
   * @notice Moves `_amount` tokens from the caller's account to the `_to` address
   * @param _to Address to send pTokens to
   * @param _amount Amount of pTokens to send
   */
  function transfer(address _to, uint256 _amount)
    public
    override
    restricted(msg.sender, _to)
    returns (bool)
  {
    return super.transfer(_to, _amount);
  }

  /**
   * @notice Moves `_amount` tokens from `_from` to `_to`, where the `_amount` is then
   * deducted from the caller's allowance.
   * @dev Only allows transfer of pTokens between this contract and purchaser
   * @param _from Address to send pTokens from
   * @param _to Address to send pTokens to
   * @param _amount Amount of pTokens to send
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) public override restricted(_from, _to) returns (bool) {
    return super.transferFrom(_from, _to, _amount);
  }
}
