// SPDX-License-Identifier: UNLICENSED

/*

Game: https://game.fsgame.io/

Website: https://fsgame.io/
Twitter: https://twitter.com/ForgottenERC
Docs: https://docs.fsgame.io
TG: https://t.me/ForgottenSoulsChat

EVER WANTED TO PLAY GAMES AND MAKE MONEY? HERE'S YOUR CHANCE.

*/

pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ForgottenSouls is ERC20("Forgotten Souls", "SOULS"), Ownable {

    // Uniswap variables
    IUniswapV2Factory public constant UNISWAP_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_V2_PAIR;

    uint256 constant TOTAL_SUPPLY = 10_000_000 ether;
    uint256 public tradingOpenedOnBlock;

    bool private swapping;

    address public soulWallet;

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
    event UpdatedsoulWallet(address indexed newWallet);
    event MaxTransactionExclusion(address _address, bool excluded);
    event Whitelisted(address indexed account, bool isWhitelisted);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    bool public claimEnable = true;

    uint256 public claimTime = 86400;
    uint256 public maxClaim = 5000;
    uint256 public minBalance = 10_000 * 10 ** 18;

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

        maxBuyAmount = (totalSupply() * 15) / 1_000; // 1.5% max buy
        maxSellAmount = (totalSupply() * 5) / 1_000; // 0.5% max sell
        maxWalletAmount = (totalSupply() * 20) / 1_000; // 2% max holdings
        tokenSwapThreshold = (totalSupply() * 70) / 10_000; // 0.65% threshold 

        soulWallet = msg.sender;
        controller[msg.sender] = true;

        _excludeFromMaxTransaction(msg.sender, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
    }

    receive() external payable {}


// Game functions
    // CLAIM $SOULS REWARDS
    function claimRewards(address _account, uint256 _amount) public {
        require(claimEnable, "Claim is not active yet.");
        require(balanceOf(_account) >= minBalance, "Not enough balance to claim.");

        uint256 claimRecord = claimDate[_account];
        require((block.timestamp - claimRecord) >= claimTime, "Need to wait until your next claim.");

        if (_amount > maxClaim) {
            _amount = maxClaim;
            }

        super.transferFrom(soulWallet, _account, _amount * 10 ** 18);
        claimDate[_account] = block.timestamp;
    }

    // SET MAX CLAIM
    function setMaxClaim(uint256 _amount) public {
        require(controller[msg.sender], "Not controller.");
        maxClaim = _amount;
    }

    // SET CLAIM TIME
    function setClaimTime(uint256 _time) public {
        require(controller[msg.sender], "Not controller.");
        claimTime = _time;
    }

    // MIN BALANCE TO CLAIM
    function setMinBalance(uint256 _amount) public {
        require(controller[msg.sender], "Not controller.");
        minBalance = _amount;
    }

    // CLAIM STATE
    function setClaimState(bool _state) public {
        require(controller[msg.sender], "Not controller.");
        claimEnable = _state;
    }

    // ADD CONTROLLER
    function setController(address _account) public {
        require(controller[msg.sender], "Not controller.");
        controller[_account] = true;
    }

// Uniswap functions
    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "ERROR: Cannot set max buy lower than 0.1%"
        );
        maxBuyAmount = newNum;
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "ERROR: Cannot set max sell lower than 0.1%"
        );
        maxSellAmount = newNum;
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 3) / 1_000),
            "ERROR: Cannot set max wallet lower than 0.3%"
        );
        maxWalletAmount = newNum;
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100_000,
            "ERROR: Swap cannot be lower than 0.001% total supply."
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
        require(tradingOpenedOnBlock == 0, "ERROR: Token is already live !");
        tradingOpenedOnBlock = block.number;
        tradingActive = true;
        swapEnabled = true;
        emit EnabledTrading(tradingActive);
    }

    function setsoulWallet(address _soulWallet) external onlyOwner {
        require(_soulWallet != address(0), "ERROR: _soulWallet address cannot be 0");
        soulWallet = payable(_soulWallet);
        emit UpdatedsoulWallet(_soulWallet);
    }

    function getFees() internal {
        require(
            tradingOpenedOnBlock > 0, "Trading not live"
        );
        uint256 currentBlock = block.number;
        uint256 lastTierOneBlock = tradingOpenedOnBlock + 7;
        if(currentBlock <= lastTierOneBlock) {
            buyTotalFees = 25;
            sellTotalFees = 30;
        } else {
            buyTotalFees = 12;
            sellTotalFees = 18;
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
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        require(amount > 0, "amt must be greater than 0");

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
                            "ERROR: Trading isnt active."
                        );
                        require(from == owner(), "ERROR: Trading enabled");
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
                            "ERROR: Cannot pass max wallet"
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
                            "ERROR: Cannot Exceed max wallet"
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

                // Sell
                if (to == UNISWAP_V2_PAIR && sellTotalFees > 0) {
                    fees = (amount * sellTotalFees) / 100;
                    taxedTokens += fees;
                }
                // Buy
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

        (success, ) = address(soulWallet).call{value: address(this).balance}("");
    }

    function withdrawStuckToken(address _token) external {
        require(
            msg.sender == owner() || msg.sender == soulWallet,
            "ERROR: Not authorized"
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
        require(success, "ERROR: failed to withdraw funds");
    }

    function updateWhitelist(address account, bool isWhitelisted) external onlyOwner {
        whitelisted[account] = isWhitelisted;
        emit Whitelisted(account, isWhitelisted);
    }
}