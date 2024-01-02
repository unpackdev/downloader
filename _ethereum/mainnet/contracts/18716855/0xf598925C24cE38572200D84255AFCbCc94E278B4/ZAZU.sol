// SPDX-License-Identifier: UNLICENSED

/*

/*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
                         ..         .:--==+*********+==-.       -+*####*=                 
                       :*#**+-.  -+********************+++=.  .*#%@@%@@@*:                
                       +######*+**###****************##**#**+=*%@@%%%@@@#-                
                      :=*###%%############*********###########%%%%%#%%@@#-                
                      -+*#*####################**###################%%@@*=                
                      =***###%##############**##############%%%#####%%@@*-                
                      =*%%#%################*###*+#######%##%%%%%%%%%@@%*                 
                      -*#%#%##%#######%#####*###**############%%%%####%#-                 
                      :*#%%%#%%%##%%#%######*###**#########%#%%%%%%#%%#*                  
                      -**#%%#%%########****************##*####%%#%##%#*-                  
                     .*+*#######%###%#%############*######%####%%###%#+                   
                     -*#%%%%%%@@@@@%#*+++#*******####*++*#%@@@@@@%%%%*.                   
                      +#%%%%@@@@@@@@@@*==****###***#*==*%@@@@@@@@@#%#+                    
                      =+%#+=#@#@@@@@@@@*=+**#%%%%#*#==#%%@@@@@@%@#+*%*:                   
                     .*%%%**+*#%@@@%%@@%+#***#*##****+@@%%@@@@@%#==+%#+                   
                    :*%%#@####*+====*%@%%##****+**##%@@@%*****++**#%%%*:                  
                   -*%###@##%%%%%#*#%@#%%%#*******##@@%@@#**#####%%@%%*-                  
                  :**#*#%%#%@%##########%@@@%%%%%%@%@#*##%####%@@@%%#@#*-                 
                  -*%%%%%%%%@%#%###**++*@@@@@%%%%@@@@#++***##%#%@@@@@@##*.                
                  :*###*%##%@%%%%###*++==+#@@@@@@@#+===+*#%%%%#%@%#*#%@@#-                
                   -*###%####%#***#**+==---+@@@@@+----==***#######**#%%@#-                
                    +**+%#***###***+++=+====*@@%+=======+***######%####@+-                
                    +#***##++++***##*++++++*#@@##*+=++++*****+++**+++*%@*.                
                   :*###*##*+++##%%%%%#####**##########%%##*+=====++*#@%*.                
                   ****###*####%%%%%%%%##***++*++**#####*++++********#%%+=                
                  .**+*##*******##%%%%%%%%%%%%%##%####**++++*******#%@@%#*:               
                  :*****#%##**+*++******######%#*#*++++++++++*****##%@@@@%+               
                  =*#***#%%#**+++++++++=++++===#+++===++++++++***#%@@@@@@%*               
                  *#%%*****###***+++++==+=*#===+#++=+++*+++++**#%@@@@%%%@@*:              
                 :**%%%#*+++*#####***++++#%*++=*#*++++++*##*#%%@@@@%%%%@@@#=              
                 =#%#@@@%%##***#%@@%%%##%%#*****%#**###%%%@@@@@%%%####%@@@@+              
                 +%@%@@@@@@@@%%%%@%%%%%######**#%#%#%%@@@@@@@%#**###%@@@@@@*              
                 *@@@@@@@@@@@@@@@@@@%%%%%%##%%#%%%###%#%#%########%%@@@@%@@*.             
                 *@@@@@@@@@@@@@@@@@@@@@@@%@%@%%%@@@%%%#%%%%#%%@%%@@@@@@@@@@#:             
                .*%%%%%%%%%%%%%%%%%%%%%%%%%%%%##%%%%%%%%%%%%%%%%%%%%%%%%%%%#-             

BECOME A ZAZOONIAN TODAY

Website: https://zazuerc.com
Twitter: https://x.com/zazuerc
Telegram: https://t.me/zazuerc

*/ 

pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ZAZU is ERC20("ZAZU Coin", "ZAZU"), Ownable {

    // Uniswap variables
    IUniswapV2Factory public constant UNISWAP_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_V2_PAIR;

    uint256 constant TOTAL_SUPPLY = 69_000_000 ether;
    uint256 public tradingOpenedOnBlock;

    bool private swapping;

    address public zazuWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public fetchFees = true;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;
    uint256 public tokenSwapThreshold;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    uint256 public taxedTokens;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public whitelisted;

    event EnabledTrading(bool tradingActive);
    event RemovedLimits();
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdatedMaxBuyAmount(uint256 newAmount);
    event UpdatedMaxSellAmount(uint256 newAmount);
    event UpdatedMaxWalletAmount(uint256 newAmount);
    event UpdatedzazuWallet(address indexed newWallet);
    event MaxTransactionExclusion(address _address, bool excluded);
    event Whitelisted(address indexed account, bool isWhitelisted);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    mapping(address => bool) public controller;
    mapping(address => uint256) public claimDate;

    constructor() {

        _mint(msg.sender, TOTAL_SUPPLY);

        _approve(address(this), address(UNISWAP_ROUTER), ~uint256(0));

        _excludeFromMaxTransaction(address(UNISWAP_ROUTER), true);
    
        UNISWAP_V2_PAIR = UNISWAP_FACTORY.createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
        );

        maxBuyAmount = (totalSupply() * 15) / 1_200; // 1.5% max buy
        maxSellAmount = (totalSupply() * 8) / 5_00; // 0.8% max sell
        maxWalletAmount = (totalSupply() * 20) / 1_000; // 2% max holdings
        tokenSwapThreshold = (totalSupply() * 65) / 10_000; // 0.65% swapToEth threshold 

        zazuWallet = msg.sender;
        controller[msg.sender] = true;

        _excludeFromMaxTransaction(msg.sender, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
    }

    receive() external payable {}

    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "ERROR: Cannot set max buy amount lower than 0.1%"
        );
        maxBuyAmount = newNum;
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "ERROR: Cannot set max sell amount lower than 0.1%"
        );
        maxSellAmount = newNum;
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 3) / 1_000),
            "ERROR: Cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newNum;
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100_000,
            "ERROR: Swap amount cannot be lower than 0.001% total supply."
        );
    
        tokenSwapThreshold = newAmount;
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function _excludeFromMaxTransaction(
        address updAds,
        bool isExcluded
    ) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function openTrading() public onlyOwner {
        require(tradingOpenedOnBlock == 0, "ERROR: Token is live !");
        tradingOpenedOnBlock = block.number;
        tradingActive = true;
        swapEnabled = true;
        emit EnabledTrading(tradingActive);
    }

    function setzazuWallet(address _zazuWallet) external onlyOwner {
        require(_zazuWallet != address(0), "ERROR: _zazuWallet address not set");
        zazuWallet = payable(_zazuWallet);
        emit UpdatedzazuWallet(_zazuWallet);
    }

    function getFees() internal {
        require(
            tradingOpenedOnBlock > 0, "Trading isnt live"
        );
        uint256 currentBlock = block.number;
        uint256 lastTierOneBlock = tradingOpenedOnBlock + 8;
        if(currentBlock <= lastTierOneBlock) {
            buyTotalFees = 25;
            sellTotalFees = 30;
        } else {
            buyTotalFees = 14;
            sellTotalFees = 20;
            fetchFees = false;
        } 
    }

    function setNewFees(uint256 newBuyFees, uint256 newSellFees) external onlyOwner {
    buyTotalFees = newBuyFees;
    sellTotalFees = newSellFees;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (whitelisted[from] || whitelisted[to]) {
            super._transfer(from, to, amount);
        } else {
            if (limitsInEffect) {
                if (
                    from != owner() &&
                    to != owner() &&
                    to != address(0) &&
                    to != address(0xdead)
                ) {
                    if (!tradingActive) {
                        require(
                            _isExcludedMaxTransactionAmount[from] ||
                                _isExcludedMaxTransactionAmount[to],
                            "ERROR: Trading not active."
                        );
                        require(from == owner(), "ERROR: Trading  enabled");
                    }

                    //when buy
                    if (
                        from == UNISWAP_V2_PAIR && !_isExcludedMaxTransactionAmount[to]
                    ) {
                        require(
                            amount <= maxBuyAmount,
                            "ERROR: Buy transfer amt exceeds max buy."
                        );
                        require(
                            amount + balanceOf(to) <= maxWalletAmount,
                            "ERROR: cant pass max wallet"
                        );
                    }
                    //when sell
                    else if (
                        to == UNISWAP_V2_PAIR && !_isExcludedMaxTransactionAmount[from]
                    ) {
                        require(
                            amount <= maxSellAmount,
                            "ERROR: Sell transfer amt exceeds the max sell."
                        );
                    } else if (
                        !_isExcludedMaxTransactionAmount[to] &&
                        !_isExcludedMaxTransactionAmount[from]
                    ) {
                        require(
                            amount + balanceOf(to) <= maxWalletAmount,
                            "ERROR: cant Exceed max wallet"
                        );
                    }
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwap = contractTokenBalance >= tokenSwapThreshold;

            if (
                canSwap &&
                swapEnabled &&
                !swapping &&
                !(from == UNISWAP_V2_PAIR) &&
                !_isExcludedFromFees[from] &&
                !_isExcludedFromFees[to]
            ) {
                swapping = true;
                swapBack();
                swapping = false;
            }

            bool takeFee = true;
        
            if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
                takeFee = false;
            }

            uint256 fees = 0;
        

            if (takeFee) {

                if(fetchFees){
                    getFees(); 
                }

                
                if (to == UNISWAP_V2_PAIR && sellTotalFees > 0) {
                    fees = (amount * sellTotalFees) / 100;
                    taxedTokens += fees;
                }
                
                else if (from == UNISWAP_V2_PAIR && buyTotalFees > 0) {
                    fees = (amount * buyTotalFees) / 100;
                    taxedTokens += fees;
                }

                if (fees > 0) {
                    super._transfer(from, address(this), fees);
                }

                amount -= fees;
            }

            super._transfer(from, to, amount);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();

        
        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));

        uint256 totalTokensToSwap =  taxedTokens;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > tokenSwapThreshold) {
            contractBalance = tokenSwapThreshold;
        }

        bool success;
    
        swapTokensForEth(contractBalance);

        (success, ) = address(zazuWallet).call{value: address(this).balance}("");
    }

    function withdrawStuckToken(address _token) external {
        require(
            msg.sender == owner() || msg.sender == zazuWallet,
            "ERR"
        );
        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }

    function withdrawStuckEth() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "ERR: cannot withdraw");
    }

    function updateWhitelist(address account, bool isWhitelisted) external onlyOwner {
        whitelisted[account] = isWhitelisted;
        emit Whitelisted(account, isWhitelisted);
    }
}