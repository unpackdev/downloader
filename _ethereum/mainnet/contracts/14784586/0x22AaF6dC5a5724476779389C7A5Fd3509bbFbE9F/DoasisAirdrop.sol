// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";

import "./DoasisGenesisPass.sol";

contract DoasisAirdrop is Context, Ownable, Pausable {
  DoasisGenesisPass public doasis;
  uint256 public totalAirdrop;

  event MintBatch(address to, uint256 quantity, uint256 totalMint);

  constructor(DoasisGenesisPass _doasis) {
    doasis = _doasis;
  }

  function airdrop(address[] calldata users, uint256 quantity)
    public
    whenNotPaused
    onlyOwner
  {
    totalAirdrop += quantity * users.length;

    for (uint256 i = 0; i < users.length; i++) {
      doasis.mint(users[i], quantity);

      emit MintBatch(users[i], quantity, totalAirdrop);
    }
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}
