// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// interfaces
interface IUniswapV3PoolState {function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);}
interface IUniswapV3PoolImmutables {function token0() external view returns (address); function token1() external view returns (address);}
interface IERC20Metadata {function decimals() external view returns (uint8);}

contract PriceOracles {

// simplified version of ownable (to save gas)
    address private _owner;
    constructor() {_owner = msg.sender;}
    modifier onlyOwner() {require(_owner == msg.sender, "Ownable: caller is not the owner"); _;}

    IUniswapV3PoolState public Pool0;
    IUniswapV3PoolState public Pool1;
    IUniswapV3PoolState public Pool2;
    IUniswapV3PoolState public Pool3;
    IUniswapV3PoolState public Pool4;
    IUniswapV3PoolImmutables internal pool0_Immutables;
    IUniswapV3PoolImmutables internal pool1_Immutables;
    IUniswapV3PoolImmutables internal pool2_Immutables;
    IUniswapV3PoolImmutables internal pool3_Immutables;
    IUniswapV3PoolImmutables internal pool4_Immutables;
    bool public Token0_Inverted = false;
    bool public Token1_Inverted = false;
    bool public Token2_Inverted = false;
    bool public Token3_Inverted = false;
    bool public Token4_Inverted = false;
    function setInversion_Token0(bool inv) external onlyOwner {Token0_Inverted = inv;}
    function setInversion_Token1(bool inv) external onlyOwner {Token1_Inverted = inv;}
    function setInversion_Token2(bool inv) external onlyOwner {Token2_Inverted = inv;}
    function setInversion_Token3(bool inv) external onlyOwner {Token3_Inverted = inv;}
    function setInversion_Token4(bool inv) external onlyOwner {Token4_Inverted = inv;}
    function setPool0(address pool) external onlyOwner {Pool0 = IUniswapV3PoolState(pool); pool0_Immutables = IUniswapV3PoolImmutables(pool);}
    function setPool1(address pool) external onlyOwner {Pool1 = IUniswapV3PoolState(pool); pool1_Immutables = IUniswapV3PoolImmutables(pool);}
    function setPool2(address pool) external onlyOwner {Pool2 = IUniswapV3PoolState(pool); pool2_Immutables = IUniswapV3PoolImmutables(pool);}
    function setPool3(address pool) external onlyOwner {Pool3 = IUniswapV3PoolState(pool); pool3_Immutables = IUniswapV3PoolImmutables(pool);}
    function setPool4(address pool) external onlyOwner {Pool4 = IUniswapV3PoolState(pool); pool4_Immutables = IUniswapV3PoolImmutables(pool);}

    function calculatePrice(uint256 sqrtPrice, uint256 decimals0, uint256 decimals1) internal pure returns(uint256) {
        uint256 price;
        uint256 decimals;
        if (decimals0 <= decimals1) {
            decimals = decimals1 - decimals0;
            if (sqrtPrice >= 3*10**38) {price = ((sqrtPrice / (10**10)) ** 2) / ((62771017353866807638357894232076664161 * (10**decimals)) / 10**18);}  // this ensures the (sqrtPrice ** 2) can't overflow, the long number is the result of 2**192 / 10**20
            else {price = (sqrtPrice ** 2) / (6277101735386680763835789423207666416102 * (10**decimals));}                                              // the long number is the result of 2**192 / 10**18
        }
        else {
            decimals = decimals0 - decimals1;
            if (sqrtPrice >= 3*10**38) {price = ((sqrtPrice / (10**10)) ** 2) / (62771017353866807638 / (10**decimals));}  // this ensures the (sqrtPrice ** 2) can't overflow, the long number is the result of 2**192 / 10**38
            else {price = (sqrtPrice ** 2) / (6277101735386680763835789423207666416102 / (10**decimals));}                 // the long number is the result of 2**192 / 10**18
        }
        return price;
    }
    function calculateInversePrice(uint256 sqrtPrice, uint256 decimals0, uint256 decimals1) internal pure returns(uint256) {
        uint256 price;
        uint256 decimals;
        if (decimals0 <= decimals1) {
            decimals = decimals1 - decimals0;
            if (sqrtPrice >= 3*10**38) {price = 62771017353866807638357894232076664161023554444640345129 / (((sqrtPrice / (10**10)) ** 2) / (10**decimals));}  // this ensures the (sqrtPrice ** 2) can't overflow, the long number is the result of 2**192 / 100
            else {price = 6277101735386680763835789423207666416102355444464034512896000000000000000000 / ((sqrtPrice ** 2) / (10**decimals));}                 // the long number is the result of 2**192 * 10**18
        }
        else {
            decimals = decimals0 - decimals1;
            if (sqrtPrice >= 3*10**38) {price = (62771017353866807638357894232076664161023554444640345129 / (10**decimals)) / ((sqrtPrice / (10**10)) ** 2);}  // this ensures the (sqrtPrice ** 2) can't overflow, the long number is the result of 2**192 / 100
            else {price = (6277101735386680763835789423207666416102355444464034512896 / (10**decimals)) / ((sqrtPrice ** 2) / 10**18);}                        // the long number is the result of 2**192
        }
        return price;
    }

    function getEQTprice() external view returns(uint256) {
        (uint256 sqrtPrice, , , , , ,) = Pool0.slot0();
        uint256 decimals0 = IERC20Metadata(pool0_Immutables.token0()).decimals();
        uint256 decimals1 = IERC20Metadata(pool0_Immutables.token1()).decimals();
        if(Token0_Inverted){return calculateInversePrice(sqrtPrice, decimals0, decimals1);}
        else {return calculatePrice(sqrtPrice, decimals0, decimals1);}
    }
    function getEQTprice_Token1() external view returns(uint256) {
        (uint256 sqrtPrice, , , , , ,) = Pool1.slot0();
        uint256 decimals0 = IERC20Metadata(pool1_Immutables.token0()).decimals();
        uint256 decimals1 = IERC20Metadata(pool1_Immutables.token1()).decimals();
        if(Token1_Inverted){return calculateInversePrice(sqrtPrice, decimals0, decimals1);}
        else {return calculatePrice(sqrtPrice, decimals0, decimals1);}
    }
    function getEQTprice_Token2() external view returns(uint256) {
        (uint256 sqrtPrice, , , , , ,) = Pool2.slot0();
        uint256 decimals0 = IERC20Metadata(pool2_Immutables.token0()).decimals();
        uint256 decimals1 = IERC20Metadata(pool2_Immutables.token1()).decimals();
        if(Token2_Inverted){return calculateInversePrice(sqrtPrice, decimals0, decimals1);}
        else {return calculatePrice(sqrtPrice, decimals0, decimals1);}
    }
    function getEQTprice_Token3() external view returns(uint256) {
        (uint256 sqrtPrice, , , , , ,) = Pool3.slot0();
        uint256 decimals0 = IERC20Metadata(pool3_Immutables.token0()).decimals();
        uint256 decimals1 = IERC20Metadata(pool3_Immutables.token1()).decimals();
        if(Token3_Inverted){return calculateInversePrice(sqrtPrice, decimals0, decimals1);}
        else {return calculatePrice(sqrtPrice, decimals0, decimals1);}
    }
    function getEQTprice_Token4() external view returns(uint256) {
        (uint256 sqrtPrice, , , , , ,) = Pool4.slot0();
        uint256 decimals0 = IERC20Metadata(pool4_Immutables.token0()).decimals();
        uint256 decimals1 = IERC20Metadata(pool4_Immutables.token1()).decimals();
        if(Token4_Inverted){return calculateInversePrice(sqrtPrice, decimals0, decimals1);}
        else {return calculatePrice(sqrtPrice, decimals0, decimals1);}
    }
}