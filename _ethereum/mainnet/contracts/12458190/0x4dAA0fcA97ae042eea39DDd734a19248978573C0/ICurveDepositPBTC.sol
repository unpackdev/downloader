pragma solidity 0.6.6;

interface ICurveDepositPBTC {
    function add_liquidity(uint256[4] calldata call_data_amounts, uint256 min_mint_amount) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function token() external returns (address);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool is_deposit) external view returns (uint256);
}