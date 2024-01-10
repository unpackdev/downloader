// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./LUTsLoader.sol";

abstract contract LUTs {
    uint256[] internal _supplyLUT;

    uint256[] internal _priceLUT;

    uint256 internal _nodeId;

    function initSupplyLUT0() external {
        LUTsLoader.fillSupplyNodes0(_supplyLUT);
    }

    function initSupplyLUT1() external {
        LUTsLoader.fillSupplyNodes1(_supplyLUT);
    }

    function initSupplyLUT2() external {
        LUTsLoader.fillSupplyNodes2(_supplyLUT);
    }

    function initSupplyLUT3() external {
        LUTsLoader.fillSupplyNodes3(_supplyLUT);
    }

    function initPriceLUT0() external {
        LUTsLoader.fillPriceNodes0(_priceLUT);
    }

    function initPriceLUT1() external {
        LUTsLoader.fillPriceNodes1(_priceLUT);
    }

    function initPriceLUT2() external {
        LUTsLoader.fillPriceNodes2(_priceLUT);
    }

    function initPriceLUT3() external {
        LUTsLoader.fillPriceNodes3(_priceLUT);
    }

    uint256[47] private __gap;
}
