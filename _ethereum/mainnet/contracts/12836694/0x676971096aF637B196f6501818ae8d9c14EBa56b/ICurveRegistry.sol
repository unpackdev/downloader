// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ICurveRegistry {
    // https://curve.readthedocs.io/registry-registry.html

    function pool_count() external view returns(uint256);
    function pool_list(uint256 i) external view returns(uint256);
    function get_pool_from_lp_token(address lpToken) external view returns(address);
    function get_lp_token(address poolAddress) external view returns(address);
    function find_pool_for_coins(address _from, address _to, uint256 i) external view returns(address);
    function get_n_coins(address poolAddress) external view returns(uint256[2] memory);
    // Get a list of the swappable coins within a pool.
    function get_coins(address poolAddress) external view returns(address[8] memory);

    // Get a list of the swappable underlying coins within a pool.
    // For pools that do not involve lending, the return value is identical to Registry.get_coins.
    function get_underlying_coins(address poolAddress) external view returns(address[8] memory);

    // 
    function get_decimals(address poolAddress) external view returns(uint256[8] memory);
    function get_underlying_decimals(address poolAddress) external view returns(uint256[8] memory);

    // Returns the index of _from, index of _to, and a boolean indicating if the coins are considered underlying in the given pool.
    function get_coin_indices(address poolAddress, address _from, address _to) external view returns(int128, int128, bool);


}