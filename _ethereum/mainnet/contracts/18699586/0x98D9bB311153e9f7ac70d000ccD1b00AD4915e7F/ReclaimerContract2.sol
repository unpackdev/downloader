// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import "./ERC20.sol";

interface IPool {
  function flashLoan( address receiverAddress, address[] calldata assets, uint256[] calldata amounts, uint256[] memory interestRateModes, address onBehalfOf, bytes calldata params, uint16 referralCode) external;
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

contract ReclaimerContract2 {
    // protocols
    address constant private AAVE = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant private SILO_1 = 0xB1590d554dC7d66F710369983b46a5905AD34c8c;
    address constant private SILO_2 = 0xFCCc27AABd0AB7a0B2Ad2B7760037B1eAb61616b;
    address constant private UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // silo 1 tokens
    address constant private SXAI_COLLATERAL = 0x8CCD889bb3a0252b803B6B6eaA0404c40CF8Cca7;
    address constant private DWETH_DEBT = 0x5748686318Aad9F4759a9d7710CCcbF28aFeBBAb;
    address constant private DRETH_DEBT = 0xA5a688DfAa51AAfb34B846B25c62Ca792AECc95C;

    // silo 2 tokens
    address constant private SWETH_COLLATERAL = 0x818Ae48449DfdF908F7bb58f7aa2Ba16863f79dF;
    address constant private DUSDC_DEBT = 0x35406DFcF3234222ed1046B04C2E912B37d87258;
    address constant private DXAI_DEBT = 0x3C9124C18CE9fB99724cf0a8080bEeeF8B0D3cf6;

    // underlying tokens
    address constant private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant private RETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address constant private USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant private XAI = 0xd7C9F0e536dC865Ae858b0C0453Fe76D13c3bEAc;

    // users
    address constant private USER = 0xa325076Ab0e701eec54D0072974D0fD26B31612C;
    address constant private RECEIVER = 0xD3e842A1D04F9Edaa328cca8874C8896F0044CfB;
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

    function run(uint256 sXaiReclaimAmount, uint256 wEthReclaimAmount, uint256[] calldata flashBorrowAmounts, uint256[] calldata swapRates) external {
        // Hardcoded addresses for WETH, RETH, USDC
        address[] memory assets = new address[](3);
        assets[0] = address(WETH);
        assets[1] = address(RETH);
        assets[2] = address(USDC);

        // Modes array, set to 0 for all assets
        uint256[] memory modes = new uint256[](3);
        modes[0] = 0;
        modes[1] = 0;
        modes[2] = 0;

        IPool(address(AAVE)).flashLoan(address(this), assets, flashBorrowAmounts, modes, address(0), abi.encode(sXaiReclaimAmount, wEthReclaimAmount, swapRates), 0);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata flashBorrowAmounts,
        uint256[] calldata premiums,
        address /*initiator*/,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == address(AAVE), "Caller must be Aave Lending Pool");

        // Decode parameters
        (uint256 sXaiReclaimAmount, uint256 wEthReclaimAmount, uint256[2] memory swapRates) = abi.decode(params, (uint256, uint256, uint256[2]));

        // Repay debt in silo 1
        ERC20(WETH).approve(SILO_1, type(uint256).max);
        ERC20(RETH).approve(SILO_1, type(uint256).max);
        ISilo(SILO_1).repayFor(WETH, USER, flashBorrowAmounts[0]);
        ISilo(SILO_1).repayFor(RETH, USER, flashBorrowAmounts[1]);

        // Reclaim SXAI collateral from silo 1
        ERC20(SXAI_COLLATERAL).transferFrom(USER, address(this), sXaiReclaimAmount);

        // Redeem SXAI for XAI
        ISilo(SILO_1).withdraw(XAI, type(uint256).max, false);

        // Repay XAI debt in silo 2
        ERC20(XAI).approve(SILO_2, type(uint256).max);
        ISilo(SILO_2).repayFor(XAI, USER, ERC20(XAI).balanceOf(address(this)));

        // Repay USDC debt in silo 2
        ERC20(USDC).approve(SILO_2, type(uint256).max);
        ISilo(SILO_2).repayFor(USDC, USER, flashBorrowAmounts[2]);

        // Reclaim WETH collateral from silo 2
        ERC20(SWETH_COLLATERAL).transferFrom(USER, address(this), wEthReclaimAmount);
        ISilo(SILO_2).withdraw(WETH, type(uint256).max, false);

        // Swap WETH to repay flashloans
        ERC20(WETH).approve(UNISWAP_V3_ROUTER, type(uint256).max);
        swapWEthForTargetAmount(500, RETH, flashBorrowAmounts[1] + premiums[1], swapRates[0]);
        swapWEthForTargetAmount(500, USDC, flashBorrowAmounts[2] + premiums[2], swapRates[1]);

        // Approve Aave for repayment
        ERC20(WETH).approve(AAVE, flashBorrowAmounts[0]+premiums[0]);
        ERC20(RETH).approve(AAVE, flashBorrowAmounts[1]+premiums[1]);
        ERC20(USDC).approve(AAVE, flashBorrowAmounts[2]+premiums[2]);

        // Transfer remainder to RECEIVER
        ERC20(WETH).transfer(RECEIVER, ERC20(WETH).balanceOf(address(this)) - (flashBorrowAmounts[0]+premiums[0]));
        ERC20(RETH).transfer(RECEIVER, ERC20(RETH).balanceOf(address(this)) - (flashBorrowAmounts[1]+premiums[1]));
        ERC20(USDC).transfer(RECEIVER, ERC20(USDC).balanceOf(address(this)) - (flashBorrowAmounts[2]+premiums[2]));
        ERC20(XAI).transfer(RECEIVER, ERC20(XAI).balanceOf(address(this)));
        
        return true;
    }

    function transfer(address token, address to, uint256 amount) external onlyDeployer{
        ERC20(token).transfer(to, amount);
    }

    function destroy() external onlyDeployer {
        selfdestruct(payable(deployer));
    }

    function swapWEthForTargetAmount(uint24 uniswapFee, address tokenReceive, uint256 targetReceiveAmount, uint256 currentRate) internal {
        uint256 maxInAmount = targetReceiveAmount * 10**18 / currentRate;
        IUniswapV3Router.ExactOutputSingleParams memory params = IUniswapV3Router.ExactOutputSingleParams({
            tokenIn: WETH,
            tokenOut: tokenReceive,
            fee: uniswapFee,
            recipient: address(this),
            deadline: block.timestamp + 60,
            amountOut: targetReceiveAmount,
            amountInMaximum: maxInAmount,
            sqrtPriceLimitX96: 0
        });
        IUniswapV3Router(UNISWAP_V3_ROUTER).exactOutputSingle(params);
    }
}