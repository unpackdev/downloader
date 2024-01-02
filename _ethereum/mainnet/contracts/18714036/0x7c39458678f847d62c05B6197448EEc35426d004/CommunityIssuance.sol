// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./ICommunityIssuance.sol";

contract CommunityIssuance is OwnableUpgradeable, ICommunityIssuance {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize() public initializer {
        __Ownable_init();
    }

    function issue() external override returns (uint256) {
        return 0;
    }

    function trigger(address _account, uint256 _amount) external override {
        return;
    }
}
