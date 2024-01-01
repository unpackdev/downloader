//                 #########    #########
//              ####+++++++#######++++++###
//             ##+++++++++++++###+++++++++##
//           ###++++#########################
//        #####+++##++++++########+++++++########
//     ####++#+##++++++###########################            .-''-.   _____     __  .-------.     .-''-.  .-------.     .-''-.
//    #++++##+++#++########+#################+#####         .'_ _   \  \   _\   /  / \  _(`)_ \  .'_ _   \ \  _(`)_ \  .'_ _   \
//     ####+-###++#############.    ##-##-##     +##       / ( ` )   ' .-./ ). /  '  | (_ o._)| / ( ` )   '| (_ o._)| / ( ` )   '
//      #++##++#+++++########+##   .########   .+#        . (_ o _)  | \ '_ .') .'   |  (_,_) /. (_ o _)  ||  (_,_) /. (_ o _)  |
//     ########++##++############################         |  (_,_)___|(_ (_) _) '    |   '-.-' |  (_,_)___||   '-.-' |  (_,_)___|
//    ##++++++++++++++++###########++++++++####           '  \   .---.  /    \   \   |   |     '  \   .---.|   |     '  \   .---.
//    #+++++++++++###++++++#####+++++++###++###            \  `-'    /  `-'`-'    \  |   |      \  `-'    /|   |      \  `-'    /
//   ##++++++++++######++++#++++++++++++++++++##            \       /  /  /   \    \ /   )       \       / /   )       \       /
//  ###++++++++++++#+++##++++++++++++++++++++++##            `'-..-'  '--'     '----'`---'        `'-..-'  `---'        `'-..-'
//  ###+++++++++++++#+-#++##++++++++++++++++++###
//  ###++++++++++++++##--#+--+##############---+#       EXPEPE.VIP EXPEPE.VIP EXPEPE.VIP EXPEPE.VIP EXPEPE.VIP EXPEPE.VIP EXPEPE.VIP
//  ###++++++++++++++++###+-##++++++++++++++####        EXPEPE.VIP EXPEPE.VIP EXPEPE.VIP EXPEPE.VIP EXPEPE.VIP EXPEPE.VIP EXPEPE.VIP
//   ##+++++++++++++++++++####+---+++++-----+###
//    ###++++++++++++++++++++++##############
//       #####+++++++++++++++++++++#+####
//           #########################
//                 ###############

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./DividendTracker.sol";
import "./ILeaderContract.sol";

