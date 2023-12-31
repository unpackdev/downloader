// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./Interfaces.sol";

contract DoughV1Dsa {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address private constant AAVE_V3_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address private constant AAVE_V3_DATA_PROVIDER = 0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3;
    address private constant AAVE_V3_ORACLE = 0x54586bE62E3c3580375aE3723C145253060Ca0C2;

    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router private uniswap_v2_router = IUniswapV2Router(UNISWAP_V2_ROUTER);

    /* ========== STATE VARIABLES ========== */
    address public owner;
    address public DoughV1Index = address(0);
    address public doughFlashloan = address(0);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _owner, address _DoughV1Index, address _doughFlashloan) {
        owner = _owner;
        DoughV1Index = _DoughV1Index;
        doughFlashloan = _doughFlashloan;
    }

    receive() external payable {}

    /* ========== Modifier ========== */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAble() {
        require(msg.sender != address(0), "msg.sender is zero address");
        require(owner == msg.sender || IDoughV1Index(DoughV1Index).SHIELD_EXECUTOR() == msg.sender, "caller is not the owner or dough shield contract");
        _;
    }

    /* ========== VIEWS ========== */
    function balanceOfEth() external view returns (uint256) {
        return address(this).balance;
    }

    function balanceOfToken(address _tokenAddr) external view returns (uint256) {
        return IERC20(_tokenAddr).balanceOf(address(this));
    }

    function getUserData() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 totalCollateralBase, uint256 totalDebtBase, uint256 availableBorrowsBase, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor) = IAaveV3Pool(AAVE_V3_POOL).getUserAccountData(address(this));
        return (totalCollateralBase, totalDebtBase, availableBorrowsBase, currentLiquidationThreshold, ltv, healthFactor);
    }

    function getPosition(address asset) external view returns (uint256, uint256, uint256) {
        (uint256 currentATokenBalance, uint256 currentStableDebt, uint256 currentVariableDebt, , , , , , ) = IAaveV3DataProvider(AAVE_V3_DATA_PROVIDER).getUserReserveData(asset, address(this));
        return (currentATokenBalance, currentStableDebt, currentVariableDebt);
    }

    function getAssetsPrices() external view returns (uint256, uint256, uint256) {
        uint256 price_weth = IAaveV3Oracle(AAVE_V3_ORACLE).getAssetPrice(WETH);
        uint256 price_wbtc = IAaveV3Oracle(AAVE_V3_ORACLE).getAssetPrice(WBTC);
        uint256 price_usdc = IAaveV3Oracle(AAVE_V3_ORACLE).getAssetPrice(USDC);
        return (price_weth, price_wbtc, price_usdc);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function depositEthToDsa() external payable onlyOwner {
        require(msg.value > 0, "must be greater than zero");
        IWETH(WETH).deposit{value: msg.value}();
    }

    function depositTokenToDsa(address _tokenAddr, uint256 _amount) external onlyOwner {
        require(_amount > 0, "must be greater than zero");
        IERC20(_tokenAddr).transferFrom(owner, address(this), _amount);
    }

    function withdrawEthFromDsa(uint256 _amount) external onlyOwner {
        require(_amount > 0, "must be greater than zero");
        require(_amount <= address(this).balance, "must be less than balance of ETH");
        payable(owner).transfer(_amount);
    }

    function withdrawTokenFromDsa(address _tokenAddr, uint256 _amount) external onlyOwner {
        require(_amount > 0, "must be greater than zero");
        require(_amount <= IERC20(_tokenAddr).balanceOf(address(this)), "must be less than balance of token");
        if (_tokenAddr == WETH) {
            IWETH(WETH).withdraw(_amount);
            payable(owner).transfer(_amount);
        } else {
            IERC20(_tokenAddr).transfer(owner, _amount);
        }
    }

    function supplyToAaveV3(address asset, uint256 amount) external onlyOwner {
        IERC20(asset).approve(AAVE_V3_POOL, amount);
        IAaveV3Pool(AAVE_V3_POOL).supply(asset, amount, address(this), 0);
    }

    function withdrawFromAaveV3(address asset, uint256 amount, bool isClose) external onlyOwner {
        uint256 withdrawAmount = amount;
        if (isClose) {
            (withdrawAmount, , , , , , , , ) = IAaveV3DataProvider(AAVE_V3_DATA_PROVIDER).getUserReserveData(asset, address(this));
        }
        IAaveV3Pool(AAVE_V3_POOL).withdraw(asset, withdrawAmount, address(this));
    }

    function borrowFromAaveV3(address asset, uint256 amount) external onlyOwner {
        IAaveV3Pool(AAVE_V3_POOL).borrow(asset, amount, 2, 0, address(this));
    }

    function repayToAaveV3(address asset, uint256 amount, bool isClose) external onlyOwner returns (uint256) {
        uint256 repayAmount = amount;
        if (isClose) {
            (, , repayAmount, , , , , , ) = IAaveV3DataProvider(AAVE_V3_DATA_PROVIDER).getUserReserveData(asset, address(this));
        }
        IERC20(asset).approve(AAVE_V3_POOL, repayAmount);
        return IAaveV3Pool(AAVE_V3_POOL).repay(asset, repayAmount, 2, address(this));
    }

    function swapByUniswapV2(address assetIn, uint256 amountIn, address assetOut, uint256 amountOutMin) external onlyOwner returns (uint256) {
        IERC20(assetIn).approve(address(uniswap_v2_router), amountIn);
        address[] memory path;
        path = new address[](2);
        path[0] = assetIn;
        path[1] = assetOut;
        uint[] memory amounts = uniswap_v2_router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp);
        return amounts[1];
    }

    function _calcFeeAmount(address _doughV1Index, uint256 amount) private view returns (uint256) {
        return (amount * IDoughV1Index(_doughV1Index).FLASHLOAN_FEE_TOTAL()) / 10000;
    }

    function flashloanForLoop(address loanToken, uint256 leverage) external onlyAble {
        require(loanToken == WETH || loanToken == WBTC, "invalid token.");
        require(leverage > 110, "must be greater than 110(1.1x)"); // decimals 2
        (uint256 currentATokenBalance, , , , , , , , ) = IAaveV3DataProvider(AAVE_V3_DATA_PROVIDER).getUserReserveData(loanToken, address(this));
        require(currentATokenBalance > 0, "supply first");

        uint256 loanAmountForLoop = (currentATokenBalance * (leverage - 100)) / 100;

        uint256 flashLoanFeeAmount = _calcFeeAmount(DoughV1Index, loanAmountForLoop);

        require(flashLoanFeeAmount < IERC20(loanToken).balanceOf(address(this)), "deploy token");
        IERC20(loanToken).approve(doughFlashloan, flashLoanFeeAmount);
        IDoughV1Flashloan(doughFlashloan).flashloanReq(loanToken, loanAmountForLoop, flashLoanFeeAmount, 0);
    }

    function flashloanForDeloop(address loanToken, uint256 loanAmount, bool isClose) external onlyAble {
        require(loanToken == WETH || loanToken == WBTC, "invalid token.");
        (, , uint256 currentVariableDebt, , , , , , ) = IAaveV3DataProvider(AAVE_V3_DATA_PROVIDER).getUserReserveData(loanToken, address(this));
        require(currentVariableDebt > 0, "Loop first");
        require(loanAmount <= currentVariableDebt, "loanAmount must be less than Debt");
        uint256 loanAmountForDeloop = loanAmount;
        if (isClose) {
            loanAmountForDeloop = currentVariableDebt;
        }

        uint256 flashLoanFeeAmount = _calcFeeAmount(DoughV1Index, loanAmountForDeloop);

        require(flashLoanFeeAmount < IERC20(loanToken).balanceOf(address(this)), "deploy token");
        IERC20(loanToken).approve(doughFlashloan, flashLoanFeeAmount);
        IDoughV1Flashloan(doughFlashloan).flashloanReq(loanToken, currentVariableDebt, flashLoanFeeAmount, 1);
    }

    function executeAction(address loanToken, uint256 loanAmount, uint256 funcId) external {
        require(msg.sender == doughFlashloan, "wrong doughFlashloan");
        IERC20(loanToken).transferFrom(doughFlashloan, address(this), loanAmount);
        IERC20(loanToken).approve(AAVE_V3_POOL, loanAmount);
        if (funcId == 0) {
            // Loop
            IAaveV3Pool(AAVE_V3_POOL).supply(loanToken, loanAmount, address(this), 0);
            IAaveV3Pool(AAVE_V3_POOL).borrow(loanToken, loanAmount, 2, 0, address(this));
        } else {
            // Deloop
            IERC20(loanToken).approve(AAVE_V3_POOL, loanAmount);
            IAaveV3Pool(AAVE_V3_POOL).repay(loanToken, loanAmount, 2, address(this));
            IAaveV3Pool(AAVE_V3_POOL).withdraw(loanToken, loanAmount, address(this));
        }
        IERC20(loanToken).approve(doughFlashloan, loanAmount);
    }
}
