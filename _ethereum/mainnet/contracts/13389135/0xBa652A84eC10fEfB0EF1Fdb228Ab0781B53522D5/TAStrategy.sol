// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
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

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint _pid, address _user) external view returns(uint amount, uint rewardDebt);
}

interface IDaoL1Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external returns (uint);
    function getAllPoolInUSD() external view returns (uint);
    function getAllPoolInETH() external view returns (uint);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract TAStrategy is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable constant WETH = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable constant WBTC = IERC20Upgradeable(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20Upgradeable constant USDC = IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IERC20Upgradeable constant WBTCETH = IERC20Upgradeable(0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58);
    IERC20Upgradeable constant USDCETH = IERC20Upgradeable(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);

    IDaoL1Vault public WBTCETHVault;
    IDaoL1Vault public USDCETHVault;

    IRouter constant router = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // Sushi
    IMasterChef constant masterChef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);

    address public vault;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;
    bool public mode; // Attack: true, Defence: false

    event InvestWBTCETH(uint WETHAmt, uint WBTCETHAmt);
    event InvestUSDCETH(uint WETHAmt, uint USDCETHAmt);
    event WithdrawWBTCETH(uint lpTokenAmt, uint WETHAmt);
    event WithdrawUSDCETH(uint lpTokenAmt, uint WETHAmt);
    event SwitchMode(uint lpTokenAmtFrom, uint lpTokenAmtTo, bool modeFrom, bool modeTo);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event Reimburse(uint WETHAmt);
    event EmergencyWithdraw(uint WETHAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(address _WBTCETHVault, address _USDCETHVault, bool _mode) external initializer {
        WBTCETHVault = IDaoL1Vault(_WBTCETHVault);
        USDCETHVault = IDaoL1Vault(_USDCETHVault);

        profitFeePerc = 2000;
        mode = _mode;

        WETH.safeApprove(address(router), type(uint).max);
        WBTC.safeApprove(address(router), type(uint).max);
        USDC.safeApprove(address(router), type(uint).max);

        WBTCETH.safeApprove(address(WBTCETHVault), type(uint).max);
        WBTCETH.safeApprove(address(router), type(uint).max);
        USDCETH.safeApprove(address(USDCETHVault), type(uint).max);
        USDCETH.safeApprove(address(router), type(uint).max);
    }

    function invest(uint WETHAmt) external onlyVault {
        WETH.safeTransferFrom(vault, address(this), WETHAmt);
        uint halfWETHAmt = WETHAmt / 2;

        if (mode) { // Attack
            uint WBTCAmt = swap2(address(WETH), address(WBTC), halfWETHAmt, 0);
            (,,uint WBTCETHAmt) = router.addLiquidity(
                address(WBTC), address(WETH), WBTCAmt, halfWETHAmt, 0, 0, address(this), block.timestamp
            );
            WBTCETHVault.deposit(WBTCETHAmt);
            emit InvestWBTCETH(WETHAmt, WBTCETHAmt);
        } else { // Defence
            uint USDCAmt = swap2(address(WETH), address(USDC), halfWETHAmt, 0);
            (,,uint USDCETHAmt) = router.addLiquidity(
                address(USDC), address(WETH), USDCAmt, halfWETHAmt, 0, 0, address(this), block.timestamp
            );
            USDCETHVault.deposit(USDCETHAmt);
            emit InvestUSDCETH(WETHAmt, USDCETHAmt);
        }
    }

    /// @param amount Amount to withdraw in USD
    function withdraw(uint amount, uint[] calldata tokenPrice) external onlyVault returns (uint WETHAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD();
        if (mode) WETHAmt = withdrawWBTCETH(sharePerc, tokenPrice[1]);
        else WETHAmt = withdrawUSDCETH(sharePerc, tokenPrice[2]);
        WETH.safeTransfer(vault, WETHAmt);
    }

    function withdrawWBTCETH(uint sharePerc, uint WBTCPriceInETH) private returns (uint) {
        uint WBTCETHAmt = WBTCETHVault.withdraw(WBTCETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint WBTCAmt, uint WETHAmt) = router.removeLiquidity(
            address(WBTC), address(WETH), WBTCETHAmt, 0, 0, address(this), block.timestamp
        );
        WETHAmt += swap2(address(WBTC), address(WETH), WBTCAmt, WBTCAmt * WBTCPriceInETH / 1e8);
        emit WithdrawWBTCETH(WBTCETHAmt, WETHAmt);
        return WETHAmt;
    }

    function withdrawUSDCETH(uint sharePerc, uint USDCPriceInETH) private returns (uint) {
        uint USDCETHAmt = USDCETHVault.withdraw(USDCETHVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint USDCAmt, uint WETHAmt) = router.removeLiquidity(
            address(USDC), address(WETH), USDCETHAmt, 0, 0, address(this), block.timestamp
        );
        WETHAmt += swap2(address(USDC), address(WETH), USDCAmt, USDCAmt * USDCPriceInETH / 1e6);
        emit WithdrawUSDCETH(USDCETHAmt, WETHAmt);
        return WETHAmt;
    }

    function switchMode(uint[] calldata tokenPrice) external onlyVault {
        if (mode) { // Attack switch to defence
            uint WBTCETHAmt = WBTCETHVault.withdraw(WBTCETHVault.balanceOf(address(this)));
            (uint WBTCAmt, uint WETHAmt) = router.removeLiquidity(
                address(WBTC), address(WETH), WBTCETHAmt, 0, 0, address(this), block.timestamp
            );
            // tokenPrice[0] = 1 WBTC Price In USDC
            uint USDCAmt = swap3(address(WBTC), address(USDC), WBTCAmt, WBTCAmt * tokenPrice[0] / 1e8);
            (,,uint USDCETHAmt) = router.addLiquidity(
                address(USDC), address(WETH), USDCAmt, WETHAmt, 0, 0, address(this), block.timestamp
            );
            USDCETHVault.deposit(USDCETHAmt);
            mode = false;
            emit SwitchMode(WBTCETHAmt, USDCETHAmt, true, false);
        } else { // Defence switch to attack
            uint USDCETHAmt = USDCETHVault.withdraw(USDCETHVault.balanceOf(address(this)));
            (uint USDCAmt, uint WETHAmt) = router.removeLiquidity(
                address(USDC), address(WETH), USDCETHAmt, 0, 0, address(this), block.timestamp
            );
            // tokenPrice[1] = 1 USDC Price In WBTC
            uint WBTCAmt = swap3(address(USDC), address(WBTC), USDCAmt, USDCAmt * tokenPrice[1] / 1e6);
            (,,uint WBTCETHAmt) = router.addLiquidity(
                address(WBTC), address(WETH), WBTCAmt, WETHAmt, 0, 0, address(this), block.timestamp
            );
            WBTCETHVault.deposit(WBTCETHAmt);
            mode = true;
            emit SwitchMode(USDCETHAmt, WBTCETHAmt, false, true);
        }
    }

    function collectProfitAndUpdateWatermark() public onlyVault returns (uint fee) {
        uint currentWatermark = getAllPoolInUSD();
        uint lastWatermark = watermark;
        if (currentWatermark > lastWatermark) {
            uint profit = currentWatermark - lastWatermark;
            fee = profit * profitFeePerc / 10000;
            watermark = currentWatermark;
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
    function reimburse(uint amount) external onlyVault returns (uint WETHAmt) {
        if (mode) withdrawWBTCETH(amount * 1e18 / getWBTCETHPoolInETH(), 0);
        else withdrawUSDCETH(amount * 1e18 / getUSDCETHPoolInETH(), 0);
        WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);
        emit Reimburse(WETHAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        if (mode) withdrawWBTCETH(1e18, 0);
        else withdrawUSDCETH(1e18, 0);
        uint WETHAmt = WETH.balanceOf(address(this));
        WETH.safeTransfer(vault, WETHAmt);
        watermark = 0;
        emit EmergencyWithdraw(WETHAmt);
    }

    function swap2(address from, address to, uint amount, uint amountOutMin) private returns (uint) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        return router.swapExactTokensForTokens(amount, amountOutMin, path, address(this), block.timestamp)[1];
    }

    function swap3(address from, address to, uint amount, uint amountOutMin) private returns (uint) {
        address[] memory path = new address[](3);
        path[0] = from;
        path[1] = address(WETH);
        path[2] = to;
        return router.swapExactTokensForTokens(amount, amountOutMin, path, address(this), block.timestamp)[2];
    }

    function setVault(address _vault) external {
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

    function getWBTCETHPoolInETH() private view returns (uint) {
        uint WBTCETHVaultPool = WBTCETHVault.getAllPoolInETH();
        if (WBTCETHVaultPool == 0) return 0;
        return WBTCETHVaultPool * WBTCETHVault.balanceOf(address(this)) / WBTCETHVault.totalSupply();
    }

    function getUSDCETHPoolInETH() private view returns (uint) {
        uint USDCETHVaultPool = USDCETHVault.getAllPoolInETH();
        if (USDCETHVaultPool == 0) return 0;
        return USDCETHVaultPool * USDCETHVault.balanceOf(address(this)) / USDCETHVault.totalSupply();
    }

    /// @notice This function return only farms TVL in ETH
    function getAllPoolInETH() public view returns (uint) {
        if (mode) return getWBTCETHPoolInETH(); // Attack
        else return getUSDCETHPoolInETH(); // Defence
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint ETHPriceInUSD = uint(IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer()); // 8 decimals
        require(ETHPriceInUSD > 0, "ChainLink error");
        return getAllPoolInETH() * ETHPriceInUSD / 1e8;
    }
}
