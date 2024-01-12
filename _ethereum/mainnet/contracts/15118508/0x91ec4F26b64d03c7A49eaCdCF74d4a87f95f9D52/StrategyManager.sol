// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IStrategyManager.sol";
import "./StrategyManagerStorage.sol";

contract StrategyManager is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IStrategyManager,
    StrategyManagerStorage
{
    function initialize() external initializer {
        __Ownable_init();
    }

    // For UUPSUpgradeable
    function _authorizeUpgrade(address) internal view override {
        require(
            _msgSender() == owner(),
            "StrategyManager: caller is not owner"
        );
    }

    function add(address strategy) external override onlyOwner {
        require(!strategies[strategy], "SM: already added");
        strategies[strategy] = true;
        emit Added(strategy);
    }

    function remove(address strategy) external override onlyOwner {
        require(strategies[strategy], "SM: not added");
        strategies[strategy] = false;
        emit Removed(strategy);
    }

    function isValid(address c) public view override returns (bool valid) {
        return strategies[c];
    }
}
