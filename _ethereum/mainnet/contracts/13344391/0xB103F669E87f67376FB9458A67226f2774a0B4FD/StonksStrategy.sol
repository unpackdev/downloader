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

interface IDaoL1Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external returns (uint);
    function getAllPoolInUSD() external view returns (uint);
    function getAllPoolInETH() external view returns (uint);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract StonksStrategy is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable constant UST = IERC20Upgradeable(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);
    IERC20Upgradeable constant mMSFT = IERC20Upgradeable(0x41BbEDd7286dAab5910a1f15d12CBda839852BD7);
    IERC20Upgradeable constant mTWTR = IERC20Upgradeable(0xEdb0414627E6f1e3F082DE65cD4F9C693D78CCA9);
    IERC20Upgradeable constant mTSLA = IERC20Upgradeable(0x21cA39943E91d704678F5D00b6616650F066fD63);
    IERC20Upgradeable constant mGOOGL = IERC20Upgradeable(0x59A921Db27Dd6d4d974745B7FfC5c33932653442);
    IERC20Upgradeable constant mAMZN = IERC20Upgradeable(0x0cae9e4d663793c2a2A0b211c1Cf4bBca2B9cAa7);
    IERC20Upgradeable constant mAAPL = IERC20Upgradeable(0xd36932143F6eBDEDD872D5Fb0651f4B72Fd15a84);
    IERC20Upgradeable constant mNFLX = IERC20Upgradeable(0xC8d674114bac90148d11D3C1d33C61835a0F9DCD);

    IERC20Upgradeable constant mMSFTUST = IERC20Upgradeable(0xeAfAD3065de347b910bb88f09A5abE580a09D655);
    IERC20Upgradeable constant mTWTRUST = IERC20Upgradeable(0x34856be886A2dBa5F7c38c4df7FD86869aB08040);
    IERC20Upgradeable constant mTSLAUST = IERC20Upgradeable(0x5233349957586A8207c52693A959483F9aeAA50C);
    IERC20Upgradeable constant mGOOGLUST = IERC20Upgradeable(0x4b70ccD1Cf9905BE1FaEd025EADbD3Ab124efe9a);
    IERC20Upgradeable constant mAMZNUST = IERC20Upgradeable(0x0Ae8cB1f57e3b1b7f4f5048743710084AA69E796);
    IERC20Upgradeable constant mAAPLUST = IERC20Upgradeable(0xB022e08aDc8bA2dE6bA4fECb59C6D502f66e953B);
    IERC20Upgradeable constant mNFLXUST = IERC20Upgradeable(0xC99A74145682C4b4A6e9fa55d559eb49A6884F75);

    IRouter constant uniRouter = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IDaoL1Vault public mMSFTUSTVault;
    IDaoL1Vault public mTWTRUSTVault;
    IDaoL1Vault public mTSLAUSTVault;
    IDaoL1Vault public mGOOGLUSTVault;
    IDaoL1Vault public mAMZNUSTVault;
    IDaoL1Vault public mAAPLUSTVault;
    IDaoL1Vault public mNFLXUSTVault;

    address public vault;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;

    event TargetComposition (uint targetPool);
    event CurrentComposition (
        uint mMSFTUSTCurrentPool, uint mTWTRUSTCurrentPool, uint mTSLAUSTCurrentPool, uint mGOOGLUSTCurrentPool,
        uint mAMZNUSTCurrentPool, uint mAAPLUSTCurrentPool, uint mNFLXUSTCurrentPool
    );
    event InvestMMSFTUST(uint USTAmtIn, uint mMSFTUSTAmt);
    event InvestMTWTRUST(uint USTAmtIn, uint mTWTRUSTAmt);
    event InvestMTSLAUST(uint USTAmtIn, uint mTSLAUSTAmt);
    event InvestMGOOGLUST(uint USTAmtIn, uint mGOOGLUSTAmt);
    event InvestMAMZNUST(uint USTAmtIn, uint mAMZNUSTAmt);
    event InvestMAAPLUST(uint USTAmtIn, uint mAAPLUSTAmt);
    event InvestMNFLXUST(uint USTAmtIn, uint mNFLXUSTAmt);
    event Withdraw(uint amtWithdraw, uint USTAmtOut);
    event WithdrawMMSFTUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMTWTRUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMTSLAUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMGOOGLUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMAMZNUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMAAPLUST(uint lpTokenAmt, uint USTAmt);
    event WithdrawMNFLXUST(uint lpTokenAmt, uint USTAmt);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event Reimburse(uint USTAmt);
    event EmergencyWithdraw(uint USTAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(
        IDaoL1Vault _mMSFTUSTVault,
        IDaoL1Vault _mTWTRUSTVault,
        IDaoL1Vault _mTSLAUSTVault,
        IDaoL1Vault _mGOOGLUSTVault,
        IDaoL1Vault _mAMZNUSTVault,
        IDaoL1Vault _mAAPLUSTVault,
        IDaoL1Vault _mNFLXUSTVault
    ) external initializer {
        __Ownable_init();

        mMSFTUSTVault = _mMSFTUSTVault;
        mTWTRUSTVault = _mTWTRUSTVault;
        mTSLAUSTVault = _mTSLAUSTVault;
        mGOOGLUSTVault = _mGOOGLUSTVault;
        mAMZNUSTVault = _mAMZNUSTVault;
        mAAPLUSTVault = _mAAPLUSTVault;
        mNFLXUSTVault = _mNFLXUSTVault;

        profitFeePerc = 2000;

        UST.safeApprove(address(uniRouter), type(uint).max);
        mMSFT.safeApprove(address(uniRouter), type(uint).max);
        mTWTR.safeApprove(address(uniRouter), type(uint).max);
        mTSLA.safeApprove(address(uniRouter), type(uint).max);
        mGOOGL.safeApprove(address(uniRouter), type(uint).max);
        mAMZN.safeApprove(address(uniRouter), type(uint).max);
        mAAPL.safeApprove(address(uniRouter), type(uint).max);
        mNFLX.safeApprove(address(uniRouter), type(uint).max);

        mMSFTUST.safeApprove(address(mMSFTUSTVault), type(uint).max);
        mMSFTUST.safeApprove(address(uniRouter), type(uint).max);
        mTWTRUST.safeApprove(address(mTWTRUSTVault), type(uint).max);
        mTWTRUST.safeApprove(address(uniRouter), type(uint).max);
        mTSLAUST.safeApprove(address(mTSLAUSTVault), type(uint).max);
        mTSLAUST.safeApprove(address(uniRouter), type(uint).max);
        mGOOGLUST.safeApprove(address(mGOOGLUSTVault), type(uint).max);
        mGOOGLUST.safeApprove(address(uniRouter), type(uint).max);
        mAMZNUST.safeApprove(address(mAMZNUSTVault), type(uint).max);
        mAMZNUST.safeApprove(address(uniRouter), type(uint).max);
        mAAPLUST.safeApprove(address(mAAPLUSTVault), type(uint).max);
        mAAPLUST.safeApprove(address(uniRouter), type(uint).max);
        mNFLXUST.safeApprove(address(mNFLXUSTVault), type(uint).max);
        mNFLXUST.safeApprove(address(uniRouter), type(uint).max);
    }

    function invest(uint USTAmt) external onlyVault {
        UST.safeTransferFrom(vault, address(this), USTAmt);

        uint[] memory pools = getEachPoolInUSD();
        uint pool = pools[0] + pools[1] + pools[2] + pools[3] + pools[4] + pools[5] + pools[6] + USTAmt;
        uint targetPool = pool / 7;

        // Rebalancing invest
        if (
            targetPool > pools[0] &&
            targetPool > pools[1] &&
            targetPool > pools[2] &&
            targetPool > pools[3] &&
            targetPool > pools[4] &&
            targetPool > pools[5] &&
            targetPool > pools[6]
        ) {
            investMMSFTUST(targetPool - pools[0]);
            investMTWTRUST(targetPool - pools[1]);
            investMTSLAUST(targetPool - pools[2]);
            investMGOOGLUST(targetPool - pools[3]);
            investMAMZNUST(targetPool - pools[4]);
            investMAAPLUST(targetPool - pools[5]);
            investMNFLXUST(targetPool - pools[6]);
        } else {
            uint furthest;
            uint farmIndex;
            uint diff;

            if (targetPool > pools[0]) {
                diff = targetPool - pools[0];
                furthest = diff;
                farmIndex = 0;
            }
            if (targetPool > pools[1]) {
                diff = targetPool - pools[1];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 1;
                }
            }
            if (targetPool > pools[2]) {
                diff = targetPool - pools[2];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 2;
                }
            }
            if (targetPool > pools[3]) {
                diff = targetPool - pools[3];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 3;
                }
            }
            if (targetPool > pools[4]) {
                diff = targetPool - pools[4];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 4;
                }
            }
            if (targetPool > pools[5]) {
                diff = targetPool - pools[5];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 5;
                }
            }
            if (targetPool > pools[6]) {
                diff = targetPool - pools[6];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 6;
                }
            }

            if (farmIndex == 0) investMMSFTUST(USTAmt);
            else if (farmIndex == 1) investMTWTRUST(USTAmt);
            else if (farmIndex == 2) investMTSLAUST(USTAmt);
            else if (farmIndex == 3) investMGOOGLUST(USTAmt);
            else if (farmIndex == 4) investMAMZNUST(USTAmt);
            else if (farmIndex == 5) investMNFLXUST(USTAmt);
            else investMNFLXUST(USTAmt);
        }

        emit TargetComposition(targetPool);
        emit CurrentComposition(pools[0], pools[1], pools[2], pools[3], pools[4], pools[5], pools[6]);
    }

    function investMMSFTUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mMSFTAmt = swap(address(UST), address(mMSFT), halfUST, 0);
        (,,uint mMSFTUSTAmt) = uniRouter.addLiquidity(address(mMSFT), address(UST), mMSFTAmt, halfUST, 0, 0, address(this), block.timestamp);
        mMSFTUSTVault.deposit(mMSFTUSTAmt);
        emit InvestMMSFTUST(USTAmt, mMSFTUSTAmt);
    }

    function investMTWTRUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mTWTRAmt = swap(address(UST), address(mTWTR), halfUST, 0);
        (,,uint mTWTRUSTAmt) = uniRouter.addLiquidity(address(mTWTR), address(UST), mTWTRAmt, halfUST, 0, 0, address(this), block.timestamp);
        mTWTRUSTVault.deposit(mTWTRUSTAmt);
        emit InvestMTWTRUST(USTAmt, mTWTRUSTAmt);
    }

    function investMTSLAUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mTSLAAmt = swap(address(UST), address(mTSLA), halfUST, 0);
        (,,uint mTSLAUSTAmt) = uniRouter.addLiquidity(address(mTSLA), address(UST), mTSLAAmt, halfUST, 0, 0, address(this), block.timestamp);
        mTSLAUSTVault.deposit(mTSLAUSTAmt);
        emit InvestMTSLAUST(USTAmt, mTSLAUSTAmt);
    }

    function investMGOOGLUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mGOOGLAmt = swap(address(UST), address(mGOOGL), halfUST, 0);
        (,,uint mGOOGLUSTAmt) = uniRouter.addLiquidity(address(mGOOGL), address(UST), mGOOGLAmt, halfUST, 0, 0, address(this), block.timestamp);
        mGOOGLUSTVault.deposit(mGOOGLUSTAmt);
        emit InvestMGOOGLUST(USTAmt, mGOOGLUSTAmt);
    }

    function investMAMZNUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mAMZNAmt = swap(address(UST), address(mAMZN), halfUST, 0);
        (,,uint mAMZNUSTAmt) = uniRouter.addLiquidity(address(mAMZN), address(UST), mAMZNAmt, halfUST, 0, 0, address(this), block.timestamp);
        mAMZNUSTVault.deposit(mAMZNUSTAmt);
        emit InvestMAMZNUST(USTAmt, mAMZNUSTAmt);
    }

    function investMAAPLUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mAAPLAmt = swap(address(UST), address(mAAPL), halfUST, 0);
        (,,uint mAAPLUSTAmt) = uniRouter.addLiquidity(address(mAAPL), address(UST), mAAPLAmt, halfUST, 0, 0, address(this), block.timestamp);
        mAAPLUSTVault.deposit(mAAPLUSTAmt);
        emit InvestMAAPLUST(USTAmt, mAAPLUSTAmt);
    }

    function investMNFLXUST(uint USTAmt) private {
        uint halfUST = USTAmt / 2;
        uint mNFLXAmt = swap(address(UST), address(mNFLX), halfUST, 0);
        (,,uint mNFLXUSTAmt) = uniRouter.addLiquidity(address(mNFLX), address(UST), mNFLXAmt, halfUST, 0, 0, address(this), block.timestamp);
        mNFLXUSTVault.deposit(mNFLXUSTAmt);
        emit InvestMNFLXUST(USTAmt, mNFLXUSTAmt);
    }

    /// @param amount Amount to withdraw in USD
    function withdraw(uint amount, uint[] calldata tokenPrice) external onlyVault returns (uint USTAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD();
        uint USTAmtBefore = UST.balanceOf(address(this));
        withdrawMMSFTUST(sharePerc, tokenPrice[0]);
        withdrawMTWTRUST(sharePerc, tokenPrice[1]);
        withdrawMTSLAUST(sharePerc, tokenPrice[2]);
        withdrawMGOOGLUST(sharePerc, tokenPrice[3]);
        withdrawMAMZNUST(sharePerc, tokenPrice[4]);
        withdrawMAAPLUST(sharePerc, tokenPrice[5]);
        withdrawMNFLXUST(sharePerc, tokenPrice[6]);
        USTAmt = UST.balanceOf(address(this)) - USTAmtBefore;
        UST.safeTransfer(vault, USTAmt);
        emit Withdraw(amount, USTAmt);
    }

    function withdrawMMSFTUST(uint sharePerc, uint mMSFTPrice) private {
        uint mMSFTUSTAmt = mMSFTUSTVault.withdraw(mMSFTUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mMSFTAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mMSFT), address(UST), mMSFTUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mMSFT), address(UST), mMSFTAmt, mMSFTAmt * mMSFTPrice / 1e18);
        emit WithdrawMMSFTUST(mMSFTUSTAmt, USTAmt + _USTAmt);
    }
    
    function withdrawMTWTRUST(uint sharePerc, uint mTWTRPrice) private {
        uint mTWTRUSTAmt = mTWTRUSTVault.withdraw(mTWTRUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mTWTRAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mTWTR), address(UST), mTWTRUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mTWTR), address(UST), mTWTRAmt, mTWTRAmt * mTWTRPrice / 1e18);
        emit WithdrawMTWTRUST(mTWTRUSTAmt, USTAmt + _USTAmt);
    }

    function withdrawMTSLAUST(uint sharePerc, uint mTSLAPrice) private {
        uint mTSLAUSTAmt = mTSLAUSTVault.withdraw(mTSLAUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mTSLAAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mTSLA), address(UST), mTSLAUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mTSLA), address(UST), mTSLAAmt, mTSLAAmt * mTSLAPrice / 1e18);
        emit WithdrawMTSLAUST(mTSLAUSTAmt, USTAmt + _USTAmt);
    }

    function withdrawMGOOGLUST(uint sharePerc, uint mGOOGLPrice) private {
        uint mGOOGLUSTAmt = mGOOGLUSTVault.withdraw(mGOOGLUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mGOOGLAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mGOOGL), address(UST), mGOOGLUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mGOOGL), address(UST), mGOOGLAmt, mGOOGLAmt * mGOOGLPrice / 1e18);
        emit WithdrawMGOOGLUST(mGOOGLUSTAmt, USTAmt + _USTAmt);
    }

    function withdrawMAMZNUST(uint sharePerc, uint mAMZNPrice) private {
        uint mAMZNUSTAmt = mAMZNUSTVault.withdraw(mAMZNUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mAMZNAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mAMZN), address(UST), mAMZNUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mAMZN), address(UST), mAMZNAmt, mAMZNAmt * mAMZNPrice / 1e18);
        emit WithdrawMAMZNUST(mAMZNUSTAmt, USTAmt + _USTAmt);
    }

    function withdrawMAAPLUST(uint sharePerc, uint mAAPLPrice) private {
        uint mAAPLUSTAmt = mAAPLUSTVault.withdraw(mAAPLUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mAAPLAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mAAPL), address(UST), mAAPLUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mAAPL), address(UST), mAAPLAmt, mAAPLAmt * mAAPLPrice / 1e18);
        emit WithdrawMAAPLUST(mAAPLUSTAmt, USTAmt + _USTAmt);
    }

    function withdrawMNFLXUST(uint sharePerc, uint mNFLXPrice) private {
        uint mNFLXUSTAmt = mNFLXUSTVault.withdraw(mNFLXUSTVault.balanceOf(address(this)) * sharePerc / 1e18);
        (uint mNFLXAmt, uint USTAmt) = uniRouter.removeLiquidity(address(mNFLX), address(UST), mNFLXUSTAmt, 0, 0, address(this), block.timestamp);
        uint _USTAmt = swap(address(mNFLX), address(UST), mNFLXAmt, mNFLXAmt * mNFLXPrice / 1e18);
        emit WithdrawMNFLXUST(mNFLXUSTAmt, USTAmt + _USTAmt);
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

    /// @param amount Amount to reimburse to vault contract in USD
    function reimburse(uint farmIndex, uint amount) external onlyVault returns (uint USTAmt) {
        if (farmIndex == 0) withdrawMMSFTUST(amount * 1e18 / getMMSFTUSTPoolInUSD(), 0);
        else if (farmIndex == 1) withdrawMTWTRUST(amount * 1e18 / getMTWTRUSTPoolInUSD(), 0);
        else if (farmIndex == 2) withdrawMTSLAUST(amount * 1e18 / getMTSLAUSTPoolInUSD(), 0);
        else if (farmIndex == 3) withdrawMGOOGLUST(amount * 1e18 / getMGOOGLUSTPoolInUSD(), 0);
        else if (farmIndex == 4) withdrawMAMZNUST(amount * 1e18 / getMAMZNUSTPoolInUSD(), 0);
        else if (farmIndex == 5) withdrawMAAPLUST(amount * 1e18 / getMAAPLUSTPoolInUSD(), 0);
        else if (farmIndex == 6) withdrawMNFLXUST(amount * 1e18 / getMNFLXUSTPoolInUSD(), 0);
        USTAmt = UST.balanceOf(address(this));
        UST.safeTransfer(vault, USTAmt);
        emit Reimburse(USTAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        withdrawMMSFTUST(1e18, 0);
        withdrawMTWTRUST(1e18, 0);
        withdrawMTSLAUST(1e18, 0);
        withdrawMGOOGLUST(1e18, 0);
        withdrawMAMZNUST(1e18, 0);
        withdrawMAAPLUST(1e18, 0);
        withdrawMNFLXUST(1e18, 0);
        uint USTAmt = UST.balanceOf(address(this));
        UST.safeTransfer(vault, USTAmt);
        watermark = 0;

        emit EmergencyWithdraw(USTAmt);
    }

    function swap(address from, address to, uint amount, uint amountOutMin) private returns (uint) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        return uniRouter.swapExactTokensForTokens(amount, amountOutMin, path, address(this), block.timestamp)[1];
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

    function getMMSFTUSTPoolInUSD() private view returns (uint) {
        uint mMSFTUSTVaultPool = mMSFTUSTVault.getAllPoolInUSD();
        if (mMSFTUSTVaultPool == 0) return 0;
        return mMSFTUSTVaultPool * mMSFTUSTVault.balanceOf(address(this)) / mMSFTUSTVault.totalSupply();
    }

    function getMTWTRUSTPoolInUSD() private view returns (uint) {
        uint mTWTRUSTVaultPool = mTWTRUSTVault.getAllPoolInUSD();
        if (mTWTRUSTVaultPool == 0) return 0;
        return mTWTRUSTVaultPool * mTWTRUSTVault.balanceOf(address(this)) / mTWTRUSTVault.totalSupply();
    }

    function getMTSLAUSTPoolInUSD() private view returns (uint) {
        uint mTSLAUSTVaultPool = mTSLAUSTVault.getAllPoolInUSD();
        if (mTSLAUSTVaultPool == 0) return 0;
        return mTSLAUSTVaultPool * mTSLAUSTVault.balanceOf(address(this)) / mTSLAUSTVault.totalSupply();
    }

    function getMGOOGLUSTPoolInUSD() private view returns (uint) {
        uint mGOOGLUSTVaultPool = mGOOGLUSTVault.getAllPoolInUSD();
        if (mGOOGLUSTVaultPool == 0) return 0;
        return mGOOGLUSTVaultPool * mGOOGLUSTVault.balanceOf(address(this)) / mGOOGLUSTVault.totalSupply();
    }

    function getMAMZNUSTPoolInUSD() private view returns (uint) {
        uint mAMZNUSTVaultPool = mAMZNUSTVault.getAllPoolInUSD();
        if (mAMZNUSTVaultPool == 0) return 0;
        return mAMZNUSTVaultPool * mAMZNUSTVault.balanceOf(address(this)) / mAMZNUSTVault.totalSupply();
    }

    function getMAAPLUSTPoolInUSD() private view returns (uint) {
        uint mAAPLUSTVaultPool = mAAPLUSTVault.getAllPoolInUSD();
        if (mAAPLUSTVaultPool == 0) return 0;
        return mAAPLUSTVaultPool * mAAPLUSTVault.balanceOf(address(this)) / mAAPLUSTVault.totalSupply();
    }

    function getMNFLXUSTPoolInUSD() private view returns (uint) {
        uint mNFLXUSTVaultPool = mNFLXUSTVault.getAllPoolInUSD();
        if (mNFLXUSTVaultPool == 0) return 0;
        return mNFLXUSTVaultPool * mNFLXUSTVault.balanceOf(address(this)) / mNFLXUSTVault.totalSupply();
    }

    function getEachPoolInUSD() private view returns (uint[] memory pools) {
        pools = new uint[](7);
        pools[0] = getMMSFTUSTPoolInUSD();
        pools[1] = getMTWTRUSTPoolInUSD();
        pools[2] = getMTSLAUSTPoolInUSD();
        pools[3] = getMGOOGLUSTPoolInUSD();
        pools[4] = getMAMZNUSTPoolInUSD();
        pools[5] = getMAAPLUSTPoolInUSD();
        pools[6] = getMNFLXUSTPoolInUSD();
    }

    /// @notice This function return only farms TVL in ETH
    function getAllPoolInETH() public view returns (uint) {
        uint USTPriceInETH = uint(IChainlink(0xa20623070413d42a5C01Db2c8111640DD7A5A03a).latestAnswer());
        require(USTPriceInETH > 0, "ChainLink error");
        return getAllPoolInUSD() * USTPriceInETH / 1e18;
    }

    /// @notice This function return only farms TVL in USD
    function getAllPoolInUSD() public view returns (uint) {
        uint[] memory pools = getEachPoolInUSD();
        return pools[0] + pools[1] + pools[2] + pools[3] + pools[4] + pools[5] + pools[6];
    }

    function getCurrentCompositionPerc() external view returns (uint[] memory percentages) {
        uint[] memory pools = getEachPoolInUSD();
        uint allPool = getAllPoolInUSD();
        percentages = new uint[](7);
        percentages[0] = pools[0] * 10000 / allPool;
        percentages[1] = pools[1] * 10000 / allPool;
        percentages[2] = pools[2] * 10000 / allPool;
        percentages[3] = pools[3] * 10000 / allPool;
        percentages[4] = pools[4] * 10000 / allPool;
        percentages[5] = pools[5] * 10000 / allPool;
        percentages[6] = pools[6] * 10000 / allPool;
    }
}
