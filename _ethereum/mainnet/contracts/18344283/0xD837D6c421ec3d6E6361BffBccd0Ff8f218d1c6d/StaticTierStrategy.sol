// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "GovernanceOnly.sol";
import "DataTypes.sol";
import "ITierStrategy.sol";

contract StaticTierStrategy is ITierStrategy, GovernanceOnly {
    DataTypes.Tier public tier;

    constructor(
        address _governance,
        DataTypes.Tier memory _tier
    ) GovernanceOnly(_governance) {
        tier = _tier;
    }

    function getTier(
        bytes calldata
    ) external view returns (DataTypes.Tier memory) {
        return tier;
    }
}
