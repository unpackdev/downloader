// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface ICurve {
    function add_liquidity(uint[2] memory amounts, uint amountOutMin) external;
    function remove_liquidity_one_coin(uint amount, int128 index, uint amountOutMin) external;
}

interface IDaoL1Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external returns (uint);
    function getAllPoolInUSD() external view returns (uint);
    function getAllPoolInETH() external view returns (uint);
    function getAllPoolInNative() external view returns (uint);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract CitadelV2Strategy is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable constant WETH = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable constant WBTC = IERC20Upgradeable(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20Upgradeable constant DPI = IERC20Upgradeable(0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b);
    IERC20Upgradeable constant DAI = IERC20Upgradeable(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    IERC20Upgradeable constant HBTCWBTC = IERC20Upgradeable(0xb19059ebb43466C323583928285a49f558E572Fd);
    IERC20Upgradeable constant WBTCETH = IERC20Upgradeable(0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58);
    IERC20Upgradeable constant DPIETH = IERC20Upgradeable(0x34b13F8CD184F55d0Bd4Dd1fe6C07D46f245c7eD);
    IERC20Upgradeable constant DAIETH = IERC20Upgradeable(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f);

    ICurve constant curvePool = ICurve(0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F);
    IRouter constant sushiRouter = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // Sushi

    IDaoL1Vault public HBTCWBTCVault;
    IDaoL1Vault public WBTCETHVault;
    IDaoL1Vault public DPIETHVault;
    IDaoL1Vault public DAIETHVault;

    uint constant HBTCWBTCTargetPerc = 3000;
    uint constant WBTCETHTargetPerc = 3000;
    uint constant DPIETHTargetPerc = 3000;
    uint constant DAIETHTargetPerc = 1000;

    address public vault;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;

    event TargetComposition (uint HBTCWBTCTargetPool, uint WBTCETHTargetPool, uint DPIETHTargetPool, uint DAIETHTargetPool);
    event CurrentComposition (uint HBTCWBTCCurrentPool, uint WBTCETHCurrentPool, uint DPIETHCurrentPool, uint DAIETHCurrentPool);
    event InvestHBTCWBTC(uint WETHAmt, uint HBTCWBTCAmt);
    event InvestWBTCETH(uint WETHAmt, uint WBTCETHAmt);
    event InvestDPIETH(uint WETHAmt, uint DPIETHAmt);
    event InvestDAIETH(uint WETHAmt, uint DAIETHAmt);
    event Withdraw(uint amount, uint WETHAmt);
    event WithdrawHBTCWBTC(uint lpTokenAmt, uint WETHAmt);
    event WithdrawWBTCETH(uint lpTokenAmt, uint WETHAmt);
    event WithdrawDPIETH(uint lpTokenAmt, uint WETHAmt);
    event WithdrawDAIETH(uint lpTokenAmt, uint WETHAmt);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event Reimburse(uint WETHAmt);
    event EmergencyWithdraw(uint WETHAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(
        address _HBTCWBTCVault, address _WBTCETHVault, address _DPIETHVault, address _DAIETHVault
    ) external initializer {
        __Ownable_init();

        HBTCWBTCVault = IDaoL1Vault(_HBTCWBTCVault);
        WBTCETHVault = IDaoL1Vault(_WBTCETHVault);
        DPIETHVault = IDaoL1Vault(_DPIETHVault);
        DAIETHVault = IDaoL1Vault(_DAIETHVault);

        profitFeePerc = 2000;

        WETH.safeApprove(address(sushiRouter), type(uint).max);
        WBTC.safeApprove(address(curvePool), type(uint).max);
        WBTC.safeApprove(address(sushiRouter), type(uint).max);
        DPI.safeApprove(address(sushiRouter), type(uint).max);
        DAI.safeApprove(address(sushiRouter), type(uint).max);

        HBTCWBTC.safeApprove(address(HBTCWBTCVault), type(uint).max);
        HBTCWBTC.safeApprove(address(sushiRouter), type(uint).max);
        WBTCETH.safeApprove(address(WBTCETHVault), type(uint).max);
        WBTCETH.safeApprove(address(sushiRouter), type(uint).max);
        DPIETH.safeApprove(address(DPIETHVault), type(uint).max);
        DPIETH.safeApprove(address(sushiRouter), type(uint).max);
        DAIETH.safeApprove(address(DAIETHVault), type(uint).max);
        DAIETH.safeApprove(address(sushiRouter), type(uint).max);
    }

    function invest(uint WETHAmt) external onlyVault {
        WETH.safeTransferFrom(vault, address(this), WETHAmt);

        uint[] memory pools = getEachPool();
        uint pool = pools[0] + pools[1] + pools[2] + pools[3] + WETHAmt;
        uint HBTCWBTCTargetPool = pool * 3000 / 10000; // 30%
        uint WBTCETHTargetPool = HBTCWBTCTargetPool; // 30%
        uint DPIETHTargetPool = HBTCWBTCTargetPool; // 30%
        uint DAIETHTargetPool = pool * 1000 / 10000; // 10%

        // Rebalancing invest
        if (
            HBTCWBTCTargetPool > pools[0] &&
            WBTCETHTargetPool > pools[1] &&
            DPIETHTargetPool > pools[2] &&
            DAIETHTargetPool > pools[3]
        ) {
            investHBTCWBTC(HBTCWBTCTargetPool - pools[0]);
            investWBTCETH((WBTCETHTargetPool - pools[1]));
            investDPIETH((DPIETHTargetPool - pools[2]));
            investDAIETH((DAIETHTargetPool - pools[3]));
        } else {
            uint furthest;
            uint farmIndex;
            uint diff;

            if (HBTCWBTCTargetPool > pools[0]) {
                diff = HBTCWBTCTargetPool - pools[0];
                furthest = diff;
                farmIndex = 0;
            }
            if (WBTCETHTargetPool > pools[1]) {
                diff = WBTCETHTargetPool - pools[1];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 1;
                }
            }
            if (DPIETHTargetPool > pools[2]) {
                diff = DPIETHTargetPool - pools[2];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 2;
                }
            }
            if (DAIETHTargetPool > pools[3]) {
                diff = DAIETHTargetPool - pools[3];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 3;
                }
            }

            if (farmIndex == 0) investHBTCWBTC(WETHAmt);
            else if (farmIndex == 1) investWBTCETH(WETHAmt);
            else if (farmIndex == 2) investDPIETH(WETHAmt);
            else investDAIETH(WETHAmt);
        }

        emit TargetComposition(HBTCWBTCTargetPool, WBTCETHTargetPool, DPIETHTargetPool, DAIETHTargetPool);
        emit CurrentComposition(pools[0], pools[1], pools[2], pools[3]);
    }

    function investHBTCWBTC(uint WETHAmt) private {
        uint WBTCAmt = swap(address(WETH), address(WBTC), WETHAmt, 0);
        uint256[2] memory amounts = [0, WBTCAmt];
        curvePool.add_liquidity(amounts, 0);
        uint HBTCWBTCAmt = HBTCWBTC.balanceOf(address(this));
        HBTCWBTCVault.deposit(HBTCWBTCAmt);
        emit InvestHBTCWBTC(WETHAmt, HBTCWBTCAmt);
    }

    function investWBTCETH(uint WETHAmt) private {
        uint halfWETH = WETHAmt / 2;
        uint WBTCAmt = swap(address(WETH), address(WBTC), halfWETH, 0);
        (,,uint WBTCETHAmt) = sushiRouter.addLiquidity(address(WBTC), address(WETH), WBTCAmt, halfWETH, 0, 0, address(this), block.timestamp);
        WBTCETHVault.deposit(WBTCETHAmt);
        emit InvestWBTCETH(WETHAmt, WBTCETHAmt);
    }

    function investDPIETH(uint WETHAmt) private {
        uint halfWETH = WETHAmt / 2;
        uint DPIAmt = swap(address(WETH), address(DPI), halfWETH, 0);
        (,,uint DPIETHAmt) = sushiRouter.addLiquidity(address(DPI), address(WETH), DPIAmt, halfWETH, 0, 0, address(this), block.timestamp);
        DPIETHVault.deposit(DPIETHAmt);
        emit InvestDPIETH(WETHAmt, DPIETHAmt);
    }

    function investDAIETH(uint WETHAmt) private {
        uint halfWETH = WETHAmt / 2;
        uint DAIAmt = swap(address(WETH), address(DAI), halfWETH, 0);
        (,,uint DAIETHAmt) = sushiRouter.addLiquidity(address(DAI), address(WETH), DAIAmt, halfWETH, 0, 0, address(this), block.timestamp);
        DAIETHVault.deposit(DAIETHAmt);
        emit InvestDAIETH(WETHAmt, DAIETHAmt);
    }

    /// @param amount Amount to withdraw in USD
    function withdraw(uint amount, uint[] calldata tokenPrice) external onlyVault returns (uint WETHAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD();
        uint WETHAmtBefore = WETH.balanceOf(address(this));
        withdrawHBTCWBTC(sharePerc, tokenPrice[1]);
        withdrawWBTCETH(sharePerc, tokenPrice[1]);
        withdrawDPIETH(sharePerc, tokenPrice[2]);
        withdrawDAIETH(sharePerc, tokenPrice[3]);
        WETHAmt = WETH.balanceOf(address(this)) - WETHAmtBefore;
        WETH.safeTransfer(vault, WETHAmt);
        emit Withdraw(amount, WETHAmt);
    }

    function withdrawHBTCWBTC(uint sharePerc, uint WBTCPrice) private {
        uint HBTCWBTCAmt = HBTCWBTCVault.withdraw(HBTCWBTCVault.balanceOf(address(this)) * sharePerc / 1e18);
        curvePool.remove_liquidity_one_coin(HBTCWBTCAmt, 1, 0);
        uint WBTCAmt = WBTC.balanceOf(address(this));
        uint _WETHAmt = swap(address(WBTC), address(WETH), WBTCAmt, WBTCAmt * WBTCPrice / 1e8);
        emit WithdrawHBTCWBTC(HBTCWBTCAmt, _WETHAmt);
    }

    function withdrawWBTCETH(uint sharePerc, uint WBTCPrice) private {
        uint WBTCETHAmt = WBTCETHVault.withdraw(WBTCETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint WBTCAmt, uint WETHAmt) = sushiRouter.removeLiquidity(address(WBTC), address(WETH), WBTCETHAmt, 0, 0, address(this), block.timestamp);
        uint _WETHAmt = swap(address(WBTC), address(WETH), WBTCAmt, WBTCAmt * WBTCPrice / 1e8);
        emit WithdrawWBTCETH(WBTCETHAmt, WETHAmt + _WETHAmt);
    }

    function withdrawDPIETH(uint sharePerc, uint DPIPrice) private {
        uint DPIETHAmt = DPIETHVault.withdraw(DPIETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint DPIAmt, uint WETHAmt) = sushiRouter.removeLiquidity(address(DPI), address(WETH), DPIETHAmt, 0, 0, address(this), block.timestamp);
        uint _WETHAmt = swap(address(DPI), address(WETH), DPIAmt, DPIAmt * DPIPrice / 1e18);
        emit WithdrawDPIETH(DPIETHAmt, WETHAmt + _WETHAmt);
    }

    function withdrawDAIETH(uint sharePerc, uint DAIPrice) private {
        uint DAIETHAmt = DAIETHVault.withdraw(DAIETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint DAIAmt, uint WETHAmt) = sushiRouter.removeLiquidity(address(DAI), address(WETH), DAIETHAmt, 0, 0, address(this), block.timestamp);
        uint _WETHAmt = swap(address(DAI), address(WETH), DAIAmt, DAIAmt * DAIPrice / 1e18);
        emit WithdrawDAIETH(DAIETHAmt, WETHAmt + _WETHAmt);
    }

    function collectProfitAndUpdateWatermark() public onlyVault returns (uint fee) {
        uint currentWatermark = getAllPoolInUSD();
        uint lastWatermark = watermark;
        if (currentWatermark > lastWatermark) {
            uint profit = currentWatermark - lastWatermark;
            fee = profit * profitFeePerc / 10000;
        }
        emit CollectProfitAndUpdateWatermark(currentWatermark, lastWatermark, fee);
    }

    /// @param signs True for positive, false for negative
    function adjustWatermark(uint amount, bool signs) external onlyVault {
        uint lastWatermark = watermark;
        watermark = signs == true ? watermark + amount : watermark - amount;
        emit AdjustWatermark(watermark, lastWatermark);
    }

    /// @param amount Amount to reimburse to vault contract in ETH
    function reimburse(uint farmIndex, uint amount) external onlyVault returns (uint WETHAmt) {
        if (farmIndex == 0) withdrawHBTCWBTC(amount * 1e18 / getHBTCWBTCPool(), 0);
        else if (farmIndex == 1) withdrawWBTCETH(amount * 1e18 / getWBTCETHPool(), 0);
        else if (farmIndex == 2) withdrawDPIETH(amount * 1e18 / getDPIETHPool(), 0);
        else if (farmIndex == 3) withdrawDAIETH(amount * 1e18 / getDAIETHPool(), 0);
        WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);
        emit Reimburse(WETHAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        withdrawHBTCWBTC(1e18, 0);
        withdrawWBTCETH(1e18, 0);
        withdrawDPIETH(1e18, 0);
        withdrawDAIETH(1e18, 0);
        uint WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);
        watermark = 0;
        emit EmergencyWithdraw(WETHAmt);
    }

    function swap(address from, address to, uint amount, uint amountOutMin) private returns (uint) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        return (sushiRouter.swapExactTokensForTokens(amount, amountOutMin, path, address(this), block.timestamp))[1];
    }

    function setVault(address _vault) external onlyOwner {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    function setProfitFeePerc(uint _profitFeePerc) external onlyVault {
        profitFeePerc = _profitFeePerc;
    }

    function getPath(address tokenA, address tokenB) private pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
    }

    function getHBTCWBTCPool() private view returns (uint) {
        uint HBTCWBTCVaultPoolInBTC = HBTCWBTCVault.getAllPoolInNative();
        if (HBTCWBTCVaultPoolInBTC == 0) return 0;
        uint share = HBTCWBTCVaultPoolInBTC * HBTCWBTCVault.balanceOf(address(this)) / HBTCWBTCVault.totalSupply();
        uint BTCPriceInETH = uint(IChainlink(0xdeb288F737066589598e9214E782fa5A8eD689e8).latestAnswer());
        require(BTCPriceInETH > 0, "ChainLink error");
        return share * BTCPriceInETH / 1e18;
    }

    function getWBTCETHPool() private view returns (uint) {
        uint WBTCETHVaultPool = WBTCETHVault.getAllPoolInETH();
        if (WBTCETHVaultPool == 0) return 0;
        return WBTCETHVaultPool * WBTCETHVault.balanceOf(address(this)) / WBTCETHVault.totalSupply();
    }

    function getDPIETHPool() private view returns (uint) {
        uint DPIETHVaultPool = DPIETHVault.getAllPoolInETH();
        if (DPIETHVaultPool == 0) return 0;
        return DPIETHVaultPool * DPIETHVault.balanceOf(address(this)) / DPIETHVault.totalSupply();
    }

    function getDAIETHPool() private view returns (uint) {
        uint DAIETHVaultPool = DAIETHVault.getAllPoolInETH();
        if (DAIETHVaultPool == 0) return 0;
        return DAIETHVaultPool * DAIETHVault.balanceOf(address(this)) / DAIETHVault.totalSupply();
    }

    function getEachPool() private view returns (uint[] memory pools) {
        pools = new uint[](4);
        pools[0] = getHBTCWBTCPool();
        pools[1] = getWBTCETHPool();
        pools[2] = getDPIETHPool();
        pools[3] = getDAIETHPool();
    }

    /// @notice This function return only farms TVL in ETH
    function getAllPool() public view returns (uint) {
        uint[] memory pools = getEachPool();
        return pools[0] + pools[1] + pools[2] + pools[3];
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint ETHPriceInUSD = uint(IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer()); // 8 decimals
        require(ETHPriceInUSD > 0, "ChainLink error");
        return getAllPool() * ETHPriceInUSD / 1e8;
    }

    function getCurrentCompositionPerc() external view returns (uint[] memory percentages) {
        uint[] memory pools = getEachPool();
        uint allPool = pools[0] + pools[1] + pools[2] + pools[3];
        percentages = new uint[](4);
        percentages[0] = pools[0] * 10000 / allPool;
        percentages[1] = pools[1] * 10000 / allPool;
        percentages[2] = pools[2] * 10000 / allPool;
        percentages[3] = pools[3] * 10000 / allPool;
    }
}
