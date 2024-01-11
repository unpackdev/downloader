// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./OwnableUpgradeable.sol";

import "./ERC20Upgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";
import "./Initializable.sol";

import "./IPancakeRouter02.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";


interface IStake {   
    function depositReward(uint256 amount) external returns (uint256) ;
}
contract Aquasis is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable {
    mapping(address => bool) public bots;
    address public treasuryAddress; // treasury CA
    bool public isTreasuryContract;
    address payable public liquidityAddress; // Liquidity Address
    uint16 constant maxFeeLimit = 300;
    uint8 private _decimals;

    //anti sniper storages
    bool private _gasLimitActive;
    uint256 private _gasPriceLimit;
    bool public tradingActive;
    bool public limitsInTrade;
    bool public transferDelayEnabled;
    mapping(address => bool) public isExcludedFromFee;

    // these values are pretty much arbitrary since they get overwritten for every txn, but the placeholders make it easier to work with current contract.
    
    uint16 public buyRewardFee;
    uint16 public buyLiquidityFee;
    uint16 public buyBurnFee;

    uint16 public sellRewardFee;
    uint16 public sellLiquidityFee;
    uint16 public sellBurnFee;


    mapping(address => bool) public isExcludedMaxTransactionAmount;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    

    uint256 private _liquidityTokensToSwap;
    uint256 public _burnFeeTokens;
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
    bool public swapAndLiquifyEnabled;
    event LogAddBots(address[] indexed bots);
    event LogRemoveBots(address[] indexed notbots);
    event TradingActivated();
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event UpdateMaxTransactionAmount(uint256 maxTransactionAmount);
    event UpdateMaxWallet(uint256 maxWallet);
    event UpdateMinimumTokensBeforeFeeTaken(uint256 minimumFeeTokensToTake);
    event SetAutomatedMarketMakerPair(address pair, bool value);
    event ExcludedMaxTransactionAmount(
        address indexed account,
        bool isExcluded
    );
    event ExcludedFromFee(address account, bool isExcludedFromFee);
    event UpdateBuyFee(
        uint256 buyRewardFee,
        uint256 buyLiquidityFee,
        uint256 buyBurnFee
    );
    event UpdateSellFee(
        uint256 sellRewardFee,
        uint256 sellLiquidityFee,
        uint256 sellBurnFee
    );
  
    event UpdateTreasuryAddress(address treasuryAddress, bool isTreasuryContract);
    event UpdateLiquidityAddress(address _liquidityAddress);
    event SwapAndLiquify(
        uint256 tokensAutoLiq,
        uint256 ethAutoLiq
    );
    event RewardTaken(uint256 rewardFeeTokens);
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        address _pancakeV2RouterAddress,
        address _treasuryAddress,
        address _liquidityAddress,
        uint256[5] memory _uint_params,
        uint16[6] memory _uint16_params        
    ) initializer public {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __ERC20Permit_init(_name);
        __ERC20Votes_init();
        _decimals=__decimals;
        _mint(msg.sender, _uint_params[0] * 10**__decimals);
        liquidityAddress = payable(_liquidityAddress);
        treasuryAddress = _treasuryAddress;   
        _gasPriceLimit = _uint_params[1] * 1 gwei;    
        
        buyLiquidityFee = _uint16_params[0];
        buyRewardFee = _uint16_params[1];
        buyBurnFee = _uint16_params[2];
        require(maxFeeLimit>buyLiquidityFee+buyRewardFee+buyBurnFee,"buy fee < 30%");
        
        sellLiquidityFee = _uint16_params[3];
        sellRewardFee = _uint16_params[4];
        sellBurnFee = _uint16_params[5];        
        require(maxFeeLimit>sellLiquidityFee+sellRewardFee+sellBurnFee,"sell fee < 30%");

        minimumFeeTokensToTake = _uint_params[2]*(10**__decimals);
        maxTransactionAmount = _uint_params[3]*(10**__decimals);
        maxWallet = _uint_params[4]*(10**__decimals);
        require(maxWallet>0,"max wallet > 0");
        require(maxTransactionAmount>0,"maxTransactionAmount > 0");
        require(minimumFeeTokensToTake>0,"minimumFeeTokensToTake > 0");
       
        pancakeRouter = IPancakeRouter02(_pancakeV2RouterAddress);

        pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
        );

        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_treasuryAddress] = true;
        isExcludedFromFee[address(0xDead)] = true;
        excludeFromMaxTransaction(_msgSender(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(_treasuryAddress, true);
        excludeFromMaxTransaction(address(0xDead), true);
        _setAutomatedMarketMakerPair(pancakePair, true);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }
   
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    function enableTrading() external onlyOwner {
        require(!tradingActive, "already enabled");
        tradingActive = true;
        swapAndLiquifyEnabled = true;
        _gasLimitActive=true;
        transferDelayEnabled=true;
        limitsInTrade=true;
        emit TradingActivated();
    }

    function setSwapAndLiquifyEnabled(bool _enabled)
        public
        onlyOwner
    {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function updateMaxTransactionAmount(uint256 _maxTransactionAmount)
        external
        onlyOwner
    {
        maxTransactionAmount = _maxTransactionAmount*(10**_decimals);
        require(maxTransactionAmount>0,"maxTransactionAmount > 0");
        emit UpdateMaxTransactionAmount(_maxTransactionAmount);
    }

    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet*(10**_decimals);
        require(maxWallet>0,"maxWallet > 0");
        emit UpdateMaxWallet(_maxWallet);
    }

    function updateMinimumTokensBeforeFeeTaken(uint256 _minimumFeeTokensToTake)
        external
        onlyOwner
    {
        minimumFeeTokensToTake = _minimumFeeTokensToTake*(10**_decimals);
        require(minimumFeeTokensToTake>0,"minimumFeeTokensToTake > 0");
        emit UpdateMinimumTokensBeforeFeeTaken(_minimumFeeTokensToTake);
    }


    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != pancakePair,
            "The pair cannot be removed"
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
        require(10000000<_gasPriceLimit,"gasPricelimit > 10000000");
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
        emit ExcludedFromFee(account, true);
    }

    function includeInFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
        emit ExcludedFromFee(account, false);
    }

    function updateBuyFee(
        uint16 _buyRewardFee,
        uint16 _buyLiquidityFee,
        uint16 _buyBurnFee
    ) external onlyOwner {
        buyRewardFee = _buyRewardFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyBurnFee = _buyBurnFee;
        require(
            _buyRewardFee + _buyLiquidityFee + _buyBurnFee <= maxFeeLimit,
            "Must keep fees below 30%"
        );
        emit UpdateBuyFee(_buyRewardFee, _buyLiquidityFee, _buyBurnFee);
    }

    function updateSellFee(
        uint16 _sellRewardFee,
        uint16 _sellLiquidityFee,
        uint16 _sellBurnFee
    ) external onlyOwner {
        sellRewardFee = _sellRewardFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellBurnFee = _sellBurnFee;
        require(
            _sellRewardFee + _sellLiquidityFee + _sellBurnFee <= maxFeeLimit,
            "Must keep fees <= 30%"
        );
        emit UpdateSellFee(sellRewardFee, sellLiquidityFee, sellBurnFee);
    }
    function removeLimits()
        external
        onlyOwner
    {
        limitsInTrade = false;
        _gasLimitActive = false;
        transferDelayEnabled = false;
    }


    function updateTreasuryAddress(address _treasuryAddress, bool _isTreasuryContract) external onlyOwner {
        treasuryAddress = _treasuryAddress;
        isExcludedFromFee[_treasuryAddress] = true;
        excludeFromMaxTransaction(_treasuryAddress, true);
        isTreasuryContract=_isTreasuryContract;
        emit UpdateTreasuryAddress(_treasuryAddress, _isTreasuryContract);
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
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!bots[from] && !bots[to]);
        if (!tradingActive) {
            require(
                isExcludedFromFee[from] || isExcludedFromFee[to],
                "Trading is not active yet."
            );
        }

        if (to != address(0) && to != address(0xDead) && !inSwapAndLiquify) {
            // only use to prevent sniper buys in the first blocks.
            if (_gasLimitActive && automatedMarketMakerPairs[from]) {
                require(
                    tx.gasprice <= _gasPriceLimit,
                    "Gas price exceeds limit."
                );
            }
            if (
                    to != address(pancakeRouter) && to != address(pancakePair)
                ){
                if (transferDelayEnabled) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one transfer per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }
            

            if (limitsInTrade) {
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
        }
        
        bool overMinimumTokenBalance = _liquidityTokensToSwap+_rewardFeeTokens >=
            minimumFeeTokensToTake;

        // Take Fee
        if (
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            balanceOf(pancakePair) > 0 &&
            overMinimumTokenBalance &&
            automatedMarketMakerPairs[to]
        ) {
            takeFee();
        }

        uint256 _rewardFee;
        uint256 _liquidityFee;
        uint256 _burnFee;
        // If any account belongs to isExcludedFromFee account then remove the fee
        if (!inSwapAndLiquify && !isExcludedFromFee[from] && !isExcludedFromFee[to]) {           
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _rewardFee = amount*buyRewardFee/1000;
                _liquidityFee = amount*buyLiquidityFee/1000;
                _burnFee = amount*buyBurnFee/1000;
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _rewardFee = amount*sellRewardFee/1000;
                _liquidityFee = amount*sellLiquidityFee/1000;
                _burnFee = amount*sellBurnFee/1000;
            }
        }

        uint256 _transferAmount = amount-_rewardFee-_liquidityFee-_burnFee;
        super._transfer(from, to, _transferAmount);
        uint256 _feeTotal = _rewardFee+_liquidityFee+_burnFee;
        if (_feeTotal > 0) {
            super._transfer(
                from,
                address(this),
                _feeTotal
            );
            _liquidityTokensToSwap=_liquidityTokensToSwap+_liquidityFee;
            _burnFeeTokens=_burnFeeTokens+_burnFee;
            _rewardFeeTokens=_rewardFeeTokens+_rewardFee;
        }

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
    function takeFee() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensTaken=_liquidityTokensToSwap+_rewardFeeTokens;
        if (totalTokensTaken == 0 || contractBalance <totalTokensTaken) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityTokensToSwap / 2;
        uint256 initialBNBBalance = address(this).balance;
        swapTokensForBNB(tokensForLiquidity);
        uint256 bnbBalance = address(this).balance-initialBNBBalance;
     
        if (tokensForLiquidity > 0 && bnbBalance > 0) {
            addLiquidity(tokensForLiquidity, bnbBalance);
            emit SwapAndLiquify(
                tokensForLiquidity,
                bnbBalance
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

        _liquidityTokensToSwap = 0;
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

    function burnAquasis(uint256 _burnAmount)
        external
        lockTheSwap
        onlyOwner
    {
        require(_burnFeeTokens>=_burnAmount, "Insufficient tokens to burn");
        _burnFeeTokens-=_burnAmount;
        _transfer(address(this), address(0xDead), _burnAmount);
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
    receive() external payable {}
}
