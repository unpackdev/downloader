pragma solidity ^0.8.0;

interface ICurveSwap {
    function get_best_rate(
        address,
        address,
        uint256
    ) external view returns (address, uint256);

    function get_coin_indices(
        address,
        address,
        address
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );

    function exchange_with_best_rate(
        address,
        address,
        uint256,
        uint256,
        address
    ) external returns (uint256);
}
