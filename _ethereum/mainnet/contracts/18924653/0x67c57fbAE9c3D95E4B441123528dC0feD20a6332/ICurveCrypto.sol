// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface ICurveCrypto {
    function coins(uint256 n) external view returns(address);
    function exchange(int128 from, int128 to, uint256 from_amount, uint256 min_to_amount) external;
}

interface ICurveCryptoV2 {
    function coins(uint256 n) external view returns(address);
    function exchange_underlying(int128 from, int128 to, uint256 from_amount, uint256 min_to_amount) external;
    
}

interface ICurveFactory {
    function find_pool_for_coins(address from, address to) external view returns(address);
    function get_underlying_coins(address pool) external view returns(address[8] memory);
    function get_underlying_decimals(address pool) external view returns(uint256[8] memory);
    function get_underlying_balances(address pool) external view returns(uint256[8] memory);
}   

