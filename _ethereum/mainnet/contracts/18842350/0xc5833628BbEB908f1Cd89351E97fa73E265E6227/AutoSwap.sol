pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
    function WBNB() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract AutoSwap is Ownable{

    bool inSwap;
    address public ait;
    address public router;
    address public treasury;
    uint256 public swapThreshold = 5000 * 1e18;
    uint256 public constant MAX = 2**128;

    modifier inSwapFlag {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _ait, address _router, address _treasury) {
        ait = _ait;
        router = _router;
        treasury = _treasury;
        IERC20(ait).approve(router, MAX);
    }

    receive() external payable {}

    function withdrawEther() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    function changeTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setSwapThreshold(uint256 _threshold) external onlyOwner {
        swapThreshold = _threshold;
    }

    function swapToken() external inSwapFlag{
        uint256 contractTokenBalance = IERC20(ait).balanceOf(address(this));
        require(contractTokenBalance > swapThreshold, "swapThreshold");
        address[] memory path = new address[](2);
        path[0] = ait;
        path[1] = IDEXRouter(router).WETH();
        IDEXRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            treasury,
            block.timestamp
        );

    }


}