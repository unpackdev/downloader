pragma solidity 0.8.0;

interface ICurveEURSDeposit {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
    external
    returns (uint256);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] calldata _min_amounts
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);
}
