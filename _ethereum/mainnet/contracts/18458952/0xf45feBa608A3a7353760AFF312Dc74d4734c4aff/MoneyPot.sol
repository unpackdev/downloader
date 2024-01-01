// SPDX-License-Identifier: MIT


//
// Moneypot. The Good Pot
//

// https://t.me/moneypotethportal

/* 

Please read carefully:

- You can not sell any tokens you buy. 

- It's better to think of the tokens that you buy as 'tickets'. 

- 50% of the Eth that is used to buy tickets, will be distributed. This 50% is broken down into:
    - 43% reflected, as eth, to current ticket holders.
    - 2% each to the deployer and dev
    - 2% to Cuck holders
    - 1% to the person that calls the function to distribute the eth (called 'getSum')
    
- The other 50% will remain in the liquidity pool. 

- Every buy will add 5 blocks to a timer (Up to a maximum of about 3 days worth of blocks)

- When the timer runs out, the last person to buy will be sent ALL of the LP tokens, and thus effectivly, 
  all of the Eth in the liquidity pool. That is the end prize!

- When the timer runs out, all trading will stop and the only action permitted will be the winner 
  withdrawing the LP, and ticket holders claiming their reflected eth

- You can only buy a whole number of tickets at a time (eg: 1, 2, 3 etc.. - not 1.3 or 3.14)
- You can only buy up to 10 tickets in one TX, but there is no wallet limit. 
- The contract has an automatic pricing function to keep price increases linear, instead of the curve that Uniswap would apply. 
  This allows for an infinite supply. You will see lots of mints/transfers from 0x0 address to the pair address because of this. 

*/
import "./ERC20.sol";
pragma solidity ^0.8;


interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapPair {
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function sync() external;
}

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

// The Middleman contract is created because when the main contract sells tokens for eth
// the pair contract doesn't allow transferring the eth directly back to the token contract, so we need to have a 
// middleman contract.

contract Middleman {
    address immutable wethAddress;
    address immutable MoneyPotAddress;
    IWETH9 private _weth;

    constructor(address _wethAddress, address _MoneyPotAddress){
        wethAddress = _wethAddress;
        MoneyPotAddress = _MoneyPotAddress;
        _weth = IWETH9(_wethAddress);
    }

    function send() public {
        uint256 balance = _weth.balanceOf(address(this));
        if (balance != 0){
            _weth.transfer(MoneyPotAddress, balance);
        }
    }
}

