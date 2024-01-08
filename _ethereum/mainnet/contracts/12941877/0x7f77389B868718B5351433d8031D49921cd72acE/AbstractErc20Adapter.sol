// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./TransferHelper.sol";
import "./SymbolHelper.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";


abstract contract AbstractErc20Adapter {
  using SymbolHelper for address;
  using TransferHelper for address;

/* ========== Storage ========== */

  address public underlying;
  address public token;

/* ========== Initializer ========== */

  function initialize(address _underlying, address _token) public virtual {
    require(underlying == address(0) && token == address(0), "initialized");
    require(_underlying != address(0) && _token != address(0), "bad address");
    underlying = _underlying;
    token = _token;
    _approve();
  }

/* ========== Internal Queries ========== */

  function _protocolName() internal view virtual returns (string memory);

/* ========== Metadata ========== */

  function name() external view virtual returns (string memory) {
    return string(abi.encodePacked(
      bytes(_protocolName()),
      " ",
      bytes(underlying.getSymbol()),
      " Adapter"
    ));
  }

  function availableLiquidity() public view virtual returns (uint256);

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) external view virtual returns (uint256);

  function toWrappedAmount(uint256 underlyingAmount) external view virtual returns (uint256);

/* ========== Performance Queries ========== */

  function getAPR() public view virtual returns (uint256);

  function getHypotheticalAPR(int256 _deposit) external view virtual returns (uint256);

  function getRevenueBreakdown()
    external
    view
    virtual
    returns (
      address[] memory assets,
      uint256[] memory aprs
    )
  {
    assets = new address[](1);
    aprs = new uint256[](1);
    assets[0] = underlying;
    aprs[0] = getAPR();
  }

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() public view virtual returns (uint256) {
    return IERC20(token).balanceOf(msg.sender);
  }

  function balanceUnderlying() external view virtual returns (uint256);

/* ========== Token Actions ========== */

  function deposit(uint256 amountUnderlying) external virtual returns (uint256 amountMinted) {
    require(amountUnderlying > 0, "deposit 0");
    underlying.safeTransferFrom(msg.sender, address(this), amountUnderlying);
    amountMinted = _mint(amountUnderlying);
    token.safeTransfer(msg.sender, amountMinted);
  }

  function withdraw(uint256 amountToken) public virtual returns (uint256 amountReceived) {
    require(amountToken > 0, "withdraw 0");
    token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = _burn(amountToken);
    underlying.safeTransfer(msg.sender, amountReceived);
  }

  function withdrawAll() public virtual returns (uint256 amountReceived) {
    return withdraw(balanceWrapped());
  }

  function withdrawUnderlying(uint256 amountUnderlying) external virtual returns (uint256 amountBurned) {
    require(amountUnderlying > 0, "withdraw 0");
    amountBurned = _burnUnderlying(amountUnderlying);
    underlying.safeTransfer(msg.sender, amountUnderlying);
  }

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external virtual returns (uint256 amountReceived) {
    require(amountUnderlying > 0, "withdraw 0");
    uint256 amountAvailable = availableLiquidity();
    amountReceived = amountAvailable < amountUnderlying ? amountAvailable : amountUnderlying;
    _burnUnderlying(amountReceived);
    underlying.safeTransfer(msg.sender, amountReceived);
  }

/* ========== Internal Actions ========== */

  function _approve() internal virtual;

  /**
   * @dev Deposit `amountUnderlying` into the wrapper and return the amount of wrapped tokens received.
   * Note:
   * - Called after the underlying token is transferred.
   * - Should not transfer minted token to caller.
   */
  function _mint(uint256 amountUnderlying) internal virtual returns (uint256 amountMinted);

  /**
   * @dev Burn `amountToken` of `token` and return the amount of `underlying` received.
   * Note:
   * - Called after the wrapper token is transferred.
   * - Should not transfer underlying token to caller.
   */
  function _burn(uint256 amountToken) internal virtual returns (uint256 amountReceived);

  /**
   * @dev Redeem `amountUnderlying` of the underlying token and return the amount of wrapper tokens burned.
   * Note:
   * - Should transfer the wrapper token from the caller.
   * - Should not transfer underlying token to caller.
   */
  function _burnUnderlying(uint256 amountUnderlying) internal virtual returns (uint256 amountBurned);
}