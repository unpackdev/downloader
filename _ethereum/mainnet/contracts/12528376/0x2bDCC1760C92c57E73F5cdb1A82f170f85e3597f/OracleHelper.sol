// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./KineOracleV2.sol";

contract OracleHelper {
    function getPriceScale36(address oracle, string memory symbol) public view returns(uint, string memory, uint){
        KineOracleV2 oracleInstance = KineOracleV2(oracle);
        PriceConfig.KTokenConfig memory config = oracleInstance.getKConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
        uint price = oracleInstance.getUnderlyingPrice(config.kToken);
        return (oracleInstance.mcdLastUpdatedAt(), symbol, price * config.baseUnit);
    }

    function getConfigBySymbol(address oracle, string memory symbol) public view
    returns (address, address, uint, uint, PriceConfig.PriceSource){
        KineOracleV2 oracleInstance = KineOracleV2(oracle);
        PriceConfig.KTokenConfig memory config = oracleInstance.getKConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
        return  (config.kToken, config.underlying, config.baseUnit, config.priceUnit, config.priceSource);
    }
}