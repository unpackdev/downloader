// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./safeMath.sol";
import "./Vote.sol";
import "./Staking.sol";


/**
                        .:^~~110~^^:.                                                    
                   .~?5G#&@@@@@@@&&#BPJ7^.                                               
                .!5#@@@@@@@&&&&###BBGGPP5J7^.                                            
              .J#@@@@&&&###BBGGP55YJJ?7!!~~~^.                                           
             7#@@&&&&##BBGPP5YJ?7!~~^::...                                               
            Y@@&&&&##BBGP5YJ7!~^::...                                                    
           5@&&&&###BGP5J?!~^:..                                                         
          !@&&&&##BGPYJ7~^:.                                                             
          P@&&#GPYY5Y7~:.                                                                
         .B#P?~:.  :75GP7:                                                               
          ^P!         :Y&&5^              .:.                                            
          :B#5!:.::.....^G@@5:           ..:..                                           
         ^#&BBG5P#BGPPYJ!^?&@&?              ..                                          
        !&&#BBBBB##BGPY7^. ^G@@P:            :.                                          
      .5@##BBP5GBBGP5Y7^:    J@@&7           .                                           
      ^J^::^: :GGGP5J7~:      ^P@@P^                                                     
          :!~^7GGP5Y?~:         ^5&@P!.                                                  
         7BGGGGGP5J?!^.           .!YGPJ~:                                               
         :^^^:^~!7!~^..               .:::                                               
         :55Y?J7!~^:.                                                                    
            :YGP5J!^.                                                                    
           ^B#G5J7~:.                                                                    
           :J7!~^:.


        We are Passive Spectators
        In Code We Trust, In Community We Thrive.

        Website: https://passivespectators.link
        Twitter: https://twitter.com/Passive_110
        Telegram: https://t.me/PassiveSpectators
        Mirror: https://mirror.xyz/thelasthumanoid.eth         
 **/   



pragma experimental ABIEncoderV2;

contract Pass is ERC20, Ownable, Pausable, Vote, StakingContract {
    
   function pause() public onlyOwner {
        require(!paused(), "ERC20: Contract is already paused");
        _pause();
   }
   function unPause() public onlyOwner {
        require(paused(), "ERC20: Contract is not paused");
        _unpause();
    }

    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public TreasuryWallet;

    uint256 public maxTxAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 private buyTreasuryFee;
    uint256 private buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 private sellTreasuryFee;
    uint256 private sellLiquidityFee;

    uint256 private tokensForTreasury;
    uint256 private tokensForLiquidity;
    uint256 private previousFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;
   
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event TreasuryWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(string memory name,string memory symbol,uint256 supply) ERC20(name, symbol) {
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
         );

         excludeFromMaxTransaction(address(_uniswapV2Router), true);
         uniswapV2Router = _uniswapV2Router;

         uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
             .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyTreasuryFee = 25;
        uint256 _buyLiquidityFee = 0;

        uint256 _sellTreasuryFee = 30;
        uint256 _sellLiquidityFee = 0;

        uint256 totalSupply = supply * 1e18;


        maxTxAmount = (totalSupply *2) / 100;
        maxWallet = (totalSupply *2) / 100;
        swapTokensAtAmount = (totalSupply * 5) / 10000;

        buyTreasuryFee = _buyTreasuryFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTotalFees = buyTreasuryFee + buyLiquidityFee;

        sellTreasuryFee = _sellTreasuryFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTotalFees = sellTreasuryFee + sellLiquidityFee;
        previousFee = sellTotalFees;

        TreasuryWallet = address(0x1e6B3AA66AaCDFd341afCe7233d75741dCD50FcE);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, totalSupply);
      
    } 

    function _vote(uint proposal) public whenNotPaused{
        Voter storage sender = voters[msg.sender][proposalNum];
        require(balanceOf(msg.sender) > 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposalNum][proposal].voteCount += balanceOf(msg.sender);
    }

    function _setNewProposals(string[] memory proposalNames) public onlyOwner {
        proposalNum++;
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals[proposalNum].push(Proposal({
                proposal: proposalNames[i],
                voteCount: 0
            }));
        }
       
    }
    function _deleteProposals(uint num) public onlyOwner  {
       delete proposals[num];
    } 

    function deposit(uint amount) public whenNotPaused{
        require(amount <= balanceOf(msg.sender), "Not enough tokens in your wallet, please try lesser amount");
        transfer(address(this), amount);    
        _deposit(msg.sender , amount);
    }

    function withdraw() public whenNotPaused{
         ERC20(address(this)).transfer(msg.sender, rewardCalculation(msg.sender));
         _withdraw(msg.sender);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner{
        tradingActive = true;
        swapEnabled = true;
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

    function updateMaxWalletAndTxnAmount(uint256 newTxnNum, uint256 newMaxWalletNum) external onlyOwner {
        require(
            newTxnNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxTxn lower than 0.5%"
        );
        require(
            newMaxWalletNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newMaxWalletNum * (10**18);
        maxTxAmount = newTxnNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateBuyFees(
        uint256 _TreasuryFee,
        uint256 _liquidityFee
    ) external onlyOwner {
        buyTreasuryFee = _TreasuryFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyTreasuryFee + buyLiquidityFee;
        require(buyTotalFees <= 35, "Must keep fees at 35% or less");
    }

    function updateSellFees(
        uint256 _TreasuryFee,
        uint256 _liquidityFee
    ) external onlyOwner {
        sellTreasuryFee = _TreasuryFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellTreasuryFee + sellLiquidityFee;
        previousFee = sellTotalFees;
        require(sellTotalFees <= 35, "Must keep fees at 35% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
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

    function _setAutomatedMarketMakerPair(address pair, bool value) private whenNotPaused(){
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
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

                if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
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
                        amount <= maxTxAmount,
                        "Buy transfer amount exceeds the maxTxAmount."
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
                        amount <= maxTxAmount,
                        "Sell transfer amount exceeds the maxTxAmount."
                    );
                } 
                
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForTreasury += (fees * sellTreasuryFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForTreasury += (fees * buyTreasuryFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
        sellTotalFees = previousFee;

    }

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            deadAddress,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForTreasury;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForTreasury = ethBalance.mul(tokensForTreasury).div(
            totalTokensToSwap
        );

        uint256 ethForLiquidity = ethBalance - ethForTreasury;

        tokensForLiquidity = 0;
        tokensForTreasury = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success, ) = address(TreasuryWallet).call{value: address(this).balance}("");
    }
}