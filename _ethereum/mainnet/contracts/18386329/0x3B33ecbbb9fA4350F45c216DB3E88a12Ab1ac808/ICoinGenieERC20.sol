// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC20.sol";

/**
 * @title ICoinGenieERC20
 * @author @neuro_0x
 * @dev Interface for the CoinGenie ERC20 token
 */
interface ICoinGenieERC20 is IERC20 {
    /////////////////////////////////////////////////////////////////
    //                           Events                            //
    /////////////////////////////////////////////////////////////////

    /// @dev Emits when Genie is set
    /// @param genie - the address of the $GENIE contract
    event GenieSet(address indexed genie);

    /// @dev Emits when trading is opened
    /// @param pair - the address of the Uniswap V2 Pair
    event TradingOpened(address indexed pair);

    /// @dev Emits when the max buy percent is set
    /// @param maxBuyPercent - the max buy percent
    event MaxBuyPercentSet(uint256 indexed maxBuyPercent);

    /// @dev Emits when the fee recipient is set
    /// @param feeRecipient - the address of the fee recipient
    event FeeRecipientSet(address indexed feeRecipient);

    /// @dev Emits when the max wallet percent is set
    /// @param maxWalletPercent - the max wallet percent
    event MaxWalletPercentSet(uint256 indexed maxWalletPercent);

    /// @dev Emits when eth is sent to the fee recipients
    /// @param feeRecipientShare - the amount of eth sent to the fee recipient as a share
    /// @param coinGenieShare - the amount of eth sent to the coin genie as a share
    event EthSentToFee(uint256 indexed feeRecipientShare, uint256 indexed coinGenieShare);

    /////////////////////////////////////////////////////////////////
    //                           Errors                            //
    /////////////////////////////////////////////////////////////////

    /// @dev Reverts when the caller is not authorized to perform an action
    error Unauthorized();

    /// @dev Reverts when trading is not open
    error TradingNotOpen();

    /// @dev Reverts when Genie is already set
    error GenieAlreadySet();

    /// @dev Reverts when trading is already open
    error TradingAlreadyOpen();

    /// @dev Reverts when trying to burn from the zero address
    error BurnFromZeroAddress();

    /// @dev Reverts when trying to approve from the zero address
    error ApproveFromZeroAddress();

    /// @dev Reverts when trying to transfer from the zero address
    error TransferFromZeroAddress();

    /// @dev Reverts when coin genie fee is already set
    error CoinGenieFeePercentAlreadySet();

    /// @dev Reverts when invalid coin genie fee percent
    error InvalidCoinGenieFeePercent();

    /// @dev Reverts when invalid total supply
    /// @param totalSupply - the total supply
    error InvalidTotalSupply(uint256 totalSupply);

    /// @dev Reverts when trying to set an invalid max wallet percent
    /// @param maxWalletPercent - the max wallet percent
    error InvalidMaxWalletPercent(uint256 maxWalletPercent);

    /// @dev Reverts when trying to set an invalid max buy percent
    /// @param maxBuyPercent - the max buy percent
    error InvalidMaxBuyPercent(uint256 maxBuyPercent);

    /// @dev Reverts when there is not enough eth send in the tx
    /// @param amount - the amount of eth sent
    /// @param minAmount - the min amount of eth required
    error InsufficientETH(uint256 amount, uint256 minAmount);

    /// @dev Reverts when the amount sent is beyond the max amount allowed
    /// @param amount - the amount sent
    /// @param maxAmount - the max amount allowed
    error ExceedsMaxAmount(uint256 amount, uint256 maxAmount);

    /// @dev Reverts when there are not enough tokens to perform the action
    /// @param amount - the amount of tokens sent
    /// @param minAmount - the min amount of tokens required
    error InsufficientTokens(uint256 amount, uint256 minAmount);

    /// @dev Reverts when there is not enough allowance to perform the action
    /// @param amount - the amount of tokens sent
    /// @param allowance - the amount of allowance required
    error InsufficientAllowance(uint256 amount, uint256 allowance);

    /// @dev Reverts when there is an error when transferring
    /// @param amount - the amount sent
    /// @param from - the address the transfer is from
    /// @param to - the address the transfer is to
    error TransferFailed(uint256 amount, address from, address to);

    /////////////////////////////////////////////////////////////////
    //                       Public/External                       //
    /////////////////////////////////////////////////////////////////

    /// @dev Gets the name of the token
    /// @return the name of the token
    function name() external view returns (string memory);

    /// @dev Gets the symbol of the token
    /// @return the symbol of the token
    function symbol() external view returns (string memory);

    /// @dev Gets the number of decimals the token uses
    /// @return the number of decimals the token uses
    function decimals() external pure returns (uint8);

    /// @dev Gets the total supply of the token
    /// @return the total supply of the token
    function totalSupply() external view returns (uint256);

