// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./FixedPointMathLib.sol";


interface CERC20 {
    function underlying() external view returns (address);
}

interface IVaderOracle {
    function getVaderEthPriceAverage() external view returns (uint); //twap
    function getChainlinkPrice() external view returns (uint); //ethusd price
}

interface ERC20 {
    function balanceOf(address) external view returns (uint);
    function totalSupply() external view returns (uint);
}

contract VaderFuseOracle {
    using FixedPointMathLib for uint256;

    address public constant XVADER = address(0x665ff8fAA06986Bd6f1802fA6C1D2e7d780a7369);
    address public constant VADER = address(0x2602278EE1882889B946eb11DC0E810075650983);
    address public constant VADER_ORACLE = address(0x6A81BE7f5C868f34F109D5b5f38Ed67f3395f7B0);
    uint256 constant BASE_UNIT = 10e18;


    function _vaderPrice() internal view returns (uint) {
        return IVaderOracle(VADER_ORACLE).getVaderEthPriceAverage();
    }

    function _xvaderPrice() internal view returns (uint) {
        uint xvaderTotalSupply = ERC20(XVADER).totalSupply();
        uint xvaderVaderBalance = ERC20(VADER).balanceOf(XVADER);

        uint xvaderVaderPrice = xvaderVaderBalance.fdiv(xvaderTotalSupply, BASE_UNIT);
        return xvaderVaderPrice * IVaderOracle(VADER_ORACLE).getVaderEthPriceAverage() / BASE_UNIT;
    }

    function getUnderlyingPrice(address asset_) external view returns (uint) {

        address underlying = address(CERC20(asset_).underlying());
        if (address(XVADER) == address(underlying)) {
            return _xvaderPrice();
        } else if (address(VADER) == address(underlying)) {
            return _vaderPrice();
        } else {
            revert("Unsupported Asset");
        }
    }

    function price(address asset_) external view returns (uint) {
        if (address(XVADER) == address(asset_)) {
            return _xvaderPrice();
        } else if (address(VADER) == address(asset_)) {
            return _vaderPrice();
        } else {
            revert("Unsupported Asset");
        }
    }
}