contract ExPepe is ERC20, Ownable {
    IUniswapRouter public router;
    address public pair;
    address public marketing;
    ILeaderContract public leaderContract;
    DividendTracker public dividendTracker;

    bool private swapping;
    bool public swapEnabled = true;
    bool public tradingEnabled;

    uint256 public swapTaxesAtAmount;
    uint256 public maxBuyAntiBotAmount;
    uint256 public maxSellAntiBotAmount;
    uint256 public txTradeCount;
    uint256 public antiBotTime;
    uint256 public blacklistTime;
    uint256 cachedFeeAmountForHolder;
    uint256 cachedFeeAmountForMarketing;

    struct Taxes {
        uint256 holder;
        uint256 marketing;
        uint256 leaderContract;
    }

    // Decimal 2: 100 = 1%
    // Anti-bot
    Taxes public antiBotTaxes = Taxes(0, 8000, 0);
    // First 100 tx
    Taxes public phase1Taxes = Taxes(250, 250, 500);
    // 101 tx to 500 tx
    Taxes public phase2Taxes = Taxes(150, 150, 200);
    // After 501 tx
    Taxes public phase3Taxes = Taxes(200, 0, 100);

    // Decimal 2: 100 = 1%
    uint256 public constant totalAntiBotTax = 8000;
    uint256 public constant totalPhase1Tax = 1000;
    uint256 public constant totalPhase2Tax = 500;
    uint256 public constant totalPhase3Tax = 300;

    // phase1Tx = 0;
    uint256 public constant phase2Tx = 100;
    uint256 public constant phase3Tx = 500;

    mapping(address => bool) public isBlacklist;
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => mapping(uint256 => bool)) public isTransferred;

    event SendDividends(uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor(
        address _marketing,
        address _routerAddress,
        address _leaderContract
    ) ERC20("ExPepe", unicode"三PEPE") {
        dividendTracker = new DividendTracker();

        IUniswapRouter _router = IUniswapRouter(_routerAddress);

        marketing = _marketing;

        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;

        pair = _pair;

        swapTaxesAtAmount = 100_000 * 10 ** 18;

        _approve(address(this), address(_router), type(uint256).max);

        maxBuyAntiBotAmount = 1_000_000 * 10 ** 18;
        maxSellAntiBotAmount = 1_000_000 * 10 ** 18;

        _setAutomatedMarketMakerPair(_pair, true);

        leaderContract = ILeaderContract(_leaderContract);
        leaderContract.init(address(this));

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(_leaderContract, true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(0xdead), true);
        dividendTracker.excludeFromDividends(address(_router), true);

        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[_marketing] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[_leaderContract] = true;

        _mint(owner(), 50_000_000 * (10 ** 18));
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) public onlyOwner {
        DividendTracker newDividendTracker = DividendTracker(
            payable(newAddress)
        );
        newDividendTracker.excludeFromDividends(
            address(newDividendTracker),
            true
        );
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(owner(), true);
        newDividendTracker.excludeFromDividends(address(router), true);
        dividendTracker = newDividendTracker;
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender));
    }

    function setMaxBuyAndSellAntiBot(
        uint256 maxBuyAntiBot,
        uint256 maxSellAntiBot
    ) external onlyOwner {
        maxBuyAntiBotAmount = maxBuyAntiBot;
        maxSellAntiBotAmount = maxSellAntiBot;
    }

    function setSwapTaxesAtAmount(uint256 amount) external onlyOwner {
        swapTaxesAtAmount = amount;
    }

    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function forceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(marketing).call{value: ETHbalance}("");
        require(success);
    }

    function dividendTrackerRescueETH20Tokens(
        address tokenAddress
    ) external onlyOwner {
        dividendTracker.trackerRescueETH20Tokens(msg.sender, tokenAddress);
    }

    function dividendTrackerRescueStuckETH() external {
        require(msg.sender == marketing, "Not Admin");
        dividendTracker.rescueStuckETH(payable(msg.sender));
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IUniswapRouter(newRouter);
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function excludeFromDividends(
        address account,
        bool value
    ) public onlyOwner {
        dividendTracker.excludeFromDividends(account, value);
    }

    function setMarketingAddress(
        address payable _newMarketing
    ) external onlyOwner {
        require(_newMarketing != address(0), "Can not set zero address");
        marketing = _newMarketing;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function activateTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        antiBotTime = block.timestamp + 30;
        blacklistTime = block.timestamp + 600;
    }

    function setAutomatedMarketMakerPair(
        address newPair,
        bool value
    ) external onlyOwner {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(
            automatedMarketMakerPairs[newPair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[newPair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(newPair, true);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountInfo(
        address account
    ) external view returns (address, uint256, uint256, uint256, uint256) {
        return dividendTracker.getAccount(account);
    }

    function addToBlacklist(address[] calldata _addresses) external onlyOwner {
        require(
            block.timestamp <= blacklistTime || !tradingEnabled,
            "Can only add blacklist in the first 10 minutes"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            isBlacklist[_addresses[i]] = true;
        }
    }

    function removeBlacklist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            isBlacklist[_addresses[i]] = false;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isBlacklist[from] && !isBlacklist[to], "In blacklist");
        bool isBot = false;
        if (!isExcludedFromFees[from] && !isExcludedFromFees[to] && !swapping) {
            require(tradingEnabled, "Trading is not enabled");
            if (antiBotTime >= block.timestamp) {
                if (automatedMarketMakerPairs[to]) {
                    if (amount >= maxSellAntiBotAmount) isBot = true;
                } else if (automatedMarketMakerPairs[from]) {
                    if (amount >= maxBuyAntiBotAmount) isBot = true;
                }
            }
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (tx.origin == from || tx.origin == to) {
            require(!isTransferred[tx.origin][block.number], "Robot!");
            isTransferred[tx.origin][block.number] = true;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTaxesAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            automatedMarketMakerPairs[to] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapping = true;

            swapAndSend(swapTaxesAtAmount);

            swapping = false;
        }

        bool takeFee = !swapping;

        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            uint256 feeToHolder;
            uint256 feeToLeader;
            uint256 curTotalPhaseTax;
            uint256 lastTxTradeCount = txTradeCount;
            lastTxTradeCount++;
            txTradeCount = lastTxTradeCount;
            Taxes memory curPhase;

            if (isBot) {
                curTotalPhaseTax = totalAntiBotTax;
                curPhase = antiBotTaxes;
            } else if (lastTxTradeCount <= phase2Tx) {
                curTotalPhaseTax = totalPhase1Tax;
                curPhase = phase1Taxes;
            } else if (lastTxTradeCount <= phase3Tx) {
                curTotalPhaseTax = totalPhase2Tax;
                curPhase = phase2Taxes;
            } else {
                curTotalPhaseTax = totalPhase3Tax;
                curPhase = phase3Taxes;
            }
            feeAmt = (amount * curTotalPhaseTax) / 10000; // decimal 2, total fee
            amount = amount - feeAmt; //amount: go to reciever
            feeToHolder = (feeAmt * curPhase.holder) / curTotalPhaseTax;
            feeToLeader = (feeAmt * curPhase.leaderContract) / curTotalPhaseTax;
            feeAmt = feeAmt - feeToLeader - feeToHolder; // reused variable: feeAmt is for marketing

            cachedFeeAmountForHolder += feeToHolder;
            cachedFeeAmountForMarketing += feeAmt;
            super._transfer(from, address(this), feeAmt + feeToHolder);

            leaderContract.updateReward(feeToLeader);
            super._transfer(from, address(leaderContract), feeToLeader);
        }
        super._transfer(from, to, amount);
        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapAndSend(uint256 tokens) private {
        swapTokensForETH(tokens);

        uint256 feeForMarketing = cachedFeeAmountForMarketing;
        uint256 feeForHolder = cachedFeeAmountForHolder;
        cachedFeeAmountForMarketing = 0;
        cachedFeeAmountForHolder = 0;

        uint256 totalETHfee = address(this).balance;

        uint256 ethForMarketing = (totalETHfee * feeForMarketing) /
            (feeForMarketing + feeForHolder);
        uint256 ethForHolder = totalETHfee - ethForMarketing;

        if (ethForMarketing > 0) {
            payable(marketing).transfer(ethForMarketing);
        }

        if (ethForHolder > 0) {
            try dividendTracker.distributeRewardDividends(ethForHolder) {
                payable(dividendTracker).transfer(ethForHolder);
                emit SendDividends(ethForHolder);
            } catch {}
        }
    }

    function manualTokenDistributionForHolder(uint256 amount) public onlyOwner {
        bool success = IERC20(address(this)).transferFrom(
            msg.sender,
            address(dividendTracker),
            amount
        );
        if (success) {
            dividendTracker.distributeRewardDividends(amount);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}
