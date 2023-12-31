pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ISwapRouter.sol";
import "./TransferHelper.sol";
import "./IUniswapV3PoolActions.sol";
import "./IWeth.sol";
import "./IMntBridge.sol";
import "./console.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract MantleBridge is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public constant UNISWAP_V3_MNT_WETH_POOL =
        0xF4c5e0F4590b6679B3030d29A84857F226087FeF;
    address public constant UNISWAP_V3_POSITION_NFT =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant UNISWAP_V3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant MNT_L1 = 0x3c3a81e81dc49A522A592e7622A7E711c06bf354;
    address public constant MNT_L2 = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;
    address public constant MNT_BRIDGE =
        0x95fC37A27a2f68e3A647CDc081F0A89bb47c3012;

    uint24 public constant FEE = 3000;
    uint32 public constant L2_GAS = 200_000;

    uint256[50] private _gap;

    function initialize() public initializer {
        __Ownable_init();
    }

    function _contractTokenBalance(address token) private returns (uint256) {
        return IWeth(token).balanceOf(address(this));
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) private {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        ISwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(params);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    receive() external payable {
        IWeth(WETH).deposit{value: msg.value}();
        IWeth(WETH).approve(UNISWAP_V3_ROUTER, _contractTokenBalance(WETH));

        _swap(WETH, MNT_L1, _contractTokenBalance(WETH));

        IERC20(MNT_L1).approve(MNT_BRIDGE, _contractTokenBalance(MNT_L1));

        IMntBridge(MNT_BRIDGE).depositERC20To(
            MNT_L1,
            MNT_L2,
            msg.sender,
            _contractTokenBalance(MNT_L1),
            L2_GAS,
            "0x"
        );
        if (_contractTokenBalance(WETH) > 0) {
            IWeth(WETH).transfer(msg.sender, _contractTokenBalance(WETH));
        }
    }
}
