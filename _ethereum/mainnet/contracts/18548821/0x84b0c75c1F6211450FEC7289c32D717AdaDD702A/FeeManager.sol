// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./TornadoInstance.sol";

interface IFeeManager {
    function instanceFeeWithUpdate(
        ITornadoInstance _instance
    ) external returns (uint160);
}
