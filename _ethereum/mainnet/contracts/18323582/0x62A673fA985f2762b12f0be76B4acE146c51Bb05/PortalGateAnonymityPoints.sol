// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract PortalGateAnonymityPoints is ERC20, ERC20Burnable, Pausable, Ownable {
  address public rewardSwapContract;

  event NewRewardSwapContract(address newRewardSwapContract);

  constructor(address _rewardSwapContract) ERC20("PortalGateAnonymityPoints", "PGAP") {
    rewardSwapContract = _rewardSwapContract;
  }

  function setRewardSwapContract(address _rewardSwapContract) public onlyOwner {
    rewardSwapContract = _rewardSwapContract;
    emit NewRewardSwapContract(_rewardSwapContract);
  }

  modifier onlyRewardSwap() {
    require(msg.sender == rewardSwapContract, "Not authorized");
    _;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(address to, uint256 amount) public onlyRewardSwap {
    _mint(to, amount);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}