    /// @dev Gets the address of the fee recipient
    /// @return the address of the fee recipient
    function feeRecipient() external view returns (address payable);

    /// @dev Gets the address of the CoinGenie contract
    /// @return the address of the CoinGenie contract
    function coinGenie() external view returns (address payable);

    /// @dev Gets the address of the $GENIE contract
    /// @return the address of the $GENIE contract
    function genie() external view returns (address payable);

    /// @dev Gets the address of the affiliate fee recipient
    /// @return the address of the affiliate fee recipient
    function affiliateFeeRecipient() external view returns (address payable);

    /// @dev Gets the trading status of the token
    /// @return the trading status of the token
    function isTradingOpen() external view returns (bool);

    /// @dev Gets the trading status of the token
    /// @return the trading status of the token
    function isSwapEnabled() external view returns (bool);

    /// @dev Gets the tax percent
    /// @return the tax percent
    function taxPercent() external view returns (uint256);

    /// @dev Gets the max buy percent
    /// @return the max buy percent
    function maxBuyPercent() external view returns (uint256);

    /// @dev Gets the max wallet percent
    /// @return the max wallet percent
    function maxWalletPercent() external view returns (uint256);

    /// @dev Gets the discount fee required amount in $GENIE
    /// @return the discount fee required amount in $GENIE
    function discountFeeRequiredAmount() external view returns (uint256);

    /// @dev Gets the discount percent received if paying in $GENIE
    /// @return the discount percent received if paying in $GENIE
    function discountPercent() external view returns (uint256);

    /// @dev Gets the Uniswap V2 pair address
    /// @return the uniswap v2 pair address
    function lpToken() external view returns (address);

    /// @dev Gets the balance of the specified address
    /// @param account - the address to get the balance of
    /// @return the balance of the account
    function balanceOf(address account) external view returns (uint256);

    /// @dev Gets the amount of eth received by the fee recipient
    /// @param feeRecipient_ - the address to get the amount of eth received
    /// @return the amount of eth received
    function amountEthReceived(address feeRecipient_) external view returns (uint256);

    /// @dev Burns `amount` tokens from the caller
    /// @param amount - the amount of tokens to burn
    function burn(uint256 amount) external;

    /// @dev Transfers `amount` tokens to `recipient`
    /// @param recipient - the address to transfer to
    /// @param amount - the amount of tokens to transfer
    /// @return true if the transfer was successful
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @dev Gets the allowance of an address to spend tokens on behalf of the owner
    /// @param owner - the address to get the allowance of
    /// @param spender - the address to get the allowance for
    /// @return the allowance of the owner for the spender
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Approves an address to spend tokens on behalf of the caller
    /// @param spender - the address to approve
    /// @param amount - the amount to approve
    /// @return true if the approval was successful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @dev Transfers tokens from one address to another
    /// @param sender - the address to transfer from
    /// @param recipient - the address to transfer to
    /// @param amount - the amount to transfer
    /// @return true if the transfer was successful
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /// @dev Swaps the contracts tokens for eth
    function manualSwap(uint256 amount) external;

    /// @dev Opens trading by adding liquidity to Uniswap V2
    /// @param amountToLP - the amount of tokens to add liquidity with
    /// @param payInGenie - true if paying with $GENIE
    /// @return the address of the LP Token created
    function createPairAndAddLiquidity(uint256 amountToLP, bool payInGenie) external payable returns (address);

    /// @dev Adds liquidity to Uniswap V2
    /// @param amountToLP - the amount of tokens to add liquidity with
    /// @param payInGenie - true if paying with $GENIE
    function addLiquidity(uint256 amountToLP, bool payInGenie) external payable;

    /// @dev Removes liquidity from Uniswap V2
    /// @param amountToRemove - the amount of LP tokens to remove
    function removeLiquidity(uint256 amountToRemove) external;

    /// @dev Sets the address of the $GENIE contract
    /// @param genie_ - the address of the $GENIE contract
    function setGenie(address genie_) external;

    /// @dev Sets the fee recipient
    /// @param feeRecipient_ - the address of the fee recipient
    function setFeeRecipient(address payable feeRecipient_) external;

    /// @dev Sets the max amount of tokens that can be bought in a tx as a percent of the total supply
    /// @param maxBuyPercent_ - the max buy percent
    function setMaxBuyPercent(uint256 maxBuyPercent_) external;

    /// @dev Sets the max amount of tokens a wallet can hold as a percent of the total supply
    /// @param maxWalletPercent_ - the max wallet percent
    function setMaxWalletPercent(uint256 maxWalletPercent_) external;

    /// @notice Sets the Coin Genie fee percentage.
    /// @param coinGenieFeePercent_ The Coin Genie fee percentage.
    function setCoinGenieFeePercent(uint256 coinGenieFeePercent_) external;
}
