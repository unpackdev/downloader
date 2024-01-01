pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router01 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface INoMintRewardPool {
    function migrate() external;
    function exit() external;
}

interface IFarmERC20 is IERC20 {
    function withdraw(uint256 numberOfShares) external;
}

interface IBalancerVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

contract FarmArb {
    IUniswapV2Router01 router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 fUsdc = IERC20(0xc3F7ffb5d5869B3ade9448D094d81B0521e8326f);
    INoMintRewardPool pool = INoMintRewardPool(0x4F7c28cCb0F1Dbd1388209C67eEc234273C878Bd);
    IFarmERC20 mFUsdc = IFarmERC20(0xf0358e8c3CD5Fa238a29301d0bEa3D63A17bEdBE);
    IBalancerVault balancerVault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    uint input;
    uint min;

    function aaaRun(uint _input, uint _min, uint flash) public {
        input = _input;
        min = _min;
        address[] memory tokens = new address[](1);
        tokens[0] = address(usdc);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = flash;

        balancerVault.flashLoan(address(this), tokens, amounts, "");
        usdc.transfer(msg.sender, usdc.balanceOf(address(this)));
    }

    function receiveFlashLoan(
        IERC20[] memory,
        uint256[] memory amounts,
        uint256[] memory,
        bytes memory
    ) external {
        address[] memory usdcTofUsdc = new address[](2);
        usdcTofUsdc[0] = address(usdc);
        usdcTofUsdc[1] = address(fUsdc);

        usdc.approve(address(router), input);
        router.swapExactTokensForTokens(
            input,
            min,
            usdcTofUsdc,
            address(this),
            block.timestamp
        );

        fUsdc.approve(address(pool), fUsdc.balanceOf(address(this)));
        pool.migrate();
        pool.exit();
        mFUsdc.withdraw(mFUsdc.balanceOf(address(this)));

        usdc.transfer(address(balancerVault), amounts[0]);
    }
}