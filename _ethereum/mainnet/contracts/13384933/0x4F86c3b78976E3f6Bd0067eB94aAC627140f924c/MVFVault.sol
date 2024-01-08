// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./BaseRelayRecipient.sol";

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface ICurve {
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external;
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

interface IStrategy {
    function invest(uint amount) external;
    function withdraw(uint sharePerc, uint[] calldata tokenPrice) external;
    function collectProfitAndUpdateWatermark() external returns (uint);
    function adjustWatermark(uint amount, bool signs) external; 
    function reimburse(uint farmIndex, uint sharePerc) external returns (uint);
    function emergencyWithdraw() external;
    function profitFeePerc() external view returns (uint);
    function setProfitFeePerc(uint profitFeePerc) external;
    function watermark() external view returns (uint);
    function getAllPool(bool includeVestedILV) external view returns (uint);
}

contract MVFVault is Initializable, ERC20Upgradeable, OwnableUpgradeable, 
        ReentrancyGuardUpgradeable, PausableUpgradeable, BaseRelayRecipient {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable constant USDT = IERC20Upgradeable(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20Upgradeable constant USDC = IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20Upgradeable constant DAI = IERC20Upgradeable(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20Upgradeable constant WETH = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IRouter constant sushiRouter = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    ICurve constant curve = ICurve(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7); // 3pool
    IStrategy public strategy;
    uint[] public percKeepInVault;
    uint public fees;

    uint[] public networkFeeTier2;
    uint public customNetworkFeeTier;
    uint[] public networkFeePerc;
    uint public customNetworkFeePerc;

    // Temporarily variable for LP token distribution only
    address[] addresses;
    mapping(address => uint) public depositAmt; // Amount in USD (18 decimals)
    uint totalDepositAmt;

    address public treasuryWallet;
    address public communityWallet;
    address public strategist;
    address public admin;

    event Deposit(address caller, uint amtDeposit, address tokenDeposit);
    event Withdraw(address caller, uint amtWithdraw, address tokenWithdraw, uint shareBurned);
    event Invest(uint amount);
    event DistributeLPToken(address receiver, uint shareMinted);
    event TransferredOutFees(uint fees, address token);
    event Reimburse(uint farmIndex, address token, uint amount);
    event Reinvest(uint amount);
    event SetNetworkFeeTier2(uint[] oldNetworkFeeTier2, uint[] newNetworkFeeTier2);
    event SetCustomNetworkFeeTier(uint oldCustomNetworkFeeTier, uint newCustomNetworkFeeTier);
    event SetNetworkFeePerc(uint[] oldNetworkFeePerc, uint[] newNetworkFeePerc);
    event SetCustomNetworkFeePerc(uint oldCustomNetworkFeePerc, uint newCustomNetworkFeePerc);
    event SetProfitFeePerc(uint oldProfitFeePerc, uint newProfitFeePerc);
    event SetPercKeepInVault(uint[] oldPercKeepInVault, uint[] newPercKeepInVault);
    event SetTreasuryWallet(address oldTreasuryWallet, address newTreasuryWallet);
    event SetCommunityWallet(address oldCommunityWallet, address newCommunityWallet);
    event SetStrategistWallet(address oldStrategistWallet, address newStrategistWallet);
    event SetAdminWallet(address oldAdmin, address newAdmin);
    event SetBiconomy(address oldBiconomy, address newBiconomy);
    
    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner() || msg.sender == address(admin), "Only owner or admin");
        _;
    }

    function initialize(
        string calldata name, string calldata ticker,
        address _treasuryWallet, address _communityWallet, address _strategist, address _admin,
        address _biconomy, address _strategy
    ) external initializer {
        __ERC20_init(name, ticker);
        __Ownable_init();

        strategy = IStrategy(_strategy);

        treasuryWallet = _treasuryWallet;
        communityWallet = _communityWallet;
        admin = _admin;
        strategist = _strategist;
        trustedForwarder = _biconomy;

        networkFeeTier2 = [50000*1e18+1, 100000*1e18];
        customNetworkFeeTier = 1000000*1e18;
        networkFeePerc = [100, 75, 50];
        customNetworkFeePerc = 25;

        percKeepInVault = [300, 300, 300]; // USDT, USDC, DAI

        USDT.safeApprove(address(sushiRouter), type(uint).max);
        USDC.safeApprove(address(sushiRouter), type(uint).max);
        DAI.safeApprove(address(sushiRouter), type(uint).max);
        WETH.safeApprove(address(sushiRouter), type(uint).max);
        WETH.safeApprove(address(strategy), type(uint).max);
    }

    function approveCurve() external {
        USDT.safeApprove(address(curve), type(uint).max);
        USDC.safeApprove(address(curve), type(uint).max);
        DAI.safeApprove(address(curve), type(uint).max);
    }

    function deposit(uint amount, IERC20Upgradeable token) external nonReentrant whenNotPaused {
        require(msg.sender == tx.origin || isTrustedForwarder(msg.sender), "Only EOA or Biconomy");
        require(amount > 0, "Amount must > 0");
        require(token == USDT || token == USDC || token == DAI, "Invalid token deposit");

        address msgSender = _msgSender();
        token.safeTransferFrom(msgSender, address(this), amount);
        if (token != DAI) amount *= 1e12;
        uint amtDeposit = amount;

        uint _networkFeePerc;
        if (amount < networkFeeTier2[0]) _networkFeePerc = networkFeePerc[0]; // Tier 1
        else if (amount <= networkFeeTier2[1]) _networkFeePerc = networkFeePerc[1]; // Tier 2
        else if (amount < customNetworkFeeTier) _networkFeePerc = networkFeePerc[2]; // Tier 3
        else _networkFeePerc = customNetworkFeePerc; // Custom Tier
        uint fee = amount * _networkFeePerc / 10000;
        fees += fee;
        amount -= fee;

        if (depositAmt[msgSender] == 0) {
            addresses.push(msgSender);
            depositAmt[msgSender] = amount;
        } else depositAmt[msgSender] += amount;
        totalDepositAmt += amount;

        emit Deposit(msgSender, amtDeposit, address(token));
    }

    function withdraw(uint share, IERC20Upgradeable token, uint[] calldata tokenPrice) external nonReentrant {
        require(msg.sender == tx.origin, "Only EOA");
        require(share > 0 || share <= balanceOf(msg.sender), "Invalid share amount");
        require(token == USDT || token == USDC || token == DAI, "Invalid token withdraw");

        uint _totalSupply = totalSupply();
        uint withdrawAmt = (getAllPoolInUSD(false) - totalDepositAmt) * share / _totalSupply;
        _burn(msg.sender, share);

        uint tokenAmtInVault = token.balanceOf(address(this));
        if (token != DAI) tokenAmtInVault *= 1e12;
        if (withdrawAmt < tokenAmtInVault) {
            // Enough token in vault to withdraw
            if (token != DAI) withdrawAmt /= 1e12;
            token.safeTransfer(msg.sender, withdrawAmt);
        } else {
            // Not enough token in vault to withdraw, try if enough if swap from other token in vault
            (address token1, uint token1AmtInVault, address token2, uint token2AmtInVault) = getOtherTokenAndBal(token);
            if (withdrawAmt < tokenAmtInVault + token1AmtInVault) {
                // Enough if swap from token1 in vault
                uint amtSwapFromToken1 = withdrawAmt - tokenAmtInVault;
                if (token1 != address(DAI)) amtSwapFromToken1 /= 1e12;
                curve.exchange(getCurveId(token1), getCurveId(address(token)), amtSwapFromToken1, amtSwapFromToken1 * 99 / 100);
                withdrawAmt = token.balanceOf(address(this));
                token.safeTransfer(msg.sender, withdrawAmt);
            } else if (withdrawAmt < tokenAmtInVault + token1AmtInVault + token2AmtInVault) {
                // Not enough if swap from token1 in vault but enough if swap from token1 + token2 in vault
                uint amtSwapFromToken2 = withdrawAmt - tokenAmtInVault - token1AmtInVault;
                if (token1AmtInVault > 0) {
                    if (token1 != address(DAI)) token1AmtInVault /= 1e12;
                    curve.exchange(getCurveId(token1), getCurveId(address(token)), token1AmtInVault, token1AmtInVault * 99 / 100);
                }
                if (token2AmtInVault > 0) {
                    uint minAmtOutToken2 = amtSwapFromToken2 * 99 / 100;
                    if (token2 != address(DAI)) amtSwapFromToken2 /= 1e12;
                    if (token != DAI) minAmtOutToken2 /= 1e12;
                    curve.exchange(getCurveId(token2), getCurveId(address(token)), amtSwapFromToken2, minAmtOutToken2);
                }
                withdrawAmt = token.balanceOf(address(this));
                token.safeTransfer(msg.sender, withdrawAmt);
            } else {
                // Not enough if swap from token1 + token2 in vault, need to withdraw from strategy
                if (!paused()) {
                    withdrawAmt = withdrawFromStrategy(token, withdrawAmt, tokenAmtInVault, tokenPrice);
                } else {
                    withdrawAmt = withdrawWhenPaused(token, share, _totalSupply, tokenPrice);
                }
            }
        }

        emit Withdraw(msg.sender, withdrawAmt, address(token), share);
    }

    function withdrawFromStrategy(
        IERC20Upgradeable token, uint withdrawAmt, uint tokenAmtInVault, uint[] calldata tokenPrice
    ) private returns (uint) {
        strategy.withdraw(withdrawAmt - tokenAmtInVault, tokenPrice);
        strategy.adjustWatermark(withdrawAmt - tokenAmtInVault, false);
        if (token != DAI) tokenAmtInVault /= 1e12;
        uint WETHAmt = WETH.balanceOf(address(this));
        uint amountOutMin = WETHAmt * tokenPrice[0] / 1e18;
        withdrawAmt = (sushiRouter.swapExactTokensForTokens(
            WETHAmt, amountOutMin, getPath(address(WETH), address(token)), address(this), block.timestamp
        )[1]) + tokenAmtInVault;
        token.safeTransfer(msg.sender, withdrawAmt);
        return withdrawAmt;
    }

    function withdrawWhenPaused(
        IERC20Upgradeable token, uint share, uint _totalSupply, uint[] calldata tokenPrice
    ) private returns (uint withdrawAmt) {
        uint WETHAmt = WETH.balanceOf(address(this));
        uint amountOutMin = WETHAmt * tokenPrice[0] / 1e18;
        withdrawAmt = (sushiRouter.swapExactTokensForTokens(
            WETHAmt * share / _totalSupply, amountOutMin, getPath(address(WETH), address(token)), msg.sender, block.timestamp
        ))[1];
    }

    function invest() public whenNotPaused {
        require(
            msg.sender == admin ||
            msg.sender == owner() ||
            msg.sender == address(this), "Only authorized caller"
        );

        if (strategy.watermark() > 0) collectProfitAndUpdateWatermark();
        (uint USDTAmt, uint USDCAmt, uint DAIAmt) = transferOutFees();

        (uint WETHAmt, uint tokenAmtToInvest, uint pool) = swapTokenToWETH(USDTAmt, USDCAmt, DAIAmt);
        strategy.invest(WETHAmt);
        strategy.adjustWatermark(tokenAmtToInvest, true);
        distributeLPToken(pool);

        emit Invest(WETHAmt);
    }

    function collectProfitAndUpdateWatermark() public whenNotPaused {
        require(
            msg.sender == address(this) ||
            msg.sender == admin ||
            msg.sender == owner(), "Only authorized caller"
        );
        uint fee = strategy.collectProfitAndUpdateWatermark();
        if (fee > 0) fees = fees + fee;
    }

    function distributeLPToken(uint pool) private {
        if (totalSupply() != 0) pool -= totalDepositAmt;
        address[] memory _addresses = addresses;
        for (uint i; i < _addresses.length; i ++) {
            address depositAcc = _addresses[i];
            uint _depositAmt = depositAmt[depositAcc];
            uint _totalSupply = totalSupply();
            uint share = _totalSupply == 0 ? _depositAmt : _depositAmt * _totalSupply / pool;
            _mint(depositAcc, share);
            pool = pool + _depositAmt;
            depositAmt[depositAcc] = 0;
            emit DistributeLPToken(depositAcc, share);
        }
        delete addresses;
        totalDepositAmt = 0;
    }

    function transferOutFees() public returns (uint USDTAmt, uint USDCAmt, uint DAIAmt) {
        require(
            msg.sender == address(this) ||
            msg.sender == admin ||
            msg.sender == owner(), "Only authorized caller"
        );

        USDTAmt = USDT.balanceOf(address(this));
        USDCAmt = USDC.balanceOf(address(this));
        DAIAmt = DAI.balanceOf(address(this));

        uint _fees = fees;
        if (_fees != 0) {
            IERC20Upgradeable token;
            if (USDTAmt * 1e12 > _fees) {
                token = USDT;
                _fees = _fees / 1e12;
                USDTAmt = USDTAmt - _fees;
            } else if (USDCAmt * 1e12 > _fees) {
                token = USDC;
                _fees = _fees / 1e12;
                USDCAmt = USDCAmt - _fees;
            } else if (DAIAmt > _fees) {
                token = DAI;
                DAIAmt = DAIAmt - _fees;
            } else return (USDTAmt, USDCAmt, DAIAmt);

            uint _fee = _fees * 2 / 5; // 40%
            token.safeTransfer(treasuryWallet, _fee); // 40%
            token.safeTransfer(communityWallet, _fee); // 40%
            token.safeTransfer(strategist, _fees - _fee - _fee); // 20%

            fees = 0;
            emit TransferredOutFees(_fees, address(token)); // Decimal follow _token
        }
    }

    function swapTokenToWETH(uint USDTAmt, uint USDCAmt, uint DAIAmt) private returns (uint WETHAmt, uint tokenAmtToInvest, uint pool) {
        uint[] memory _percKeepInVault = percKeepInVault;
        pool = getAllPoolInUSD(true);

        uint USDTAmtKeepInVault = calcTokenKeepInVault(_percKeepInVault[0], pool) / 1e12;
        if (USDTAmt > USDTAmtKeepInVault + 1e6) {
            USDTAmt = USDTAmt - USDTAmtKeepInVault;
            WETHAmt = sushiSwap(address(USDT), address(WETH), USDTAmt);
            tokenAmtToInvest = USDTAmt * 1e12;
        }

        uint USDCAmtKeepInVault = calcTokenKeepInVault(_percKeepInVault[1], pool) / 1e12;
        if (USDCAmt > USDCAmtKeepInVault + 1e6) {
            USDCAmt = USDCAmt - USDCAmtKeepInVault;
            uint _WETHAmt = sushiSwap(address(USDC), address(WETH), USDCAmt);
            WETHAmt = WETHAmt + _WETHAmt;
            tokenAmtToInvest = tokenAmtToInvest + USDCAmt * 1e12;
        }

        uint DAIAmtKeepInVault = calcTokenKeepInVault(_percKeepInVault[2], pool);
        if (DAIAmt > DAIAmtKeepInVault + 1e18) {
            DAIAmt = DAIAmt - DAIAmtKeepInVault;
            uint _WETHAmt = sushiSwap(address(DAI), address(WETH), DAIAmt);
            WETHAmt = WETHAmt + _WETHAmt;
            tokenAmtToInvest = tokenAmtToInvest + DAIAmt;
        }
    }

    function calcTokenKeepInVault(uint _percKeepInVault, uint pool) private pure returns (uint) {
        return pool * _percKeepInVault / 10000;
    }

    /// @param amount Amount to reimburse (decimal follow token)
    function reimburse(uint farmIndex, address token, uint amount) external onlyOwnerOrAdmin {
        uint WETHAmt;
        WETHAmt = sushiRouter.getAmountsOut(amount, getPath(token, address(WETH)))[1];
        WETHAmt = strategy.reimburse(farmIndex, WETHAmt);
        sushiSwap(address(WETH), token, WETHAmt);

        if (token != address(DAI)) amount *= 1e12;
        strategy.adjustWatermark(amount, false);

        emit Reimburse(farmIndex, token, amount);
    }

    function emergencyWithdraw() external onlyOwnerOrAdmin whenNotPaused {
        _pause();
        strategy.emergencyWithdraw();
    }

    function reinvest() external onlyOwnerOrAdmin whenPaused {
        _unpause();

        uint WETHAmt = WETH.balanceOf(address(this));
        strategy.invest(WETHAmt);
        uint ETHPriceInUSD = uint(IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer());
        require(ETHPriceInUSD > 0, "ChainLink error");
        strategy.adjustWatermark(WETHAmt * ETHPriceInUSD / 1e8, true);

        emit Reinvest(WETHAmt);
    }

    function sushiSwap(address from, address to, uint amount) private returns (uint) {
        return (sushiRouter.swapExactTokensForTokens(
            amount, 0, getPath(from, to), address(this), block.timestamp
        ))[1];
    }

    function setNetworkFeeTier2(uint[] calldata _networkFeeTier2) external onlyOwner {
        require(_networkFeeTier2[0] != 0, "Minimun amount cannot be 0");
        require(_networkFeeTier2[1] > _networkFeeTier2[0], "Maximun amount must > minimun amount");
        /**
         * Network fee has three tier, but it is sufficient to have minimun and maximun amount of tier 2
         * Tier 1: deposit amount < minimun amount of tier 2
         * Tier 2: minimun amount of tier 2 <= deposit amount <= maximun amount of tier 2
         * Tier 3: amount > maximun amount of tier 2
         */
        uint[] memory oldNetworkFeeTier2 = networkFeeTier2;
        networkFeeTier2 = _networkFeeTier2;
        emit SetNetworkFeeTier2(oldNetworkFeeTier2, _networkFeeTier2);
    }

    function setCustomNetworkFeeTier(uint _customNetworkFeeTier) external onlyOwner {
        require(_customNetworkFeeTier > networkFeeTier2[1], "Must > tier 2");
        uint oldCustomNetworkFeeTier = customNetworkFeeTier;
        customNetworkFeeTier = _customNetworkFeeTier;
        emit SetCustomNetworkFeeTier(oldCustomNetworkFeeTier, _customNetworkFeeTier);
    }

    function setNetworkFeePerc(uint[] calldata _networkFeePerc) external onlyOwner {
        require(_networkFeePerc[0] < 3001 && _networkFeePerc[1] < 3001 && _networkFeePerc[2] < 3001,
            "Not allow > 30%");
        /**
         * _networkFeePerc contains an array of 3 elements, representing network fee of tier 1, tier 2 and tier 3
         * For example networkFeePerc is [100, 75, 50],
         * which mean network fee for Tier 1 = 1%, Tier 2 = 0.75% and Tier 3 = 0.5% (Denominator = 10000)
         */
        uint[] memory oldNetworkFeePerc = networkFeePerc;
        networkFeePerc = _networkFeePerc;
        emit SetNetworkFeePerc(oldNetworkFeePerc, _networkFeePerc);
    }

    function setCustomNetworkFeePerc(uint _customNetworkFeePerc) external onlyOwner {
        require(_customNetworkFeePerc < networkFeePerc[2], "Not allow > tier 2");
        uint oldCustomNetworkFeePerc = customNetworkFeePerc;
        customNetworkFeePerc = _customNetworkFeePerc;
        emit SetCustomNetworkFeePerc(oldCustomNetworkFeePerc, _customNetworkFeePerc);
    }

    function setProfitFeePerc(uint profitFeePerc) external onlyOwner {
        require(profitFeePerc < 3001, "Profit fee cannot > 30%");
        uint oldProfitFeePerc = strategy.profitFeePerc();
        strategy.setProfitFeePerc(profitFeePerc);
        emit SetProfitFeePerc(oldProfitFeePerc, profitFeePerc);
    }

    function setPercKeepInVault(uint[] calldata _percKeepInVault) external onlyOwner {
        uint[] memory oldPercKeepInVault = percKeepInVault;
        percKeepInVault = _percKeepInVault;
        emit SetPercKeepInVault(oldPercKeepInVault, _percKeepInVault);
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        address oldTreasuryWallet = treasuryWallet;
        treasuryWallet = _treasuryWallet;
        emit SetTreasuryWallet(oldTreasuryWallet, _treasuryWallet);
    }

    function setCommunityWallet(address _communityWallet) external onlyOwner {
        address oldCommunityWallet = communityWallet;
        communityWallet = _communityWallet;
        emit SetCommunityWallet(oldCommunityWallet, _communityWallet);
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == strategist || msg.sender == owner(), "Only owner or strategist");
        address oldStrategist = strategist;
        strategist = _strategist;
        emit SetStrategistWallet(oldStrategist, _strategist);
    }

    function setAdmin(address _admin) external onlyOwner {
        address oldAdmin = admin;
        admin = _admin;
        emit SetAdminWallet(oldAdmin, _admin);
    }

    function setBiconomy(address _biconomy) external onlyOwner {
        address oldBiconomy = trustedForwarder;
        trustedForwarder = _biconomy;
        emit SetBiconomy(oldBiconomy, _biconomy);
    }

    function _msgSender() internal override(ContextUpgradeable, BaseRelayRecipient) view returns (address) {
        return BaseRelayRecipient._msgSender();
    }
    
    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    function getOtherTokenAndBal(IERC20Upgradeable token) private view returns (address token1, uint token1AmtInVault, address token2, uint token2AmtInVault) {
        if (token == USDT) {
            token1 = address(USDC);
            token1AmtInVault = USDC.balanceOf(address(this)) * 1e12;
            token2 = address(DAI);
            token2AmtInVault = DAI.balanceOf(address(this));
        } else if (token == USDC) {
            token1 = address(USDT);
            token1AmtInVault = USDT.balanceOf(address(this)) * 1e12;
            token2 = address(DAI);
            token2AmtInVault = DAI.balanceOf(address(this));
        } else {
            token1 = address(USDT);
            token1AmtInVault = USDT.balanceOf(address(this)) * 1e12;
            token2 = address(USDC);
            token2AmtInVault = USDC.balanceOf(address(this)) * 1e12;
        }
    }

    function getCurveId(address token) private pure returns (int128) {
        if (token == address(USDT)) return 2;
        else if (token == address(USDC)) return 1;
        else return 0; // DAI
    }

    function getPath(address tokenA, address tokenB) private pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
    }

    function getTotalPendingDeposits() external view returns (uint) {
        return addresses.length;
    }

    function getAllPoolInUSD(bool includeVestedILV) private view returns (uint) {
        // ETHPriceInUSD amount in 8 decimals
        uint ETHPriceInUSD = uint(IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer());
        require(ETHPriceInUSD > 0, "ChainLink error");

        uint tokenKeepInVault = USDT.balanceOf(address(this)) * 1e12 +
            USDC.balanceOf(address(this)) * 1e12 + DAI.balanceOf(address(this));

        if (paused()) return WETH.balanceOf(address(this)) * ETHPriceInUSD / 1e8 + tokenKeepInVault - fees;
        uint strategyPoolInUSD = strategy.getAllPool(includeVestedILV) * ETHPriceInUSD / 1e8;
        
        return strategyPoolInUSD + tokenKeepInVault - fees;
    }

    function getAllPoolInUSD() external view returns (uint) {
        return getAllPoolInUSD(true);
    }

    /// @notice Can be use for calculate both user shares & APR    
    function getPricePerFullShare() external view returns (uint) {
        return (getAllPoolInUSD(false) - totalDepositAmt) * 1e18 / totalSupply();
    }
}
