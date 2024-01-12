// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "./BentoAdapter.sol";
import "./TokenAdapter.sol";
import "./SushiLegacyAdapter.sol";
import "./TridentSwapAdapter.sol";
import "./StargateAdapter.sol";

interface ISushiXSwap {
    function cook(
        uint8[] memory actions,
        uint256[] memory values,
        bytes[] memory datas
    ) external payable;
}