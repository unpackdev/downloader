// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./UniswapPoolV2.sol";

contract UniswapStakingPool is UniswapPoolV2 {
  using Address for address;

  constructor (string memory name, string memory symbol, address pair, address fees) public UniswapPoolV2(name, symbol, pair, true, fees) { }

  function earn() onlyHarvester nonReentrant override virtual external {
  }

  function _earn() internal override virtual {
    // Noop for these pools
  }

  function _unearn(uint256 amount) internal override virtual {
    // Noop for these pools
  }

  function unearn() onlyHarvester nonReentrant override virtual external {
  }

  function liquidate() onlyHarvester nonReentrant override virtual external {
  }

}
