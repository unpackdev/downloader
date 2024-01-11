// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IPancakeRouter02.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";

interface IStake {   
    function depositReward(uint256 amount) external returns (uint256) ;
}

contract MusheXMU is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
    uint8 _decimals;
    address public treasuryAddress;
    bool public isTreasuryContract;
    address payable public marketingWallet; // marketing fee wallet
    address payable public liquidityAddress; // Liquidity Address
    uint256 constant maxFeeLimit = 300;

    //anti sniper storages
    mapping(address => bool) public bots;

    uint256 private _gasPriceLimit;
    bool public tradingActive;

    mapping(address => bool) public isExcludedFromFee;

    uint256 private constant BUY = 1;
    uint256 private constant SELL = 2;
    uint256 private constant TRANSFER = 3;
    uint256 private buyOrSellSwitch;

    // these values are pretty much arbitrary since they get overwritten for every txn, but the placeholders make it easier to work with current contract.
    uint256 private _rewardFee;
    uint256 private _previousRewardFee;

    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee;

    uint256 private _marketingFee;
    uint256 private _previousMarketingFee;

    uint256 public buyRewardFee;
    uint256 public buyLiquidityFee;
    uint256 public buyMarketingFee;

    uint256 public sellRewardFee;
    uint256 public sellLiquidityFee;
    uint256 public sellMarketingFee;

    mapping(address => bool) public isExcludedMaxTransactionAmount;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool private _transferDelayEnabled;

    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingFeeTokens;
    uint256 private _rewardFeeTokens;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 public minimumFeeTokensToTake;
    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;

    bool inSwapAndLiquify;
    event LogAddBots(address[] indexed bots);
    event LogRemoveBots(address[] indexed notbots);
    event TradingActivated();
    event UpdateMaxTransactionAmount(uint256 maxTransactionAmount);
    event UpdateMaxWallet(uint256 maxWallet);
    event UpdateMinimumTokensBeforeFeeTaken(uint256 minimumFeeTokensToTake);
    event SetAutomatedMarketMakerPair(address pair, bool value);
    event ExcludedMaxTransactionAmount(
        address indexed account,
        bool isExcluded
    );
    event UpdateTreasuryAddress(address treasuryAddress, bool isTreasuryContract);
    event UpdateBuyFee(
        uint256 buyRewardFee,
        uint256 buyLiquidityFee,
        uint256 buyMarketingFee
    );
    event UpdateSellFee(
        uint256 sellRewardFee,
        uint256 sellLiquidityFee,
        uint256 sellMarketingFee
    );
    event UpdateMarketingWallet(address marketingWallet);
    event UpdateLiquidityAddress(address _liquidityAddress);
    event SwapAndLiquify(
        uint256 tokensAutoLiq,
        uint256 ethAutoLiq
    );
    event RewardTaken(uint256 rewardFeeTokens);
    event MarketingFeeTaken(uint256 marketingFeeTokens);
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    function initialize(
        string memory _name,
        string memory _symbol,
        address _pancakeV2RouterAddress,
        address _treasuryAddress,
        address _liquidityAddress,
        address _marketingWallet,
        uint256[10] memory _uint_params,
        uint8 __decimals
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __ERC20Burnable_init();
        __Ownable_init();
        __ERC20Permit_init(_name);
        _mint(msg.sender, _uint_params[0] * (10**__decimals));
        _decimals=__decimals;
        liquidityAddress = payable(_liquidityAddress);
        marketingWallet = payable(_marketingWallet);
        treasuryAddress = _treasuryAddress;
        _gasPriceLimit = _uint_params[1] * 1 gwei;
        
        buyLiquidityFee = _uint_params[2];
        buyRewardFee = _uint_params[3];
        buyMarketingFee = _uint_params[4];

        
        sellLiquidityFee = _uint_params[5];
        sellRewardFee = _uint_params[6];
        sellMarketingFee = _uint_params[7];

        minimumFeeTokensToTake = _uint_params[0] * (10**__decimals)/10000;
        maxTransactionAmount = _uint_params[8]*(10**_decimals);
        maxWallet = _uint_params[9]*(10**_decimals);

        pancakeRouter = IPancakeRouter02(_pancakeV2RouterAddress);

        pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
        );

        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_treasuryAddress] = true;
        isExcludedFromFee[marketingWallet] = true;
        excludeFromMaxTransaction(_msgSender(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(_treasuryAddress, true);
        excludeFromMaxTransaction(marketingWallet, true);
        _setAutomatedMarketMakerPair(pancakePair, true);
    }
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }

    function enableTrading() external onlyOwner {
        require(!tradingActive, "already enabled");
        tradingActive = true;
        _transferDelayEnabled = true;
        emit TradingActivated();
    }

    function updateMaxTransactionAmount(uint256 _maxTransactionAmount)
        external
        onlyOwner
    {
        maxTransactionAmount = _maxTransactionAmount*(10**_decimals);
        emit UpdateMaxTransactionAmount(_maxTransactionAmount);
    }

    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet*(10**_decimals);
        emit UpdateMaxWallet(_maxWallet);
    }

    function updateMinimumTokensBeforeFeeTaken(uint256 _minimumFeeTokensToTake)
        external
        onlyOwner
    {
        minimumFeeTokensToTake = _minimumFeeTokensToTake*(10**_decimals);
        emit UpdateMinimumTokensBeforeFeeTaken(_minimumFeeTokensToTake);
    }


    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != pancakePair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasPriceLimit(uint256 gas) external onlyOwner {
        _gasPriceLimit = gas * 1 gwei;
    }

    // disable Transfer delay
    function disableTransferDelay(bool _isEnabled) external onlyOwner {
        _transferDelayEnabled = _isEnabled;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        isExcludedMaxTransactionAmount[updAds] = isEx;
        emit ExcludedMaxTransactionAmount(updAds, isEx);
    }

    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function updateBuyFee(
        uint256 _buyRewardFee,
        uint256 _buyLiquidityFee,
        uint256 _buyMarketingFee
    ) external onlyOwner {
        buyRewardFee = _buyRewardFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyMarketingFee = _buyMarketingFee;
        require(
            _buyRewardFee + _buyLiquidityFee + _buyMarketingFee <= maxFeeLimit,
            "Must keep Rewardes below 30%"
        );
        emit UpdateBuyFee(_buyRewardFee, _buyLiquidityFee, _buyMarketingFee);
    }

    function updateSellFee(
        uint256 _sellRewardFee,
        uint256 _sellLiquidityFee,
        uint256 _sellMarketingFee
    ) external onlyOwner {
        sellRewardFee = _sellRewardFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellMarketingFee = _sellMarketingFee;
        require(
            _sellRewardFee + _sellLiquidityFee + _sellMarketingFee <= maxFeeLimit,
            "Must keep Rewardes <= 30%"
        );
        emit UpdateSellFee(sellRewardFee, sellLiquidityFee, sellMarketingFee);
    }



    function updateTreasuryAddress(address _treasuryAddress, bool _isTreasuryContract) external onlyOwner {
        treasuryAddress = _treasuryAddress;
        isExcludedFromFee[_treasuryAddress] = true;
        excludeFromMaxTransaction(_treasuryAddress, true);
        isTreasuryContract=_isTreasuryContract;
        emit UpdateTreasuryAddress(_treasuryAddress, _isTreasuryContract);
    }
    function updateMarketingWallet(address _marketingWallet)
        external
        onlyOwner
    {
        marketingWallet = payable(_marketingWallet);
        isExcludedFromFee[_marketingWallet] = true;
        excludeFromMaxTransaction(_marketingWallet, true);
        emit UpdateMarketingWallet(_marketingWallet);
    }

    function updateLiquidityAddress(address _liquidityAddress)
        external
        onlyOwner
    {
        liquidityAddress = payable(_liquidityAddress);
        emit UpdateLiquidityAddress(_liquidityAddress);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!bots[from] && !bots[to]); 
        if (!tradingActive) {
            require(
                isExcludedFromFee[from] || isExcludedFromFee[to],
                "Trading is not active yet."
            );
        }

        if (!inSwapAndLiquify) {
            if (automatedMarketMakerPairs[from]) {
                require(
                    tx.gasprice <= _gasPriceLimit,
                    "Gas price exceeds limit."
                );
            }
            // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
            if (_transferDelayEnabled) {
                if (
                    to != address(pancakeRouter) && to != address(pancakePair)
                ) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            //when buy
            if (
                automatedMarketMakerPairs[from] &&
                !isExcludedMaxTransactionAmount[to]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Cannot exceed max wallet"
                );
            }
            //when sell
            else if (
                automatedMarketMakerPairs[to] &&
                !isExcludedMaxTransactionAmount[from]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Sell transfer amount exceeds the maxTransactionAmount."
                );
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minimumFeeTokensToTake;

        // Take Fee
        if (
            !inSwapAndLiquify &&
            balanceOf(pancakePair) > 0 &&
            overMinimumTokenBalance &&
            automatedMarketMakerPairs[to]
        ) {
            takeFee();
        }

        removeAllFee();

        buyOrSellSwitch = TRANSFER;

        // If any account belongs to isExcludedFromFee account then remove the fee
        if (!inSwapAndLiquify && !isExcludedFromFee[from] && !isExcludedFromFee[to]) {
             // Buy
            if (automatedMarketMakerPairs[from]) {
                _rewardFee = amount*(buyRewardFee)/(1000);
                _liquidityFee = amount*(buyLiquidityFee)/(1000);
                _marketingFee = amount*(buyMarketingFee)/(1000);
                buyOrSellSwitch = BUY;
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _rewardFee = amount*(sellRewardFee)/(1000);
                _liquidityFee = amount*(sellLiquidityFee)/(1000);
                _marketingFee = amount*(sellMarketingFee)/(1000);
                buyOrSellSwitch = SELL;
            }
        }

        uint256 _transferAmount = amount-_rewardFee-_liquidityFee-_marketingFee;
        super._transfer(from, to, _transferAmount);
        uint256 _feeTotal = _rewardFee+_liquidityFee+_marketingFee;
        if (_feeTotal > 0) {
            super._transfer(
                from,
                address(this),
                _feeTotal
            );
            _liquidityTokensToSwap=_liquidityTokensToSwap+_liquidityFee;
            _marketingFeeTokens=_marketingFeeTokens+_marketingFee;
            _rewardFeeTokens=_rewardFeeTokens+_rewardFee;
        }

        restoreAllFee();
    }

    function addBots(address[] memory _bots)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _bots.length; i++) {
            bots[_bots[i]] = true;
        }
        emit LogAddBots(_bots);
    }

    function removeBots(address[] memory _notbots)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _notbots.length; i++) {
            bots[_notbots[i]] = false;
        }
        emit LogRemoveBots(_notbots);
    }
    function removeAllFee() private {
        if (_rewardFee == 0 && _liquidityFee == 0 && _marketingFee==0) return;

        _previousRewardFee = _rewardFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        _rewardFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
    }

    function restoreAllFee() private {
        _rewardFee = _previousRewardFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }


    function takeFee() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensTaken=_liquidityTokensToSwap+(_marketingFeeTokens)+(_rewardFeeTokens);
        if (totalTokensTaken == 0 || contractBalance <totalTokensTaken) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityTokensToSwap / 2;
        uint256 initialBNBBalance = address(this).balance;
        swapTokensForBNB(tokensForLiquidity+_marketingFeeTokens);
        uint256 bnbBalance = address(this).balance-initialBNBBalance;        
        uint256 bnbForMarketing = bnbBalance*_marketingFeeTokens/(
            tokensForLiquidity+_marketingFeeTokens
        );
        uint256 bnbForLiquidity = bnbBalance - bnbForMarketing;
        if (tokensForLiquidity > 0 && bnbForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, bnbForLiquidity);
            emit SwapAndLiquify(
                tokensForLiquidity,
                bnbForLiquidity
            );
        }

        if(isTreasuryContract){
            IStake stake=IStake(treasuryAddress);
            _approve(address(this), address(stake), _rewardFeeTokens);
            stake.depositReward(_rewardFeeTokens);
        }else{
            _transfer(address(this), treasuryAddress, _rewardFeeTokens);
        }       
        
        emit RewardTaken(_rewardFeeTokens);

        (bool success, ) = address(marketingWallet).call{
            value: bnbForMarketing
        }("");
        emit MarketingFeeTaken(_marketingFeeTokens);
        

        _liquidityTokensToSwap = 0;
        _marketingFeeTokens = 0;
        _rewardFeeTokens=0;
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        _approve(address(this), address(pancakeRouter), tokenAmount);
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(pancakeRouter), tokenAmount);
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityAddress,
            block.timestamp
        );
    }
    receive() external payable {}
}