contract MoneyPot is ERC20 {
    // Maps
    // These keep track of the reflected eth balances
    mapping (address => uint256) internal withdrawnDividends;
    mapping (address => uint256) internal magnifiedDividendCorrections;
    mapping (address => uint256) internal lastBlockBuy;

    // Interfaces
    IUniswapRouter private _swapRouter;
    IUniswapPair private _swapPair;
    IWETH9 private _weth;

    // Addresses
    address private _wethAddress;
    address private _swapRouterAddress;
    address private _cuckPairAddress;
    address public swapPairAddress;
    address public lastBuyer;
    address private constant deployer = 0x0A62891336667b540045A10F87B1fd6c0Dadf94f;
    address private constant dev = 0xbb8e9B891a1f8298219bDde868B2EcbEc7f71190;

    // Booleans
    bool private immutable _isToken0;
    bool private reeeeeeee;

    // Numbers
    uint8 private constant _decimals = 18;

    uint256 public maxBlocksAhead = 21600; //3 days ish at 12 second blocks
    uint256 public maxTokensPerTx = 10*10**_decimals;
    uint256 public finishBlock;
    uint256 public tradingStartBlock;
    uint256 public ethToBeSwapped;
    uint256 public totalEthDistributed;

    uint256 public targetPrice = 5000000000000000; //0.005 eth start price
    uint256 public priceIncrease = 500000000000000; //0.005 added to each buy
    uint256 public tokensPurchased = 0;

    uint256 constant internal magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;

    // Starting supply of 40 to match 0.005 price @ 0.2 eth liquidity
    uint256 private startingSupply = 40*10**_decimals; 
 
    bool public gameOver;
    bool private liquidityAdded;


    Middleman public middleman;

    event FinishBlockEvent(uint256 blockNumber);
    event DividendsDistributed(uint256 amount, uint256 totalethToBeSwapped);
    event LastBuyerUpdate(address lastBuyer);
    event EthClaimed(address claimee, uint256 amount);
    
    constructor (
            address swapRouterAddress, 
            address cuckPairAddress, 
            address[] memory airDropRecipients,
            uint256[] memory airDropAmounts
        ) payable ERC20("MoneyPot", "MONEY")  {
        _swapRouter = IUniswapRouter(swapRouterAddress);
        _swapRouterAddress = swapRouterAddress;
        _cuckPairAddress = cuckPairAddress;
        _wethAddress = _swapRouter.WETH();
        _weth = IWETH9(_wethAddress);
        _weth.deposit{value: msg.value}();
        tradingStartBlock = block.number + 6900; // Approx 23 hrs @ 12s blocks
        finishBlock = tradingStartBlock + 3600; // Approx 12 hours after launch
        swapPairAddress = IUniswapFactory(_swapRouter.factory()).createPair(address(this), _wethAddress);
        _swapPair = IUniswapPair(swapPairAddress);
        _isToken0 = address(this) < _wethAddress ? true : false;
        middleman = new Middleman(_wethAddress, address(this));

        // Airdrop V1 recipients
        for(uint i = 0; i < airDropRecipients.length; i++) {
            super._mint(airDropRecipients[i], airDropAmounts[i]);
            tokensPurchased += airDropAmounts[i];
        }
    }


    receive() external payable {
  	}

    // Re entry protection
    modifier reeeeeee {
        require(!reeeeeeee);
        reeeeeeee = true;
        _;
        reeeeeeee = false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingStartBlock < block.number, "Too early");
        require(amount > 0);

        // First off, let's see if the game is over or not
        checkGameIsOver();
        
        if (gameOver){
            // Only the 'winner' can receive tokens after the game is over 
            // This is to allow them to withdraw the liquidity easily. 
            require(to == lastBuyer, "Game is Over. Last Buyer Wins");
        } else {
            // Check that user is buying a whole number of tokens only
            // Uniswap GUI has a rounding error so if you request '1' token
            // it will ask for something slightly off, like 1.000000000000000178.
            // So we round the number slightly to make it work with the modulo check
            uint256 rounded = (amount/200)*200;
            require(rounded >= 1**_decimals, 'Min of 1 ticket buy!');
            require(rounded % (10**_decimals) == 0, "Whole number buys only!");

            // Buys only!
            require(from == swapPairAddress, "No sell for you!");

            // Can't be too greedy!
            require(rounded <= maxTokensPerTx, "Only 10 tokens per TX sers/madams");

            // We know how much the buyer paid in eth due to the difference between the pair contract's weth reserves
            // figure and the actual weth balance. So we take that difference and divide by two to create the 50% "tax"
            // that will be re-distributed to holders when someone calls the getSum function.
            uint wethReserve = _getWethReserve();
            uint pairBalance = IERC20(_swapRouter.WETH()).balanceOf(swapPairAddress); 
            ethToBeSwapped += ((pairBalance - wethReserve)/2);
            tokensPurchased += amount;
            lastBlockBuy[to] = block.number;
            lastBuyer = to;
            emit LastBuyerUpdate(to);
        }
        
        
        // Transfer the tokens using the standard ERC20 transfer function
        super._transfer(from, to, amount);

        //set new target price 
        targetPrice += priceIncrease;
        if (!gameOver){
            setTargetPrice();
            // We add 5 blocks to the countdown timer. 
            // If adding those 5 blocks causes it to exceed the maximum block number ahead, we keep it at max blocks ahead
            // So the the timer can never be longer than max blocks ahead.
            finishBlock = (finishBlock + 5)-block.number >= maxBlocksAhead ? block.number + maxBlocksAhead : finishBlock + 5;
            emit FinishBlockEvent(finishBlock);
        }       
    }

    // 
    // Public Functions
    //

    // Anyone can call this, and get paid 1% of the eth to be swapped for doing so. 
    function getSum() public payable reeeeeee {

        // Make sure there is something to be swapped, unless it's the final getSum check 
        require(ethToBeSwapped > 0 || gameOver, 'No eth to be swapped');

            
        // Figure out how much (w)eth is in the liquidity pool
        uint wethReserve;
        uint tokenReserve;
        {
            (uint reserve0, uint reserve1,) = _swapPair.getReserves();
            (wethReserve, tokenReserve) = _isToken0 ? (reserve1, reserve0) : (reserve0, reserve1);
        }
        
        // Figure out how many tokens to send (mint) to the pool to get the equivelent eth back
        // This code is pretty much the same as what is in the uniswap libraries
        // https://docs.uniswap.org/contracts/v2/reference/smart-contracts/library#getamountin
        uint numerator = tokenReserve*ethToBeSwapped*1000;
        uint denominator = (wethReserve-ethToBeSwapped)*997;
        uint amountIn = (numerator / denominator)+1;
        super._mint(swapPairAddress, amountIn);

        // Swap the now minted tokens that are in the liquidity pool for eth, sending it to the middle man contract 
        // See line 169 of the uniswap pair code as to why we need the middleman contract:
        // https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
        // (Most contracts that have a swapBack kind of function use the uniswap router contract to execute the trade
        // which is why they dont need the middleman contract. Moneypot is better than that.
        (uint amount0Out, uint amount1Out) = _isToken0 ? (uint(0), ethToBeSwapped) : (ethToBeSwapped, uint(0));
        _swapPair.swap(amount0Out,amount1Out,address(middleman),new bytes(0));
        
        // Ask the middleman to pretty please send the weth back to us.
        middleman.send();
        ethToBeSwapped = 0;

        uint bal = _weth.balanceOf(address(this));

        //Send some weth to Cuck token LP
        uint cuckAmount = (bal*2)/100;
        _weth.transfer(_cuckPairAddress, cuckAmount);
        IUniswapPair(_cuckPairAddress).sync();
        
        // Unwrap Weth for Eth and distribute to ticket holder balances
        uint256 remainingAmount = bal-cuckAmount;
        _weth.withdraw(remainingAmount);
        _distribute(remainingAmount);

        // Make sure the price is at or near our target price.
        setTargetPrice();
        _swapPair.sync();

    }

    function checkGameIsOver() public returns (bool gameIsOver){
        if(!gameOver){
            if(block.number >= finishBlock){
                 //Call getsum for the last time
                gameOver = true;
                getSum();
            }
        } 
        return gameOver;
    }

    // This function needs to be called to send the winnings to the winner
    // You might have to call checkGameIsOver first.
    function chickenDinner() public {
        require(gameOver);
        uint256 lpBalance = _swapPair.balanceOf(address(this));
        if (lpBalance != 0){
            // Transfer LP tokens to the LP pair, ready for calling the burn function
            _swapPair.transfer(swapPairAddress, lpBalance);
            // The burn function of the LP pair contract burns the LP tokens and sends all WETH and Tokens 
            // in the pair contract to the lastBuyer address
            _swapPair.burn(lastBuyer);
        }
    }

    function claim() public reeeeeee {
        // Calculate how much sers/maaaams can have
        uint256 _withdrawableDividend = withdrawableDividendOf(msg.sender);
        require(_withdrawableDividend > 0);
        require(lastBlockBuy[msg.sender] < block.number, 'Can not claim in same block as last buy');
        withdrawnDividends[msg.sender] += _withdrawableDividend;
        bool success = _safeSend(msg.sender, _withdrawableDividend);
        require(success, 'Failed to send eth');
        emit EthClaimed(msg.sender, _withdrawableDividend);
    }

    // Can only be called once
    function addLiquidity() public {
        require(!liquidityAdded);
        _weth.transfer(swapPairAddress, _weth.balanceOf(address(this)));
        super._mint(swapPairAddress, startingSupply);
        _swapPair.mint(address(this));
        liquidityAdded = true;
    }

    function withdrawableDividendOf(address _owner) public view returns(uint256) {
        return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns(uint256) {
        return (magnifiedDividendPerShare*balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude;
    }

    //
    // Private Functions 
    // 

    // distribute eth to dev and to hodlers, 1% of eth distributed goes to whoever calls it
    function _distribute(uint256 amount) private {
        require(tokensPurchased > 0);
        require(amount > 0);

        // Calculate tax for dev/deployer
        // div by 50 cause 'amount' is 50% of the eth revenue, so div'ing by 100 would equate to 1%, not 2%.
        uint256 taxLol = (amount*2)/50; 

        // Calculate 1% reward for whoever calls this function
        uint256 reward = (amount*1)/100;

        // Send tax
        bool dev1Success = _safeSend(deployer, taxLol);
        bool dev2Success =_safeSend(dev, taxLol);
        bool rewardSuccess = _safeSend(_msgSender(), reward);
        
        require(dev1Success && dev2Success && rewardSuccess, 'Failed to distribute');

        // Distribute what remains to holders
        uint256 dividends = amount-reward-(taxLol*2);
        totalEthDistributed += dividends;
        magnifiedDividendPerShare += (dividends*magnitude) / tokensPurchased;
        emit DividendsDistributed(dividends, totalEthDistributed);
        
    }

    function _getWethReserve() private view returns (uint wethReserve){
        (uint reserve0, uint reserve1,) = _swapPair.getReserves();
        return wethReserve = _isToken0 ? reserve1 : reserve0;
    }

    // Self explanatory. I was having a bad day.
    function _fuckingUintToIntconverterBullshitIHateLifeSometimes(uint cock, uint balls) private pure returns (uint, bool) {
        return cock >= balls ? (uint(cock - balls), true) : (uint(balls - cock),false);
    }

    // Set the trading pair price back down to the target price if the price goes above teh target price
    // Side note: If you buy max tokens (10) at a time, you may be paying more than if you bought them 
    // one at a time...because of this function!
    function setTargetPrice() internal {
        // We do this by adding (minting) tokens into the swap pair contract 
        // This effectivly decreases the price per token
        uint256 wethBalance = _weth.balanceOf(swapPairAddress);
        uint256 currentBalance = balanceOf(swapPairAddress);
        uint256 targetBalance = (wethBalance*10000)/((targetPrice*10000)/(10**_decimals));

        (uint256 diff, bool positive) = _fuckingUintToIntconverterBullshitIHateLifeSometimes(targetBalance, currentBalance);

        if (diff != 0 && positive){
            super._mint(swapPairAddress, diff);
        }
    }

    function _safeSend(address recipient, uint256 value) private returns(bool success){
        (success,) = recipient.call{value: value}("");
    }
    
}