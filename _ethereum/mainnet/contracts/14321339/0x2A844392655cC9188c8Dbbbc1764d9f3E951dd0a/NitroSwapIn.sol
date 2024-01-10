// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.4;

import "./ReentrancyGuard.sol";
import "./NitroVault.sol";

contract NitroSwapIn is ReentrancyGuard {
  uint256 public chainId;
  address public token;
  NitroVault public vault;

  constructor(address _token, NitroVault _vault) {
    chainId = block.chainid;
    token = _token;
    vault = _vault;
  }

  uint256 public txNonce;

  event SwappedIn(
    address account,
    uint256 amount,
    uint256 chainId,
    uint256 nonce,
    address token
  );

  function deposit(uint256 _amount) external nonReentrant {
    require(_amount > 0, "NitroSwap:: deposit:: Invalid _amount");
    txNonce = txNonce + 1;
    TransferHelper.safeTransferFrom(token, msg.sender, address(vault), _amount);
    emit SwappedIn(msg.sender, _amount, chainId, txNonce, token);
  }
}