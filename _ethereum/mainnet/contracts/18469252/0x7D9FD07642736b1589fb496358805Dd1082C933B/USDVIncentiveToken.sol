// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Proxied.sol";

contract USDVIncentiveToken is Proxied, ERC20Upgradeable, OwnableUpgradeable {
    function initialize(address _owner) public proxied initializer {
        __ERC20_init("USDV Incentive Token", "USDV-I");

        // initial supply 40 million
        _mint(_owner, 40_000_000 * 10 ** 6);

        // replace __Ownable_init() with the following
        _transferOwnership(_owner);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
