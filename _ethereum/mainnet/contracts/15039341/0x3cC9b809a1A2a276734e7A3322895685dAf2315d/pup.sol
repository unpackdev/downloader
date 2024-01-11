// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.2;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";
import "./ERC20VotesCompUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

/*
    Twitter: https://twitter.com/pupsdao_

    What is PUPS.DAO? It is the first revolutionary doge dao. It consists of governance, game, and nfts.

    PUPS DAO seeks to fast forward the collapse of the global economic order and to fund the revolutionaries seeking the same goal.

    The top 100 PUP stakers are The Guardians.
    These Guardians can submit proposals to the DAO, but they cannot influence the vote. The votes can be made by all PUP stakers who are not Guardians. 
    Votes pass based on token share Yes vs No.

    These proposals put forward should be requests for investment from protocols which match all or most of the below criteria;
    -Fight Against Centralisation 
    -Further the Cause of Decentralisation
    -Directly Benefit a Noble Cause

    The DAO can then vote on whether they believe the investment should be granted. 
    There is also a burning mechanism in place that works as an incentive.
    For every 20000USDC worth of PUP raised, 5000USDC worth of PUP is burned, and 15000USDC worth of PUP goes to the investee protocol or cause.
    The investee token is redistributed as per the proposal, with the full distribution swapped to the PUP token at the agreed rates of dispursement. 
    E.g. once a day, week or month.
    50% of that PUP is immediately sent to a burn wallet, with the other 50% redistributed proportionally to all stakers of PUP.

    Tokenomics:
    - Total supply: 2 billion
    - MAX BUY: 80 Million
    - MAX SELL: 80 Million
    - BUY FEE: 0.25% 
    - SELL FEE: 4%
*/

interface ITreasury {
    function validatePayout() external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);

    function factory() external pure returns (address);
}

