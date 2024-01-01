/// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

import "./ToadStructs.sol";
import "./IMulticall.sol";
import "./IToadRouter03.sol";
import "./IAllowanceTransfer.sol";
/**
 * IToadRouter04
 * Extends the V3 router with Uniswap V3 capabilities and vETH support
 */
abstract contract IToadRouter04 is IMulticall {

    address public immutable vETH;
        
    // IToadRouter01
    string public versionRecipient = "3.0.0";


    address public immutable factory;
    address public immutable WETH;


    mapping(address => uint256) public accountNonces;
    constructor(address fac, address weth, address veth)  {
        factory = fac;
        WETH = weth;
        vETH = veth;
    }

    function useNonce(uint256 nonce, address account) external virtual;

    function exactInputWETH(ToadStructs.ExactInputParams memory params, ToadStructs.FeeStruct memory fees) external payable virtual returns (uint256 amountOut);
    function exactInputSingleWETH(ToadStructs.ExactInputSingleParams memory params, ToadStructs.FeeStruct memory fees) external payable virtual returns (uint256 amountOut);
    function exactInput(ToadStructs.ExactInputParams memory params, ToadStructs.FeeStruct memory fees, ToadStructs.GasRepayParams memory repay) external payable virtual returns (uint256 amountOut);
    function exactInputSingle(ToadStructs.ExactInputSingleParams memory params, ToadStructs.FeeStruct memory fees, ToadStructs.GasRepayParams memory repay) external payable virtual returns (uint256 amountOut);

    function unwrapVETH(address to, uint256 amount, ToadStructs.FeeStruct calldata fees) external virtual;

    function sendETHToCoinbase() external payable virtual;

    function convertVETHtoWETH(address to, uint256 amount, ToadStructs.FeeStruct calldata fees) external virtual;
    //function swapExactTokensForTokens
        /**
     * Run a permit on a token to the Permit2 contract for max uint256
     * @param holder the token owner
     * @param tok the token to permit
     * @param deadline A deadline to expire by
     * @param v v of the sig
     * @param r r of the sig
     * @param s s of the sig
     */
    function performPermit(address holder, address tok, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual;

    /**
     * Run a permit on a token to the Permit2 contract via the Dai-style permit
     * @param holder the token owner
     * @param tok the token to permit
     * @param deadline A deadline to expire by
     * @param nonce the nonce
     * @param v v of the sig
     * @param r r of the sig
     * @param s s of the sig
     */
    function performPermitDai(address holder, address tok, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual;

    /**
     * Run a Permit2 permit on a token to be spent by us
     * @param holder The tokens owner
     * @param permitSingle The struct 
     * @param signature The signature
     */
    function performPermit2Single(address holder, IAllowanceTransfer.PermitSingle memory permitSingle, bytes calldata signature) public virtual;

    /**
     * Run a batch of Permit2 permits on a token to be spent by us
     * @param holder The tokens owner
     * @param permitBatch The struct
     * @param signature The signature
     */
    function performPermit2Batch(address holder, IAllowanceTransfer.PermitBatch memory permitBatch, bytes calldata signature) public virtual;

    function swapExactTokensForTokensSupportingFeeOnTransferTokensWithWETHGas(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path1, ToadStructs.AggPath[] calldata path2, address to, uint deadline, ToadStructs.FeeStruct calldata fees, ToadStructs.DexData[] calldata dexes) public virtual returns(uint256 outputAmount);

    function swapExactTokensForWETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path, address to, uint deadline, ToadStructs.FeeStruct calldata fees, ToadStructs.DexData[] calldata dexes, bool unwrap) public virtual returns(uint256 outputAmount);

    function swapExactWETHforTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] memory path, address to, uint deadline, ToadStructs.FeeStruct calldata fees, ToadStructs.DexData[] calldata dexes) public virtual returns(uint256 outputAmount);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path, address to, uint deadline, ToadStructs.FeeStruct calldata fees, uint256 ethFee, ToadStructs.AggPath[] calldata gasPath, ToadStructs.DexData[] calldata dexes) public virtual returns(uint256 outputAmount);

    function getPriceOut(uint256 amountIn, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) public view virtual returns (uint256[] memory amounts);
    
    function getAmountsOut(uint amountIn, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) external view virtual returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) external view virtual returns (uint[] memory amounts);

    function unwrapWETH(address to, uint256 amount, ToadStructs.FeeStruct calldata fees) external virtual;


}


//swapExactTokensForTokensSupportingFeeOnTransferTokensWithWETHGas(uint256,uint256,(address,uint96)[],(address,uint96)[],address,uint256,(uint256,address,uint96),(bytes32,address)[])
