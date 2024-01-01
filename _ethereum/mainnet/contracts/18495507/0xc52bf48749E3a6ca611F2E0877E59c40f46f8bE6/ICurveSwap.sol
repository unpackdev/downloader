// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Interface for the CurveSwap contract
interface ICurveSwap {
    /// @notice Retrieves the fee applied by the CurveSwap contract
    /// @return The fee amount
    function fee() external view returns (uint256);

    /// @notice Retrieves the balance of a token at a specific index within the CurveSwap contract
    /// @param index The index of the token
    /// @return The balance of the token
    function balances(uint256 index) external view returns (uint256);

    /// @notice Retrieves the total supply of LP (Liquidity Provider) tokens in the CurveSwap contract
    /// @return The total supply of LP tokens
    function totalSupply() external view returns (uint256);

    /// @notice Retrieves the admin fee applied by the CurveSwap contract
    /// @return The admin fee amount
    function admin_fee() external view returns (uint256);

    /// @notice Calculates the amount of LP tokens to mint or burn for a given token input or output amounts
    /// @param amounts The token input or output amounts
    /// @param is_deposit Boolean indicating if it's a deposit or withdrawal operation
    /// @return The calculated amount of LP tokens
    function calc_token_amount(
        uint256[2] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    /// @notice Calculates the amount of LP tokens to mint or burn for a given token input or output amounts
    /// @param amounts The token input or output amounts
    /// @param is_deposit Boolean indicating if it's a deposit or withdrawal operation
    /// @return The calculated amount of LP tokens
    function calc_token_amount(
        uint256[3] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    /// @notice Removes liquidity from the CurveSwap contract
    /// @param _burn_amount The amount of LP tokens to burn
    /// @param _min_amounts The minimum acceptable token amounts to receive
    /// @return The actual amounts received after removing liquidity
    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] memory _min_amounts
    ) external returns (uint256[2] memory);

    /// @notice Removes liquidity from the CurveSwap contract for a single token
    /// @param token_amount The amount of the token to remove
    /// @param i The index of the token in the pool
    /// @param min_amount The minimum acceptable token amount to receive
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;

    /// @notice Removes liquidity from the CurveSwap contract for a single token
    /// @param token_amount The amount of the token to remove
    /// @param i The index of the token in the pool
    /// @param min_amount The minimum acceptable token amount to receive
    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    /// @notice Calculates the amount of tokens to receive when withdrawing a single token from the CurveSwap contract
    /// @param tokenAmount The LP amount to withdraw
    /// @param i The index of the token in the pool
    /// @return The calculated amount of tokens to receive
    function calc_withdraw_one_coin(uint256 tokenAmount, int128 i) external view returns (uint256);

    /// @notice Calculates the amount of tokens to receive when withdrawing a single token from the CurveSwap contract
    /// @param tokenAmount The LP amount to withdraw
    /// @param i The index of the token in the pool
    /// @return The calculated amount of tokens to receive
    function calc_withdraw_one_coin(uint256 tokenAmount, uint256 i) external view returns (uint256);

    /// @notice Retrieves the address of a token in the CurveSwap pool by its index
    /// @param arg0 The index of the token in the pool
    /// @return The address of the token
    function coins(uint256 arg0) external view returns (address);

    /// @notice Retrieves the virtual price of the CurveSwap pool
    /// @return The virtual price
    function get_virtual_price() external view returns (uint256);

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract with an option to use underlying tokens
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    /// @param _use_underlying Boolean indicating whether to use underlying tokens
    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[2] memory amounts,
        uint256 min_mint_amount
    ) external;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract with an option to use underlying tokens
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    /// @param _use_underlying Boolean indicating whether to use underlying tokens
    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[5] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[6] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[6] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Exchanges tokens on the CurveSwap contract
    /// @param i The index of the input token in the pool
    /// @param j The index of the output token in the pool
    /// @param dx The amount of the input token to exchange
    /// @param min_dy The minimum acceptable amount of the output token to receive
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
}
