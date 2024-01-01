// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";

import "./IConfig.sol";

contract Config is Ownable, IConfig {
    address public override marketplace;

    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }
}
