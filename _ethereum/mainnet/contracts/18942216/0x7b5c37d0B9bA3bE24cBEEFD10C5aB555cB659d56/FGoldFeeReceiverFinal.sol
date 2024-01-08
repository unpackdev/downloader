// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Address.sol";
import "./Ownable.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;  

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);  

    function WETH() external pure returns (address);
}

contract fgFeeDistributor is Ownable(msg.sender) {
    using Address for address payable;

    address public fgMarketingWallet = _msgSender();
    address public fgDevWallet = _msgSender();
    IUniswapV2Router02 private router;
    IERC20 public fgold;

    struct Distribution {
        uint8 marketing;
        uint8 lp;
        uint8 dev;
    }

    Distribution public distribution = Distribution(3, 0, 0);

    bool private _liquidityMutex;
    modifier mutexLock() {
        require(!_liquidityMutex, "Function locked");
        _liquidityMutex = true;
        _;
        _liquidityMutex = false;
    }

    constructor(address fgoldAddress) {
        fgold = IERC20(fgoldAddress);
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        Ownable(_msgSender());
    }

    function distributeFees(uint256 fgoldAmount) external onlyOwner mutexLock {
        require(fgoldAmount > 0, "Token amount must be greater than 0");
        require(fgold.balanceOf(address(this)) > fgoldAmount, "Insufficient Balance");

        uint256 distributionTotal = distribution.lp + distribution.marketing + distribution.dev;
        uint256 denominator = distributionTotal * 2;
        uint256 tokensToAddLiquidityWith = (fgoldAmount * distribution.lp) / denominator;
        uint256 toSwap = fgoldAmount - tokensToAddLiquidityWith;
        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance = deltaBalance / (denominator - distribution.lp);
        uint256 ethToAddLiquidityWith = unitBalance * distribution.lp;

        if (ethToAddLiquidityWith > 0) {
            addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
        }

        uint256 marketingAmt = unitBalance * 2 * distribution.marketing;
        if (marketingAmt > 0) {
            payable(fgMarketingWallet).sendValue(marketingAmt);
        }

        uint256 devAmt = unitBalance * 2 * distribution.dev;
        if (devAmt > 0) {
            payable(fgDevWallet).sendValue(devAmt);
        } 
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        router.addLiquidityETH { value: ethAmount } (address(fgold), tokenAmount, 0, 0, _msgSender(), block.timestamp + 600);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(fgold);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp + 600);
    }

    function updateMarketingWallet(address newWallet) external onlyOwner {
        fgMarketingWallet = newWallet;
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        fgDevWallet = newWallet;
    }

    function updateDistribution(uint8 marketing, uint8 liquidity, uint8 dev) external onlyOwner {
        distribution.marketing = marketing;
        distribution.lp = liquidity;
        distribution.dev = dev;

        uint256 distributionTotal = distribution.lp + distribution.marketing + distribution.dev;
            require(distributionTotal <= 3, "Total distribution cannot be more than 3");
    }

    function distributeToken(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Lengths do not match");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(totalAmount <= fgold.balanceOf(address(this)), "Insufficient balance");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(fgold.transferFrom(address(this), recipients[i], amounts[i]), "Transfer failed");
        }
    }
    
    function renounceOwnership() public view override onlyOwner {
        revert("Ownership cannot be renounced");
    }

    receive() external payable {}
}
