// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
NodeLiquidETH v1.0

Ethereum Staking Pool contract using SSV Network technology.

https://github.com/01node/staking-pool-contracts

Copyright (c) 2023 Alexandru Ovidiu Miclea

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./Math.sol";

/// @custom:security-contact security@ovmi.sh
contract NodeLiquidETH is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using Math for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public sharePrice;
    uint256 public constant DECIMALS_OFFSET = 1;

    event LogUpdatedSharePrice(uint256 sharePrice);

    error AmountTooLow();
    error AmountTooBig();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("Node Staking Liquid ETH", "nodeLETH");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        sharePrice = 1e18;
    }

    function getSharePrice() public view returns (uint256) {
        return sharePrice;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(uint256 amount) public override onlyRole(MINTER_ROLE) {
        super.burn(amount);
    }

    function burnFrom(
        address _from,
        uint256 amount
    ) public override onlyRole(MINTER_ROLE) {
        super.burnFrom(_from, amount);
    }

    function assetsToShares(uint256 assets) public view returns (uint256) {
        return assets.mulDiv(1e18, sharePrice, Math.Rounding.Down);
    }

    function sharesToAssets(uint256 shares) public view returns (uint256) {
        return shares.mulDiv(sharePrice, 1e18, Math.Rounding.Down);
    }

    function updateSharePrice(
        uint256 totalAssets
    ) public onlyRole(MINTER_ROLE) {
        sharePrice = (totalAssets + DECIMALS_OFFSET).mulDiv(
            1e18,
            totalSupply(),
            Math.Rounding.Down
        );

        emit LogUpdatedSharePrice(sharePrice);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 assets
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, assets);
    }
}
