// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./TransferHelper.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./AbstractErc20Adapter.sol";


abstract contract AbstractEtherAdapter is AbstractErc20Adapter {
  using TransferHelper for address;

/* ========== Metadata ========== */

  function name() external view virtual override returns (string memory) {
    return string(abi.encodePacked(
      bytes(_protocolName()),
      " ETH Adapter"
    ));
  }

/* ========== Fallback ========== */

  fallback() external payable { return; }

  receive() external payable { return; }

/* ========== Token Actions ========== */

  function deposit(uint256 amountUnderlying)
    external
    virtual
    override
    returns (uint256 amountMinted)
  {
    underlying.safeTransferFrom(msg.sender, address(this), amountUnderlying);
    _afterReceiveWETH(amountUnderlying);
    amountMinted = _mint(amountUnderlying);
    token.safeTransfer(msg.sender, amountMinted);
  }

  function depositETH() external virtual payable returns (uint256 amountMinted) {
    _afterReceiveETH(msg.value);
    amountMinted = _mint(msg.value);
    token.safeTransfer(msg.sender, amountMinted);
  }

  function withdraw(uint256 amountToken) public virtual override returns (uint256 amountReceived) {
    token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = _burn(amountToken);
    _beforeSendWETH(amountReceived);
    underlying.safeTransfer(msg.sender, amountReceived);
  }

  function withdrawAsETH(uint256 amountToken) public virtual returns (uint256 amountReceived) {
    token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = _burn(amountToken);
    _beforeSendETH(amountReceived);
    address(msg.sender).safeTransferETH(amountReceived);
  }

  function withdrawAllAsETH() public virtual returns (uint256 amountReceived) {
    return withdrawAsETH(balanceWrapped());
  }

  function withdrawUnderlying(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    amountBurned = _burnUnderlying(amountUnderlying);
    _beforeSendWETH(amountUnderlying);
    underlying.safeTransfer(msg.sender, amountUnderlying);
  }

  function withdrawUnderlyingAsETH(uint256 amountUnderlying) external virtual returns (uint256 amountBurned) {
    amountBurned = _burnUnderlying(amountUnderlying);
    _beforeSendETH(amountUnderlying);
    address(msg.sender).safeTransferETH(amountUnderlying);
  }

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external virtual override returns (uint256 amountReceived) {
    require(amountUnderlying > 0, "withdraw 0");
    uint256 amountAvailable = availableLiquidity();
    amountReceived = amountAvailable < amountUnderlying ? amountAvailable : amountUnderlying;
    _burnUnderlying(amountReceived);
    _beforeSendWETH(amountReceived);
    underlying.safeTransfer(msg.sender, amountReceived);
  }

/* ========== Internal Ether Handlers ========== */
  
  // Convert to WETH if contract takes WETH
  function _afterReceiveETH(uint256 amount) internal virtual;

  // Convert to WETH if contract takes ETH
  function _afterReceiveWETH(uint256 amount) internal virtual;

  // Convert to ETH if contract returns WETH
  function _beforeSendETH(uint256 amount) internal virtual;

  // Convert to WETH if contract returns ETH
  function _beforeSendWETH(uint256 amount) internal virtual;
}