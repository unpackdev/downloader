// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./ERC20FarmingPool.sol";

contract MistFarmingPool is ERC20FarmingPool {
    constructor()
        ERC20FarmingPool(
            address(0xC701E3D2DcCf4115D87a92f2a6E0eeEF2f0D0F25), // owner
            address(0x7Fd4d7737597E7b4ee22AcbF8D94362343ae0a79), //MIST token
            address(0x476908D9f75687684CE3DBF6990e722129cDbCc6) //WBTC token
        )
    {}

    function name() public pure override returns (string memory) {
        return "WMST-WBTC Farming Pool";
    }

    function symbol() public pure override returns (string memory) {
        return "WMST-WBTC";
    }

    function decimals() public pure override returns (uint8) {
        return 2;
    }
}
