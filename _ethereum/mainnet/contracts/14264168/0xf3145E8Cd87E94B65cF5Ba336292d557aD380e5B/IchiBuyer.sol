// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IIchiBuyer.sol";
import "./SafeUint128.sol";
import "./IVault.sol";

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IUniswapV3Pool.sol";
import "./OracleLibrary.sol";
import "./TransferHelper.sol";
import "./ISwapRouter.sol";
import "./Path.sol";

contract IchiBuyer is IIchiBuyer, Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeUint128 for uint256;
    using Path for bytes;

    uint256 private constant PRECISION = 1e18;

    address public override immutable swapRouter;
    address public override immutable oneUni;
    address public override immutable uniswapFactory;
    address public override immutable xIchi;
    address public override immutable ichi;

    address public override vault;
    uint256 public override maxSlippage = 1e16; // 1% slippage by default

    /**
     * @notice Construct a new IchiBuyer
     * @param _swapRouter Uniswap V3 swap router address
     * @param _ichiVault address of the ICHI/oneUni vault to be used by the buyer
     * @param _oneUni oneUNI address
     * @param _uniswapFactory Uniswap V3 factory address
     * @param _xIchi xICHI address
     * @param _ichi ICHI address
     */
    constructor(address _swapRouter, address _ichiVault, address _oneUni, address _uniswapFactory, address _xIchi, address _ichi) {
        swapRouter = _swapRouter;
        vault = _ichiVault;
        oneUni = _oneUni;
        uniswapFactory = _uniswapFactory;
        xIchi = _xIchi;
        ichi = _ichi;

        address token0 = IVault(_ichiVault).token0();
        address token1 = IVault(_ichiVault).token1();

        require(token0 == _ichi || token1 == _ichi, 'IchiBuyer.constructor: ichi token vault mismatch');
        require(token0 == _oneUni || token1 == _oneUni, 'IchiBuyer.constructor: oneUni token vault mismatch');
    }

    /**
     * @notice Swap the amount of the ERC20 token for another ERC20 on Uniswap V3 as long as Maximum_Slippage isn’t exceeded
     * @param route uniswap route to follow for the swap
     * @return amountReceived - amount received and transfered to the vault
     */
    function trade(bytes calldata route) external onlyOwner returns(uint256 amountReceived) {

        (address token0, , ) = route.decodeFirstPool();

        uint256 amountSend = IERC20(token0).balanceOf(address(this));
        ( address token1, uint256 withoutSlippage ) = spotForRoute(amountSend, route);
        uint256 allowSlippage = withoutSlippage.mul(maxSlippage).div(PRECISION);
        uint256 minAmountOut = withoutSlippage.sub(allowSlippage);

        TransferHelper.safeApprove(token0, swapRouter, amountSend);

        ISwapRouter.ExactInputParams memory params = 
            ISwapRouter.ExactInputParams({                
                path: route,
                recipient: address(this),
                deadline: block.timestamp, 
                amountIn: amountSend,
                amountOutMinimum: minAmountOut
            });
      
        amountReceived = ISwapRouter(swapRouter).exactInput(params);
        emit Trade(msg.sender, token0, amountSend, token1, amountReceived);
    }

    /**
     * @notice Transfer available ICHI to xIchi contract for xIchi tokens
     */
    function transferIchi() public override onlyOwner {
        uint256 balanceIchi = IERC20(ichi).balanceOf(address(this));

        bool success = IERC20(ichi).transfer(
            xIchi, 
            balanceIchi
        );
        require(success, 'IchiBuyer.transferIchi: xIchiContract rejected transfer');

        emit TransferIchi(msg.sender, balanceIchi);
    }

    /**
     * @notice Redeem liquidity from IchiVault, transfer available ICHI to xIchi contract for xIchi tokens, open vault position with any surplus oneUni
     * @dev Be sure to recover from over-limit in IchiVault
     */
    function resetVaultPosition() external override onlyOwner {

        /*
        1. Redeem any available ICHI-oneUNI ICHI vault ERC20 tokens to receive back ICHI and/or oneUNI.
        */

        bool ichiIsToken0;

        uint256 shares = IVault(vault).balanceOf(address(this));
        if (shares > 0) {
            IVault(vault).withdraw(
                shares, 
                address(this)
            );
        }

        address token0Addr = IVault(vault).token0();

        if(token0Addr == ichi) {
            ichiIsToken0 = true;
        }

        /*
        2. Send all available ICHI balance to the xICHI contract
        */

        transferIchi();

        /*
        3. Deposit any available oneUNI back into the ICHI-oneUNI Vault
        */

        uint256 balanceOneUni = IERC20(oneUni).balanceOf(address(this));

        if(balanceOneUni > 0) {
            IERC20(oneUni).safeApprove(vault, balanceOneUni);
            if(ichiIsToken0) {
                shares = IVault(vault).deposit(0, balanceOneUni, address(this));
                require(shares > 0, 'ichiBuyer.resetVaultPosition: did not receive vault shares');
            } else {
                shares = IVault(vault).deposit(balanceOneUni, 0, address(this));
                require(shares > 0, 'ichiBuyer.resetVaultPosition: did not receive vault shares');
            }
        }

        emit ResetVaultPosition(msg.sender, balanceOneUni, shares);
    }

    /**
     * @notice Redeem liquidity, swap oneUni for ICHI, send all ICHI to xICHI. 
     * @param fee uniswap fee for pool selection
     */
    function liquidate(uint24 fee) external override onlyOwner {

        /*
        1. Redeem any available ICHI-oneUNI ICHI vault ERC20 tokens to receive back ICHI and/or oneUNI.
        */

        uint256 amount0;
        uint256 amount1;
        uint256 amountIchi;
        uint256 amountOneUni;
        uint256 amountReceived;        
        uint256 amountSend;

        uint256 shares = IVault(vault).balanceOf(address(this));
        if(shares > 0) {
            (amount0, amount1) = IVault(vault).withdraw(
                shares, 
                address(this)
            );
        }

        address token0Addr = IVault(vault).token0();

        if(token0Addr == ichi) {
            amountIchi = amount0;
            amountOneUni = amount1;
        } else {
            amountIchi = amount1;
            amountOneUni = amount0;
        }

        /*
         * 2. Swap oneUni for ICHI
         */

        amountSend = IERC20(oneUni).balanceOf(address(this));

        uint256 withoutSlippage = ichiForOneUniSpot(amountSend, fee);
        uint256 allowSlippage = withoutSlippage.mul(maxSlippage).div(PRECISION);
        uint256 minAmountOut = withoutSlippage.sub(allowSlippage);  

        ISwapRouter.ExactInputSingleParams memory params = 
            ISwapRouter.ExactInputSingleParams({                
                tokenIn: oneUni,
                tokenOut: ichi,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp, 
                amountIn: amountSend,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0 
            });
      
        TransferHelper.safeApprove(oneUni, swapRouter, amountSend);
        amountReceived = ISwapRouter(swapRouter).exactInputSingle(params);

        /*
        3. Send all available ICHI balance to the xICHI contract
        */

        uint256 balanceIchi = IERC20(ichi).balanceOf(address(this));

        bool success = IERC20(ichi).transfer(
            xIchi, 
            balanceIchi
        );
        require(success, 'IchiBuyer.transferIchi: xIchiContract rejected transfer');

        emit Liquidate(msg.sender, amountIchi, amountOneUni, amountReceived, amountSend, balanceIchi);
    }


    /**
     * @notice determine the amountOut to receive for amountIn of tokens, at spot
     * @param amountIn tokens to swap
     * @param route uniswap route to follow
     * @return token to be received
     * @return amountOut to be received for the amount of tokens
     */
    function spotForRoute(uint256 amountIn, bytes calldata route) public override view returns(address token, uint256 amountOut) {
        require(amountIn > 0, 'IchiBuyer.spotForRoute: amountIn must be > 0');

        bytes memory path = route;

        while (true) {
            bool hasMultiplePools = path.hasMultiplePools();

            (address tokenIn, address tokenOut, uint24 fee) = path.decodeFirstPool();
            address pool = PoolAddress.computeAddress(uniswapFactory, PoolAddress.getPoolKey(tokenIn, tokenOut, fee));
            int24 tick = _getTick(pool);
            amountIn = _fetchSpot(tokenIn, tokenOut, tick, amountIn);

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                amountOut = amountIn;
                token = tokenOut;
                break;
            }
        }
    }    

    /**
     * @notice determine the ICHI to receive for amount of oneUni, at spot
     * @param amount tokens to swap
     * @param fee uniswap fee helps determine pool to use
     * @return ichiAmount to be received for the amount of oneUni
     */
    function ichiForOneUniSpot(uint256 amount, uint24 fee) public override view returns(uint256 ichiAmount) {
        address pool = PoolAddress.computeAddress(uniswapFactory, PoolAddress.getPoolKey(ichi, oneUni, fee));
        int24 tick = _getTick(pool);
        ichiAmount = _fetchSpot(oneUni, ichi, tick, amount); 
    }    

    /**
     * @notice checks whether the pool is unlocked and returns the current tick
     * @param pool the pool address
     * @return tick from slot0
     */
    function _getTick(address pool) internal view returns (int24 tick) {
        IUniswapV3Pool oracle = IUniswapV3Pool(pool);
        (, int24 tick_, , , , , bool unlocked_) = oracle.slot0();
        require(unlocked_, "UniswapV3OracleSimple: the pool is locked");
        tick = tick_;
    }

    /**
     * @notice returns equivalent _tokenOut for _amountIn, _tokenIn using spot price
     * @param _tokenIn token the input amount is in
     * @param _tokenOut token for the output amount
     * @param _tick tick for the spot price
     * @param _amountIn amount in _tokenIn
     * @return amountOut - equivalent amount in _tokenOut
     */
    function _fetchSpot(
        address _tokenIn,
        address _tokenOut,
        int24 _tick,
        uint256 _amountIn
    ) internal pure returns (uint256 amountOut) { 
        return OracleLibrary.getQuoteAtTick(
            _tick,
            _amountIn.toUint128(),
            _tokenIn,
            _tokenOut
        );
    }

    /**
     * @notice set the oneUni IchiVault address
     * @param oneUniIchiVault address of the oneUni IchiVault
     */
    function setVault(address oneUniIchiVault) external override onlyOwner {
        require(oneUniIchiVault != address(0), 'IchiBuyer.setVault : Ichi:OneUni hypervisor cannot be address(0)');
        vault = oneUniIchiVault;
        emit SetVault(msg.sender, oneUniIchiVault);
    }

    /**
     * @notice set maxSlippage
     * @param maxSlippage_ new maxSlippage, precision 18, 1e18 = 100%
     */
    function setMaxSlippage(uint256 maxSlippage_) external override onlyOwner {
        require(maxSlippage_ <= PRECISION, 'IchiBuyer.setMaxSlippage : out of range');
        maxSlippage = maxSlippage_;
        emit SetMaxSlippage(msg.sender, maxSlippage_);
    }
}
