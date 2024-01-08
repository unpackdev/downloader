// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract LollipopPool is ERC20('Lollipop Pool', 'xLPOP') {
  using SafeMath for uint256;
  IERC20 public halo;
  uint256 public constant DECIMALS = 1e18;
  uint256 public genesisTimestamp;

  // Define the Halo token contract
  constructor(IERC20 _halo) public {
    halo = _halo;
    genesisTimestamp = 0;
  }

  //TODO: add test before entering the genesis == 0, after enter  >0
  // Stake HALOs for HALOHALOs.
  // Locks Halo and mints HALOHALO
  function enter(uint256 _amount) public {
    if (genesisTimestamp == 0) {
      genesisTimestamp = now;
    }
    // Gets the amount of Halo locked in the contract
    uint256 totalHalo = halo.balanceOf(address(this));
    // Gets the amount of HALOHALO in existence
    uint256 totalShares = totalSupply();
    // If no HALOHALO exists, mint it 1:1 to the amount put in
    if (totalShares == 0 || totalHalo == 0) {
      _mint(msg.sender, _amount);
    } else {
      // Calculate and mint the amount of HALOHALO the Halo is worth. The ratio will change overtime, as HALOHALO is burned/minted and Halo deposited from LP rewards.
      uint256 haloHaloAmount = _amount.mul(totalShares).div(totalHalo);
      _mint(msg.sender, haloHaloAmount);
    }

    // Lock the Halo in the contract
    halo.transferFrom(msg.sender, address(this), _amount);
  }

  // Claim HALOs from HALOHALOs.
  // Unlocks the staked + gained Halo and burns HALOHALO
  function leave(uint256 _share) public {
    // Gets the amount of HALOHALO in existence
    uint256 totalShares = totalSupply();
    // Calculates the amount of Halo the HALOHALO is worth
    uint256 haloHaloAmount =
      _share.mul(halo.balanceOf(address(this))).div(totalShares);
    _burn(msg.sender, _share);
    halo.transfer(msg.sender, haloHaloAmount);
  }

  function getCurrentHaloHaloPrice() public view returns (uint256) {
    uint256 totalShares = totalSupply();
    require(totalShares > 0, 'No xLPOP supply');
    // convert to decimals to get answer in wei

    uint256 haloHaloPrice =
      halo.balanceOf(address(this)).mul(DECIMALS).div(totalShares);

    // ratio in wei
    return haloHaloPrice;
  }
}
