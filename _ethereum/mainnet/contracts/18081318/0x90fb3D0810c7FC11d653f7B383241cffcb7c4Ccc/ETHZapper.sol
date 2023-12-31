// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./ICamelotRouter.sol";
import "./IPancakeRouter.sol";
import "./IBalancerVault.sol";

contract ETHZapper is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ========== CONSTANT VARIABLES ========== */

    address public constant NATIVE = address(0);
    address private constant ADDRESS_ZERO = address(0);
    address private WETH;

    uint256 public constant BALANCERV2 = 1;
    uint256 public constant CAMELOTV2 = 2;
    uint256 public constant PANCAKEV3 = 3;

    /* ============ State Variables ============ */

    mapping(address => uint256) public fromTokenToDex;
    mapping(address => bytes32) public balancerPoolIdForToken;
    address public balancerVault;
    ICamelotRouter public camelotRouter;
    IPancakeRouter public pancakeRouter;

    /* ============= Events ===================*/

    event TokenUpdatedForDex( address token, uint256 dexNumber );
    event CamelotRouteDataUpdated( address camelotRoutee, address _weth );
    event PancakeRouteDataUpdated( address camelotRoutee, address _bnb );
    event BalancerSwapDataUpdated( address _token, bytes32 poolId, address balancerVault );

    /* ============ Custom Errors ============ */

    error TokenNotSupported();
    error IsNotSmartContractAddress();
    error ExchnageNumberCanNotBeZero();
    error IsTokenAmountZero();
    error IsZeroAddressReciever();

    /* ========== Constructor ========== */

    constructor() {}

    /* ============ External Getters ============ */

    function swapExactTokensToETH(
        address tokenIn,
        uint tokenAmountIn,
        uint256 _amountOutMin,
        address amountReciever
    ) external {
        if(fromTokenToDex[tokenIn] == 0) revert TokenNotSupported();
        if(tokenAmountIn == 0) revert IsTokenAmountZero();
        if(amountReciever == ADDRESS_ZERO) revert IsZeroAddressReciever();

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenAmountIn);
    
        if (fromTokenToDex[tokenIn] == BALANCERV2) {
            _swapUsingBalancerV2(tokenIn, NATIVE, tokenAmountIn, _amountOutMin, amountReciever);
        } else if (fromTokenToDex[tokenIn] == CAMELOTV2) {
            _swapUsingCamelotV2(tokenIn, WETH, tokenAmountIn, _amountOutMin, amountReciever);
        } else if (fromTokenToDex[tokenIn] == PANCAKEV3) {
            _swapForEthUsingPancakeV2(tokenIn, WETH, tokenAmountIn, amountReciever);
        }
    }

    function swapforBnbUsingPancakeV2 (
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 _amountOutMin,
        address receiver
    ) external {
        if(tokenAmountIn == 0) revert IsTokenAmountZero();
        if(receiver == ADDRESS_ZERO) revert IsZeroAddressReciever();

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = WETH;

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenAmountIn);

        IERC20(tokenIn).safeApprove(address(pancakeRouter), tokenAmountIn);
        pancakeRouter.swapExactTokensForETH(
            tokenAmountIn,
            _amountOutMin,
            path,
            receiver,
            block.timestamp + 1000
        );
    
    }

    /* ============ External Functions ============ */

    /* ============ Internal Functions ============ */

    function _swapUsingBalancerV2(
        address tokenIn,
        address tokenOut,
        uint tokenAmountIn,
        uint256 _amountOutMin,
        address amountReciever
    ) internal {
        uint256 maxEpochTime = type(uint256).max;
        IERC20(tokenIn).safeApprove(balancerVault, tokenAmountIn);
        IBalancerVault(balancerVault).swap(
            IBalancerVault.SingleSwap(
                balancerPoolIdForToken[tokenIn],
                IBalancerVault.SwapKind.GIVEN_IN,
                IAsset(tokenIn),
                IAsset(tokenOut),
                tokenAmountIn,
                hex""
            ),
            IBalancerVault.FundManagement(
                address(this),
                false,
                payable(amountReciever),
                false
            ),
            _amountOutMin,
            maxEpochTime
        );
    }

    function _swapUsingCamelotV2(
        address tokenIn,
        address tokenOut,
        uint tokenAmountIn,
        uint256 _amountOutMin,
        address amountReciever
    ) internal {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        IERC20(tokenIn).safeApprove(address(camelotRouter), tokenAmountIn);
        camelotRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmountIn,
            _amountOutMin,
            path,
            amountReciever,
            ADDRESS_ZERO,
            block.timestamp + 1000
        );
    }
    
    function _swapForEthUsingPancakeV2(
        address tokenIn,
        address tokenOut,
        uint tokenAmountIn,
        address amountReciever
    ) internal {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint[] memory amounts = pancakeRouter.getAmountsOut(
            tokenAmountIn, path
        );

        IERC20(tokenIn).safeApprove(address(pancakeRouter), tokenAmountIn);
        
        pancakeRouter.swapTokensForExactETH(
            amounts[1],
            type(uint256).max,
            path,
            amountReciever,
            block.timestamp + 1000
        );
    }

    /* ============ Admin Functions ============ */

    function setTokenToDex(
        address _Token,
        uint256 _exchangeNo
    ) external onlyOwner {
        if(_exchangeNo == 0) revert ExchnageNumberCanNotBeZero();

        fromTokenToDex[_Token] = _exchangeNo;

        emit TokenUpdatedForDex( _Token, _exchangeNo );
    }

    function setTokenForETHSwapDataOnBalancerV2(
        address _token,
        bytes32 _poolId,
        address _balancervault
    ) external onlyOwner {
        if(! Address.isContract(_balancervault)) revert IsNotSmartContractAddress();

        balancerPoolIdForToken[_token] = _poolId;
        balancerVault = _balancervault;

        emit BalancerSwapDataUpdated( _token, _poolId, balancerVault );
    }

    function setCamelotRouterV2Data(address _camelotrouter, address _weth) external onlyOwner {
        if(!  Address.isContract(_camelotrouter) || ! Address.isContract(_weth)) revert IsNotSmartContractAddress();

        camelotRouter = ICamelotRouter(_camelotrouter);
        WETH = _weth;

        emit CamelotRouteDataUpdated( address(camelotRouter), WETH );
    }

    function setPancakeRouterV2Data(address _pancakerouter, address _weth) external onlyOwner {
        if(! Address.isContract(_pancakerouter) || ! Address.isContract(_weth) ) revert IsNotSmartContractAddress();

        pancakeRouter = IPancakeRouter(_pancakerouter);
        WETH = _weth;    

        emit PancakeRouteDataUpdated( address(pancakeRouter), WETH );
    }
}

