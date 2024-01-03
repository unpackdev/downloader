// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TREE is ERC20("tree.finance", "TREE"), Ownable {
  /**
    @notice the TREERebaser contract
   */
  address public rebaser;
  /**
    @notice the TREEReserve contract
   */
  address public reserve;

  function initContracts(address _rebaser, address _reserve)
    external
    onlyOwner
  {
    require(_rebaser != address(0), "TREE: invalid rebaser");
    require(rebaser == address(0), "TREE: rebaser already set");
    rebaser = _rebaser;
    require(_reserve != address(0), "TREE: invalid reserve");
    require(reserve == address(0), "TREE: reserve already set");
    reserve = _reserve;
  }

  function ownerMint(address account, uint256 amount) external onlyOwner {
    _mint(account, amount);
  }

  function rebaserMint(address account, uint256 amount) external {
    require(msg.sender == rebaser);
    _mint(account, amount);
  }

  function reserveBurn(address account, uint256 amount) external {
    require(msg.sender == reserve);
    _burn(account, amount);
  }
}
