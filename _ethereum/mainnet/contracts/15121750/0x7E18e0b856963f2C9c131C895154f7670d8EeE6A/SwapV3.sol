// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./Ownable.sol";
import "./TransferHelper.sol";
import "./ISwapRouter.sol";

interface IFeeCollection {
    function claimBuyDistribute() external;

    function claimBuyBurn() external;
}

interface IHedron {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function proofOfBenevolence(uint256 amount) external; // To Burn the Hedron
}

contract SwapV3 is Ownable {
    ISwapRouter public immutable swapRouter;

    IFeeCollection public fee;
    address public stake;

    address public constant HDRN = 0x3819f64f282bf135d62168C1e513280dAF905e06;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint24 internal ETH_USDC_POOL = 3000;
    uint24 internal HDRN_USDC_POOL = 10000;

    constructor(ISwapRouter _swapRouter, address feeCollection) {
        swapRouter = _swapRouter;
        fee = IFeeCollection(feeCollection);
    }

    function setStakeAddress(address _stake) external onlyOwner {
        require(_stake != stake, "Cannot add the same stake address");
        stake = _stake;
    }

    function updateETHtoUSDCPool(
        uint24 newETH2USDCShare,
        uint24 newUSDC2HDRNShare
    ) external onlyOwner {
        if (newETH2USDCShare != 0 && newETH2USDCShare != ETH_USDC_POOL) {
            ETH_USDC_POOL = newETH2USDCShare;
        }

        if (newUSDC2HDRNShare != 0 && newUSDC2HDRNShare != HDRN_USDC_POOL) {
            HDRN_USDC_POOL = newUSDC2HDRNShare;
        }
    }

    function setFeeCollectionAddress(address _fee) external onlyOwner {
        fee = IFeeCollection(_fee);
    }

    function convertEthToHedronDistribute() external returns (uint256) {
        fee.claimBuyDistribute();
        uint256 amountIn = address(this).balance;

        require(amountIn > 0, "Amount cannot be less than 0");

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(
                    WETH9,
                    uint24(ETH_USDC_POOL),
                    USDC,
                    uint24(HDRN_USDC_POOL),
                    HDRN
                ),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });
        swapRouter.exactInput{value: amountIn}(params);
        uint256 balance = IHedron(HDRN).balanceOf(address(this));
        require(
            IHedron(HDRN).transfer(stake, balance),
            "Hedron not transferred successfully"
        );
        return balance;
    }

    function convertEthToHedronBurn() external returns (uint256) {
        uint256 balanceBefore = address(this).balance;
        fee.claimBuyBurn();
        uint256 balanceAfter = address(this).balance;
        uint256 amountIn = balanceAfter - balanceBefore;

        require(amountIn > 0, "Amount cannot be less than 0");

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(
                    WETH9,
                    uint24(ETH_USDC_POOL),
                    USDC,
                    uint24(HDRN_USDC_POOL),
                    HDRN
                ),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        swapRouter.exactInput{value: amountIn}(params);
        uint256 balance = IHedron(HDRN).balanceOf(address(this));

        IHedron(HDRN).approve(HDRN, balance);
        IHedron(HDRN).proofOfBenevolence(balance);

        return balance;
    }

    receive() external payable {}
}
