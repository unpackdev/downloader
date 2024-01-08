// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./IUniswapV3FlashCallback.sol";
import "./ICTokenSwap.sol";
import "./IERC20.sol";
import "./IUniswapV3Pool.sol";
import "./CTokenInterfaces.sol";
import "./IWETH9.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./PoolAddress.sol";
import "./CallbackValidation.sol";

/// @author Ganesh Gautham Elango
/// @title Compound collateral swap contract
/// @notice Swaps on any DEX
contract CTokenSwap is ICTokenSwap, IUniswapV3FlashCallback, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev UniswapV3Factory address
    address public immutable uniswapV3Factory;
    /// @dev WETH9 contract
    IWETH9 public immutable weth;

    /// @dev Constructor
    /// @param _uniswapV3Factory UniswapV3Factory address
    constructor(address _uniswapV3Factory, address _weth) {
        uniswapV3Factory = _uniswapV3Factory;
        weth = IWETH9(_weth);
    }

    /// @dev Fallback for reciving Ether
    receive() external payable {}

    /// @notice Performs collateral swap of 2 cTokens
    /// @dev This may put the sender at liquidation risk if they have debt
    /// @param params Collateral swap params
    /// @return Amount of cToken1 minted and received
    function collateralSwap(CollateralSwapParams calldata params) external override returns (uint256) {
        // Transfers cToken0Amount of cToken0 from msg.sender to this contract
        require(
            CTokenInterface(params.cToken0).transferFrom(msg.sender, address(this), params.cToken0Amount),
            "CTokenSwap: TransferFrom failed"
        );
        // Redeems token0Amount of token0 from cToken0 to this contract
        require(
            CErc20Interface(params.cToken0).redeemUnderlying(params.token0Amount) == 0,
            "CTokenSwap: RedeemUnderlying failed"
        );
        // If token0 is Ether
        if (params.token0 == address(0)) {
            // Swap token0Amount of Ether to token1, receiving token1Amount of token1
            uint256 token1Amount = swapFromEther(params.token0Amount, params.token1, params.exchange, params.data);
            // Approve token1Amount of token1 to be spent by cToken1
            IERC20(params.token1).safeApprove(params.cToken1, token1Amount);
            // Mint token1Amount token1 worth of cToken1 to this contract
            require(CErc20Interface(params.cToken1).mint(token1Amount) == 0, "CTokenSwap: Mint failed");
            // If token1 is Ether
        } else if (params.token1 == address(0)) {
            // Swap token0Amount of token0 to Ether, receiving token1Amount of Ether
            uint256 token1Amount = swapToEther(params.token0Amount, params.token0, params.exchange, params.data);
            // Mint token1Amount Ether worth of cToken1 to this contract
            CEtherInterface(params.cToken1).mint{ value: token1Amount }();
            // If neither token0 nor token1 is Ether
        } else {
            // Swap token0Amount of token0 to token1, receiving token1Amount of token1
            uint256 token1Amount = swap(
                params.token0Amount,
                params.token0,
                params.token1,
                params.exchange,
                params.data
            );
            // Approve token1Amount of token1 to be spent by cToken1
            IERC20(params.token1).safeApprove(params.cToken1, token1Amount);
            // Mint token1Amount token1 worth of cToken1 to this contract
            require(CErc20Interface(params.cToken1).mint(token1Amount) == 0, "CTokenSwap: Mint failed");
        }
        // Amount of cToken1 minted
        uint256 cToken1Balance = CTokenInterface(params.cToken1).balanceOf(address(this));
        // Transfer cToken1Balance of cToken1 to msg.sender
        require(CTokenInterface(params.cToken1).transfer(msg.sender, cToken1Balance), "CTokenSwap: Transfer failed");
        // Get cToken0 balance of this contract
        uint256 cToken0Balance = CTokenInterface(params.cToken0).balanceOf(address(this));
        // If cToken0Balance is greater than 0, transfer the amount back to msg.sender
        if (cToken0Balance > 0) {
            // Transfer cToken0Balance of cToken0 to msg.sender
            require(
                CTokenInterface(params.cToken0).transfer(msg.sender, cToken0Balance),
                "CTokenSwap: Transfer failed"
            );
        }
        // Emit event
        emit CollateralSwap(msg.sender, params.cToken0, params.cToken1, params.token0Amount);
        // Return cToken1Balance
        return cToken1Balance;
    }

    /// @notice Performs collateral swap of 2 cTokens using a Uniswap V3 flash loan
    /// @dev This reduces the senders liquidation risk if they have debt
    /// @param amount0 Amount of token0 in pool to flash loan (must be 0 if not being flash loaned)
    /// @param amount0 Amount of token1 in pool to flash loan (must be 0 if not being flash loaned)
    /// @param pool Uniswap V3 pool address containing token to be flash loaned
    /// @param poolKey The identifying key of the Uniswap V3 pool
    /// @param params Collateral swap params
    function collateralSwapFlash(
        uint256 amount0,
        uint256 amount1,
        address pool,
        PoolAddress.PoolKey calldata poolKey,
        CollateralSwapParams calldata params
    ) external override {
        // Encode msg.sender, poolKey and params for flash loan
        bytes memory data = abi.encode(msg.sender, poolKey, params);
        // Execute flash loan
        IUniswapV3Pool(pool).flash(address(this), amount0, amount1, data);
    }

    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        // Decode callback data
        (address sender, PoolAddress.PoolKey memory poolKey, CollateralSwapParams memory params) = abi.decode(
            data,
            (address, PoolAddress.PoolKey, CollateralSwapParams)
        );
        // Check if callback is coming from Uniswap pool
        CallbackValidation.verifyCallback(uniswapV3Factory, poolKey);
        // Flash loan fee
        uint256 fee = fee0 > 0 ? fee0 : fee1;
        // If token1 is Ether
        if (params.token1 == address(0)) {
            // Swap token0Amount of token0 to Ether, receiving token1Amount of Ether
            uint256 token1Amount = swapToEther(params.token0Amount, params.token0, params.exchange, params.data);
            // Mint token1Amount Ether worth of cToken1 to this contract
            CEtherInterface(params.cToken1).mint{ value: token1Amount }();
        } else {
            // Swap token0Amount of token0 to token1, receiving token1Amount of token1
            uint256 token1Amount = swap(
                params.token0Amount,
                params.token0,
                params.token1,
                params.exchange,
                params.data
            );
            // Approve token1Amount of token1 to be spent by cToken1
            IERC20(params.token1).safeApprove(params.cToken1, token1Amount);
            // Mint token1Amount token1 worth of cToken1 to this contract
            require(CErc20Interface(params.cToken1).mint(token1Amount) == 0, "CTokenSwap: Mint failed");
        }
        // Amount of cToken1 minted
        uint256 cToken1Balance = CTokenInterface(params.cToken1).balanceOf(address(this));
        // Transfer cToken1Balance of cToken1 to sender
        require(CTokenInterface(params.cToken1).transfer(sender, cToken1Balance), "CTokenSwap: Transfer failed");
        // Transfers cToken0Amount of cToken0 from sender to this contract
        require(
            CTokenInterface(params.cToken0).transferFrom(sender, address(this), params.cToken0Amount),
            "CTokenSwap: TransferFrom failed"
        );
        // Amount of token0 to pay back flash loan
        uint256 token0Amount = params.token0Amount.add(fee);
        // Redeems token0Amount of token0 from cToken0 to this contract
        require(
            CErc20Interface(params.cToken0).redeemUnderlying(token0Amount) == 0,
            "CTokenSwap: RedeemUnderlying failed"
        );
        // If token0 is Ether
        if (params.token0 == address(weth)) {
            // Wrap Ether into WETH
            weth.deposit{ value: token0Amount }();
        }
        // Transfer token0Amount to pool to pay back flash loan
        IERC20(params.token0).safeTransfer(msg.sender, token0Amount);
        // Get cToken0 balance of this contract
        uint256 cToken0Balance = CTokenInterface(params.cToken0).balanceOf(address(this));
        // If cToken0Balance is greater than 0, transfer the amount back to sender
        if (cToken0Balance > 0) {
            // Transfer cToken0Balance of cToken0 to sender
            require(CTokenInterface(params.cToken0).transfer(sender, cToken0Balance), "CTokenSwap: Transfer failed");
        }
        // Emit event
        emit CollateralSwap(sender, params.cToken0, params.cToken1, params.token0Amount);
    }

    /// @notice Transfer a tokens balance left on this contract to the owner
    /// @dev Can only be called by owner
    /// @param token Address of token to transfer the balance of
    function transferToken(address token) external override onlyOwner {
        if (token == address(0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    /// @dev Swap token for token
    /// @param amount Amount of token0 to swap
    /// @param token0 Token to swap from
    /// @param token1 Token to swap to
    /// @param exchange Exchange address to swap on
    /// @param data Calldata to call exchange with
    /// @return token1 received from swap
    function swap(
        uint256 amount,
        address token0,
        address token1,
        address exchange,
        bytes memory data
    ) internal returns (uint256) {
        IERC20(token0).safeApprove(exchange, amount);
        (bool success, ) = exchange.call(data);
        require(success, "CTokenSwap: Swap failed");
        return IERC20(token1).balanceOf(address(this));
    }

    /// @dev Swap ether for token
    /// @param amount Amount of ether to swap
    /// @param token1 Token to swap to
    /// @param exchange Exchange address to swap on
    /// @param data Calldata to call exchange with
    /// @return token1 received from swap
    function swapFromEther(
        uint256 amount,
        address token1,
        address exchange,
        bytes memory data
    ) internal returns (uint256) {
        (bool success, ) = exchange.call{ value: amount }(data);
        require(success, "CTokenSwap: Swap failed");
        return IERC20(token1).balanceOf(address(this));
    }

    /// @dev Swap token for ether
    /// @param amount Amount of token0 to swap
    /// @param token0 Token to swap from
    /// @param exchange Exchange address to swap on
    /// @param data Calldata to call exchange with
    /// @return ether received from swap
    function swapToEther(
        uint256 amount,
        address token0,
        address exchange,
        bytes memory data
    ) internal returns (uint256) {
        IERC20(token0).safeApprove(exchange, amount);
        (bool success, ) = exchange.call(data);
        require(success, "CTokenSwap: Swap failed");
        return address(this).balance;
    }
}
