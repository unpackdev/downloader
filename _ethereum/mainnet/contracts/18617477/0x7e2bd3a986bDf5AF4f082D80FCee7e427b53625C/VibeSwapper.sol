pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Router.sol";
import "./IWeth.sol";
import "./IERC20.sol";
import "./IPointsDistributor.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract VibeSwapper is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    event Swapped(
        uint256 wethAmount,
        address domain,
        address maker,
        uint256 vibeAmount
    );

    address public constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant VIBE = 0x49608dC7C97f8Bc7AFB2096422d1d4adC11fA922;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant SLIPPAGE = 3;

    uint256[50] private _gap;

    address public rewardsContract;

    function initialize() public initializer {
        __Ownable_init();
    }

    function setPointsDistributorContract(
        address _rewardsContract
    ) public onlyOwner {
        rewardsContract = _rewardsContract;
    }

    function _chargeFee(uint256 amount) private returns (uint256) {
        address feeDestination = IPointsDistributor(rewardsContract)
            .feeDestination();
        uint256 shortcutComplexity = IPointsDistributor(rewardsContract)
            .shortcuts(address(this))
            .complexity;
        uint256 baseShortcutFee = IPointsDistributor(rewardsContract)
            .shortcutBaseFee();
        uint256 fee = (amount * shortcutComplexity) / baseShortcutFee;

        payable(feeDestination).transfer(fee);
        return fee;
    }

    function _contractTokenBalance(address token) private returns (uint256) {
        return IWeth(token).balanceOf(address(this));
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
        uint256 chargedFees = _chargeFee(msg.value);
        IWeth(WETH).deposit{value: msg.value - chargedFees}();
        IWeth(WETH).approve(UNISWAP_V2_ROUTER, _contractTokenBalance(WETH));

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = VIBE;

        uint256 wethAmountToSwap = _contractTokenBalance(WETH);

        uint[] memory amountsOut = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(wethAmountToSwap, path);

        uint256 amountOutMin = amountsOut[1] -
            ((amountsOut[1] * SLIPPAGE)) /
            100;

        uint256 vibeBalanceBefore = IERC20(VIBE).balanceOf(msg.sender);

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            wethAmountToSwap,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        uint256 vibeBalanceAfter = IERC20(VIBE).balanceOf(msg.sender);

        if (_contractTokenBalance(WETH) > 0) {
            IWeth(WETH).transfer(msg.sender, _contractTokenBalance(WETH));
        }
        if (IPointsDistributor(rewardsContract).isPointDistributionActive()) {
            IPointsDistributor(rewardsContract).distributePoints(msg.value);
        }
        emit Swapped(
            wethAmountToSwap,
            address(this),
            msg.sender,
            vibeBalanceAfter - vibeBalanceBefore
        );
    }
}
