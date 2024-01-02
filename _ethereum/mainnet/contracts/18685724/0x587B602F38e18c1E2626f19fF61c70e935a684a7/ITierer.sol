// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "DataTypes.sol";

interface ITierer {
    function getTier(
        address _contract,
        bytes calldata payload
    ) external view returns (DataTypes.Tier memory);
}
