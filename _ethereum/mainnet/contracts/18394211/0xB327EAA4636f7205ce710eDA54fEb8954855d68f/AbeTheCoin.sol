    // SPDX-License-Identifier: UNLICENSED

/*

-------------------------------------




       $$$$$                                                                              
       $:::$                                                                              
   $$$$$:::$$$$$$             AAA               BBBBBBBBBBBBBBBBB   EEEEEEEEEEEEEEEEEEEEEE
 $$::::::::::::::$           A:::A              B::::::::::::::::B  E::::::::::::::::::::E
$:::::$$$$$$$::::$          A:::::A             B::::::BBBBBB:::::B E::::::::::::::::::::E
$::::$       $$$$$         A:::::::A            BB:::::B     B:::::BEE::::::EEEEEEEEE::::E
$::::$                    A:::::::::A             B::::B     B:::::B  E:::::E       EEEEEE
$::::$                   A:::::A:::::A            B::::B     B:::::B  E:::::E             
$:::::$$$$$$$$$         A:::::A A:::::A           B::::BBBBBB:::::B   E::::::EEEEEEEEEE   
 $$::::::::::::$$      A:::::A   A:::::A          B:::::::::::::BB    E:::::::::::::::E   
   $$$$$$$$$:::::$    A:::::A     A:::::A         B::::BBBBBB:::::B   E:::::::::::::::E   
            $::::$   A:::::AAAAAAAAA:::::A        B::::B     B:::::B  E::::::EEEEEEEEEE   
            $::::$  A:::::::::::::::::::::A       B::::B     B:::::B  E:::::E             
$$$$$       $::::$ A:::::AAAAAAAAAAAAA:::::A      B::::B     B:::::B  E:::::E       EEEEEE
$::::$$$$$$$:::::$A:::::A             A:::::A   BB:::::BBBBBB::::::BEE::::::EEEEEEEE:::::E
$::::::::::::::$$A:::::A               A:::::A  B:::::::::::::::::B E::::::::::::::::::::E
 $$$$$$:::$$$$$ A:::::A                 A:::::A B::::::::::::::::B  E::::::::::::::::::::E
      $:::$    AAAAAAA                   AAAAAAABBBBBBBBBBBBBBBBB   EEEEEEEEEEEEEEEEEEEEEE
      $$$$$                                                                               
                                                                                          
                                                                                          
                                                                                          
                                                                                                                                                                   
-------------------------------------

Twitter  -  https://x.com/AbeTheCoin
Telegram -  https://t.me/AbeTheCoin
Website  -  https://abethecoin.com/                                                           
                                                               
*/                  


pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./SafeMath.sol";



contract AbeTheCoin is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address private marketingWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 private launchedAt;
    uint256 private launchedTime;
    uint256 public deadBlocks;

    uint256 public buyTotalFees;
    uint256 private buyMarketingFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(uint256 => uint256) private swapInBlock;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("Four score and seven years ago our fathers brought forth, upon this continent, a new nation, conceived in Liberty, and dedicated to the proposition that all men are created equal.","ABE") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTransactionAmount = 1_000_0000 * 1e18;
        maxWallet = 2_000_0000 * 1e18;
        swapTokensAtAmount = maxTransactionAmount / 2000;


        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTrading(uint256 _deadBlocks) external onlyOwner {
        deadBlocks = _deadBlocks;
        tradingActive = true;
        swapEnabled = true;
        launchedAt = block.number;
        launchedTime = block.timestamp;
    }

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function whitelistContract(address _whitelist,bool isWL)
    public
    onlyOwner
    {
      _isExcludedMaxTransactionAmount[_whitelist] = isWL;

      _isExcludedFromFees[_whitelist] = isWL;

    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function manualswap(uint256 amount) external {
      require(_msgSender() == marketingWallet);
        require(amount <= balanceOf(address(this)) && amount > 0, "Wrong amount");
        swapTokensForEth(amount);
    }

    function manualsend() external {
        bool success;
        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

        function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(
        uint256 _marketingFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyTotalFees = buyMarketingFee;
        require(buyTotalFees <= 10, "Must keep fees at 5% or less");
    }

    function updateSellFees(
        uint256 _marketingFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellTotalFees = sellMarketingFee;
        require(sellTotalFees <= 10, "Must keep fees at 5% or less");
    }

    function updateMarketingWallet(address newMarketingWallet)
        external
        onlyOwner
    {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function airdrop(address[] calldata addresses, uint256[] calldata amounts) external {
          require(addresses.length > 0 && amounts.length == addresses.length);
          address from = msg.sender;

          for (uint i = 0; i < addresses.length; i++) {

            _transfer(from, addresses[i], amounts[i] * (10**18));

          }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 blockNum = block.number;

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if ((launchedAt + deadBlocks) >= blockNum) {
                    buyMarketingFee = 99;
                    buyTotalFees = buyMarketingFee;

                    sellMarketingFee = 99;
                    sellTotalFees = sellMarketingFee;
                } 
                else if (blockNum > (launchedAt + deadBlocks) && blockNum <= (launchedAt + 32)) {
                    maxTransactionAmount = 20_000_000 * 1e18;
                    maxWallet = 20_000_000 * 1e18;

                    buyMarketingFee = 10;
                    buyTotalFees = buyMarketingFee;

                    sellMarketingFee = 10;
                    sellTotalFees = sellMarketingFee;
                }

                else {
                    maxTransactionAmount = 20_000_000 * 1e18;
                    maxWallet = 20_000_000 * 1e18;

                    buyMarketingFee = 1;
                    buyTotalFees = buyMarketingFee;

                    sellMarketingFee = 1;
                    sellTotalFees = sellMarketingFee;
                }
            }


            if (!tradingActive) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "Trading is not active."
                );
            }

            //when buy
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactionAmount[to]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
            //when sell
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactionAmount[from]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Sell transfer amount exceeds the maxTransactionAmount."
                );
            } else if (!_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
            
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            canSwap &&
            swapEnabled &&
            !swapping &&
            (swapInBlock[blockNum] < 2) &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            ++swapInBlock[blockNum];

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }


        uint256 amountToSwapForETH = contractBalance;

        swapTokensForEth(amountToSwapForETH);

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

}