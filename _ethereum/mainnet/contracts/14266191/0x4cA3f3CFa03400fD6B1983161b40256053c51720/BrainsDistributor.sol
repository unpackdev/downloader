// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.12;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./IBrains.sol";
import "./IBrainsDistributor.sol";

contract BrainsDistributor is Initializable, OwnableUpgradeable, IBrainsDistributor {

    IBrains public brains;

    event BrainsUpdated(address updated);

    function initialize() external initializer {
        __Ownable_init();
    }

    function updateBrains(address _brains) external onlyOwner {
        require(address(brains) != _brains, "brains_address_same");
        brains = IBrains(_brains);
        emit BrainsUpdated(_brains);
    }

    function burnBrainsFor(address holder, uint256 amount) external override _hasBrains(holder, amount) {
        brains.burn(holder, amount);
    }

    function mintBrainsFor(address holder, uint256 amount) external override {
        brains.mint(holder, amount);
    }

    modifier _hasBrains(address holder, uint256 amount) {
        require(brains.balanceOf(holder) >= amount, "insufficient_brains");
        _;
    }
}