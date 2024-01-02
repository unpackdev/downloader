// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import "./ERC20.sol";

interface IPool {
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;
}

interface ISilo {
    function depositFor(address _asset, address _depositor, uint256 _amount, bool _collateralOnly) external;
    function repayFor(address _asset, address _borrower, uint256 _amount) external;
    function withdraw(address _asset, uint256 _amount, bool _collateralOnly) external;
    function withdrawFor(address _asset, address _depositor, address _receiver, uint256 _amount, bool _collateralOnly) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV3Router {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    function exactOutputSingle(ExactOutputSingleParams calldata params) external returns (uint256 amountIn);
}

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

contract ReclaimerContract {
    // protocols
    address constant private AAVE = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant private SILO = 0x63E5D6cc84ed2A6336b2A06FB5b4318F70F14b45;

    // tokens
    address constant private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant private SRPL = 0xF5328879635Edd800ee67b10c8246a1841d88C21;
    address constant private RPL = 0xD33526068D116cE69F19A9ee46F0bd304F21A51f;

    // user
    address constant private USER = 0xa325076Ab0e701eec54D0072974D0fD26B31612C;
    address constant private RECEIVER = 0xD3e842A1D04F9Edaa328cca8874C8896F0044CfB;

    address constant private UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint24 constant private UNISWAP_FEE = 3000;

    address immutable private deployer;
   
    modifier onlyDeployer() {
        require(msg.sender == deployer, "Not deployer");
        _;
    }
    constructor() {
        deployer = msg.sender;
    }

    // Receive function to accept ETH
    receive() external payable {
    }

    function run(uint256 flashBorrowAmount, uint256 collReclaimAmount, uint256 currentRate, uint256 slippageTolerance) external {
        IPool(address(AAVE)).flashLoanSimple(
            address(this),
            WETH,
            flashBorrowAmount,
            abi.encode(collReclaimAmount, currentRate, slippageTolerance),
            0
        );
    }

    function executeOperation(
        address asset,
        uint256 flashBorrowAmount,
        uint256 premium,
        address /*initiator*/,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == address(AAVE), "Caller must be Aave Lending Pool");
        require(asset == WETH, "Asset must be WETH");
        
        // Decode parameters
        (uint256 collReclaimAmount, uint256 currentRate, uint256 slippageTolerance) = abi.decode(params, (uint256, uint256, uint256));

        // Repay debt
        ERC20(WETH).approve(SILO, type(uint256).max);
        ISilo(SILO).repayFor(WETH, USER, flashBorrowAmount);

        // Pull sRPL position
        ERC20(SRPL).transferFrom(USER, address(this), collReclaimAmount);

        // Withdraw RPL
        ISilo(SILO).withdraw(RPL, type(uint256).max, false);

        // Swap RPL for ETH
        uint256 totalRepayment = flashBorrowAmount + premium;
        swapRplForEthTargetAmount(totalRepayment, currentRate, slippageTolerance);

        // Wrap received ETH to WETH
        IWETH(WETH).deposit{value: address(this).balance}();
        require(ERC20(WETH).balanceOf(address(this)) == totalRepayment, "Swap received WETH doesn't match repayment");

        // Approve Aave
        IWETH(WETH).approve(AAVE, totalRepayment);

        // Send remaining RPL to RECEIVER
        ERC20(RPL).transfer(RECEIVER, ERC20(RPL).balanceOf(address(this)));

        return true;
    }

    function transfer(address token, address to, uint256 amount) external onlyDeployer{
        ERC20(token).transfer(to, amount);
    }

    function destroy() external onlyDeployer {
        selfdestruct(payable(deployer));
    }

    function swapRplForEthTargetAmount(uint256 targetEthAmount, uint256 currentRate, uint256 slippageTolerance) internal {
        ERC20(RPL).approve(UNISWAP_V3_ROUTER, type(uint256).max);

        uint256 maxRplWithSlippage = targetEthAmount * 10**18 * (10000 + slippageTolerance) / 10000 / currentRate;
        IUniswapV3Router.ExactOutputSingleParams memory params = IUniswapV3Router.ExactOutputSingleParams({
            tokenIn: RPL,
            tokenOut: WETH,
            fee: UNISWAP_FEE,
            recipient: address(this),
            deadline: block.timestamp + 60,
            amountOut: targetEthAmount,
            amountInMaximum: maxRplWithSlippage,
            sqrtPriceLimitX96: 0
        });
        IUniswapV3Router(UNISWAP_V3_ROUTER).exactOutputSingle(params);
    }
}