contract PUP is Initializable,UUPSUpgradeable,ERC20Upgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable,ERC20VotesCompUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;

    address public govTreasury;
    address public gameTreasury;
    address public nftTreasury;

    uint256 public totalSupplyAmount;
    uint256 public totalFees;

    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public taxFee;

    mapping(address => uint256) private sellcooldown;

    mapping(address => bool) public whitelistedAddress;
    mapping(address => bool) public automatedMarketMakerPairs;

    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;
    bool public tradingIsEnabled;

    address public USDC;
    address public devWallet;

    uint256 public maxWalletToken; 
    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;

    event TaxUpdated(uint256 _buy, uint256 _sell);
    event WhitelistAddressUpdated(address whitelistAccount, bool value);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event DevWalletUpdated(address indexed newDevWallet, address indexed oldDevWallet);
    event TreasuryAddressUpdated(address _govTreasury, address _gameTreasury, address _nftTreasury);
    
    function initialize(        
        address initialHolder,
        uint256 initialSupply
        ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ERC20Upgradeable.__ERC20_init("PUPS DAO", "PUP");
        ERC20PermitUpgradeable.__ERC20Permit_init("pup");
        ERC20VotesUpgradeable.__ERC20Votes_init_unchained();
        __Pausable_init_unchained();
        ERC20VotesCompUpgradeable.__ERC20VotesComp_init_unchained();
        _mint(initialHolder, initialSupply);

        tradingIsEnabled = false;

        govTreasury = address(0xdead);
        gameTreasury = address(0xdead);
        nftTreasury = address(0xdead);
        
        USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        devWallet = 0x5F9368460537e25D95FB355BC667a02FcC94cD93;

        totalSupplyAmount = initialSupply;

        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Create a uniswap pair for this new token
        address _uniswapUSDCPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), USDC);
        address _uniswapWETHPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapUSDCPair;

        _setAutomatedMarketMakerPair(_uniswapUSDCPair, true);
        _setAutomatedMarketMakerPair(_uniswapWETHPair, true);

        // exclude from paying fees or having max transaction amount
        setWhitelistAddress(devWallet, true);
        setWhitelistAddress(initialHolder, true);
        setWhitelistAddress(address(this), true);
    }

    function afterPreSale() external onlyOwner {
        tradingIsEnabled = true;

        buyTax = 25; // 0.25%
        sellTax = 400; // 4%

        swapTokensAtAmount = totalSupplyAmount.mul(1).div(10000);
        maxBuyTransactionAmount = totalSupplyAmount.mul(4).div(100);
        maxSellTransactionAmount = totalSupplyAmount.mul(4).div(100);
        maxWalletToken = totalSupplyAmount.mul(4).div(100);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        ERC20VotesUpgradeable._afterTokenTransfer(from, to, amount);
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

    function getTotalFees() external view returns(uint256) {
        return totalFees;
    }

    function setTreasuryAddress(address _govTreasury, address _gameTreasury, address _nftTreasury) external onlyOwner{
        require(_govTreasury != address(0) && _gameTreasury != address(0) && _nftTreasury != address(0), "setTreasuryAddress: Zero address");
        govTreasury = _govTreasury; gameTreasury = _gameTreasury; nftTreasury = _nftTreasury;
        whitelistedAddress[_govTreasury] = true; whitelistedAddress[_gameTreasury] = true; whitelistedAddress[_nftTreasury] = true;
        emit TreasuryAddressUpdated(_govTreasury, _gameTreasury, _nftTreasury);
    }

    function setWhitelistAddress(address _whitelist, bool _status) public onlyOwner{
        require(_whitelist != address(0), "setWhitelistAddress: Zero address");
        whitelistedAddress[_whitelist] = _status;
        emit WhitelistAddressUpdated(_whitelist, _status);
    }

    function setTax(uint256 _buyTax, uint256 _sellTax) external onlyOwner{
        require(_buyTax < 100 && _sellTax < 1000, "Sell Tax must be lower than 1% and buy tax must be lower than 10%");
        buyTax = _buyTax; sellTax = _sellTax;
        emit TaxUpdated(_buyTax, _sellTax);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The DEX pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _maxSupply() internal view virtual override(ERC20VotesCompUpgradeable,ERC20VotesUpgradeable) returns (uint224) {
        return type(uint224).max;
    }

    function _authorizeUpgrade(address) internal view override {
        require(owner() == msg.sender, "Only owner can upgrade implementation");
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override{      
        bool excludedAccount  = whitelistedAddress[sender] || whitelistedAddress[recipient];

        if (!tradingIsEnabled && !excludedAccount){
            require(!automatedMarketMakerPairs[sender] && !automatedMarketMakerPairs[recipient] , "You cannot add liquidity before the trading active.");
        }

        if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[sender] &&
            !excludedAccount
        ) {
            require(
                amount <= maxBuyTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
        } else if (
        	tradingIsEnabled &&
            automatedMarketMakerPairs[recipient] &&
            !excludedAccount
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap) {
                swapping = true;

                swapTokensForUSDC(contractTokenBalance, devWallet);

                liqBurnOrTreasuries(contractTokenBalance);

                swapping = false;
            }
        }

        bool takeFee = tradingIsEnabled && !swapping && !excludedAccount;

        if(takeFee) {
            if(automatedMarketMakerPairs[sender]){
                // Buy tokens
                taxFee = amount.mul(buyTax).div(10000);
                super._transfer(sender, govTreasury, taxFee);
            }else if(automatedMarketMakerPairs[recipient]) {
                require(sellcooldown[sender] < block.timestamp);

                sellcooldown[sender] = block.timestamp + (10 seconds);

                //Sell tokens
                taxFee = amount.mul(sellTax).div(10000);
                super._transfer(sender, govTreasury, taxFee.div(2));
                super._transfer(sender, address(this), taxFee.div(2));
            }

        	amount = amount.sub(taxFee);

            if (govTreasury != address(0xdead))
                ITreasury(govTreasury).validatePayout();
        }
        
        super._transfer(sender, recipient, amount);
    }

    function swapTokensForUSDC(uint256 _tokenAmount, address _recipient) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            _recipient,
            block.timestamp
        );
    }

    function updateMaxAmounts(uint256 _maxWallet, uint256 _maxBuyAmount, uint256 _maxSellAmount, uint256 _swapAmount) external onlyOwner {
        maxWalletToken = _maxWallet * (10**18); 
        maxBuyTransactionAmount = _maxBuyAmount * (10**18);
        maxSellTransactionAmount = _maxSellAmount * (10**18);
        swapTokensAtAmount = _swapAmount * (10**18);
    }

    function updateDevWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != devWallet, "The dev wallet is already this address");
        devWallet = _newWallet;
        setWhitelistAddress(_newWallet, true);
        emit DevWalletUpdated(devWallet, _newWallet);
  	}

    function liqBurnOrTreasuries(uint256 _tresuaryAmount) internal {
        // pull tokens from pancakePair liquidity and move to dead address or treasuries.
        if (_tresuaryAmount > 0){
            super._transfer(uniswapV2Pair, gameTreasury, _tresuaryAmount.div(2));
            super._transfer(uniswapV2Pair, nftTreasury, _tresuaryAmount.div(2));

            if (gameTreasury != address(0xdead))
                ITreasury(gameTreasury).validatePayout();

            if (nftTreasury != address(0xdead))
                ITreasury(nftTreasury).validatePayout();
        }
        
        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
    }

    receive() external payable {}

    function manualToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function manualWETH(address _recipient) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        (bool success, ) = _recipient.call{ value: contractETHBalance }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}