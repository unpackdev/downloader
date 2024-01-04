// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./Lists.sol";
import "./Rewards.sol";

/**
 * @title A Liquidity Game
 * @notice Implementation of a game which rewards the top half of liquidity providers.
 * 
 * Users interact with the contract through three public state-changing functions, which are different paths to the same goal:
 * lock Token-ETH LP tokens into the system, and track metrics around those LP locks.
 * 
 *   1. `provideLiquidity` accepts Tokens and ETH, and adds them to the Uniswap Pair, which creates fresh LP tokens
 *   2. `depositLP` accepts existing Token-ETH LP tokens
 *   3. `purchaseTokensAndDepositLP` accepts ETH, market buys a small amount of Tokens on Uniswap, then mints new Tokens,
 *      and finally adds Tokens and ETH to the Uniswap Pair, which creates fresh LP tokens
 * 
 * Each user has a score, which can only increase over time as they interact with the contract, because the only action is to
 * add more liquidity. A user's score is simply the total amount of LP tokens that they've locked into the system, via the
 * three functions listed above.
 * 
 * The system keeps track of two equally-sized, sorted lists. Each entry in the list contains a user's address and their current score.
 * Every time a score is created or updated, the lists are re-balanced and re-sorted. See `Lists.sol` for the implementation.
 * 
 * When the game is over, the system sucks as much liquidity out of the Uniswap Pair as possible, and then distributes the 
 * collected Ether to all participants. The amount of Ether reward that any given user receives is dependent on a few factors:
 *
 *   1. how much liquidity they've added to the system
 *   2. how much liquidity everyone else has added to the system
 *   3. which list they're on ("top half of all scores" list, or "bottom half of all scores" list)
 * 
 * At a high level, this is how the rewards are collected (liquidity is removed):
 * 
 *   1. Call Uniswap Router's `removeLiquidityETH` with all of the LP tokens that this system controls, sending all
 *      rewards (Tokens and Ether) back here.
 *   2. For all of the Tokens that now belong to the system, call Uniswap Router's `swapExactTokensForETH`, which
 *      forces out more ETH that may have existed in liquidity (due to people manually adding liquidity and not
 *      playing this game).
 *   3. Now the system contains a bag of Ether, which are used for rewards.
 * 
 * At a high level, calculating the rewards for any given user at any given time works like this:
 * 
 *   1. If the game is not over, then the reward calculation logic "pretends" that the game is ending at that moment,
 *      and performs read-only logic on the above process. So, from the point of view of the caller, it makes no difference
 *      if the game is over or not when calculating rewards for an account. The only difference is that DURING gameplay,
 *      a user's calculated rewared will change every time score state changes, but once the game is over a user's rewards
 *      become fixed. So, we can assume we know the "total Ether for rewards" for the rest of this calculation.
 *   2. Initially, the Total Ether Rewards are split between the "winning list" and the "losing list" (denoted in code as
 *      "positive list" and "negative list"). That initial split is completely determined by the relative total scores of
 *      the two lists. For example, if the sum of all scores in the Positive List is 70, and the sum of all scores in the
 *      Negative List is 30, (total score of 100 between the two lists) and the total Ether rewards are 10 ETH, then
 *      70 / 100 * 10 ETH = 7 ETH belong to the Positive List and 30 / 100 * 10 ETH = 3 ETH belong to the Negative List.
 *   3. Next, an owner-defined percentage of the Negative List rewards is TAKEN from the Negative List and GIVEN to the
 *      Positive List. For example (continuing from above example), if that owner-defined percentage is 50%, then
 *      3 ETH * 0.5 = 1.5 ETH will be subtracted from the Negative List (leaving that list with 3 ETH - 1.5 ETH = 1.5 ETH),
 *      and added to the Positive List (leaving that list with 7 ETH + 1.5 ETH = 8.5 ETH).
 *   4. Finally, a user's reward is calculated as their percentage of their lists's total score, multiplied by the rewards
 *      that belong to that list. For example (continuing from the above example), if a user is on the Positive List with a
 *      score of 14, then they account for 14 / 70 = 20% of that list, so they'll receive 8.5 ETH * 0.2 = 1.7 ETH as reward.
 *      If a user is on the Negative List with a score of 3, then they account for 3 / 30 = 10% of that list, so they'll
 *      receive 1.5 ETH * 0.1 = 0.15 ETH as reward.
 *
 * @dev Inherits from the `Lists` contract, which houses all implementation of the two weighted, sorted list management
 */
contract Game is Lists, ERC20, Ownable {
    using SafeMath for uint256;

    uint256 constant MAX_MARKET_PURCHASE = 10**18 / 2; // 50%

    /**
     * @notice The timestamp at which the game is over. No more score-increasing functions are callable after this time.
     */
    uint256 public immutable endTime;

    bool private _distributed;
    uint256 private _totalRewards;

    /**
     * @notice Tracks whether or not an account has claimed their rewards.
     */
    mapping(address => bool) public claimedRewards;

    /**
     * @notice Addresses of the Uniswap Factory and Router
     */
    IUniswapV2Factory public immutable uniswapV2Factory;
    IUniswapV2Router02 public immutable uniswapV2Router;

    // Used to calculate the fraction of rewards that are taken from the negative list, and given to positive list
    // Note: the "_negativeWeight" value is used as the numerator in a calculation with the denominator equaling 10e18
    uint256 private _negativeWeight;

    // Used to determine how much input Ether is used to market-buy Token on Uniswap
    // Note: the "marketPurchase" value is used as the numerator in a calculation with the denominator equaling 10e18
    uint256 public marketPurchase;

    /**
     * @notice Instance of the contract where all value (ETH / Tokens) is held
     */
    Rewards public rewards;

    // Minimum acceptable values for deposit
    uint256 public minEthers;
    uint256 public minLpTokens;

    event ProvidedLiquidity(address indexed account, address indexed forAccount, uint256 scoreIncrease, uint256 newScore, uint256 newPayout);
    event DepositedLP(address indexed account, address indexed forAccount, uint256 scoreIncrease, uint256 newScore, uint256 newPayout);
    event PurchasedGameTokensAndDepositedLP(address indexed account, address indexed forAccount, uint256 scoreIncrease, uint256 newScore, uint256 newPayout);
    event SplitAdjusted(uint256 newNegativeWeight);
    event MarketPurchaseAdjusted(uint256 newMarketPurchase);
    event MinEthersAdjusted(uint256 newMinEthers);
    event MinLpTokensAdjusted(uint256 newMinLpTokens);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialMint,
        address mintOwner,
        IUniswapV2Router02 _uniswapV2Router,
        uint256 _endTime,
        uint256 negativeWeight,
        uint256 _marketPurchase,
        uint256 _minEthers,
        uint256 _minLpTokens
    ) ERC20(_name, _symbol) {
        require(marketPurchase <= MAX_MARKET_PURCHASE, "Game: attemping to set purchase percentage > 50%");
        require(negativeWeight <= 10**18, "Game: attemping to set split weigth > 100%");
        require(_endTime > block.timestamp, "Game: attemping to set endTime value less than or equal to now");

        // mint the initial set of tokens
        _mint(mintOwner, _initialMint * (uint256(10)**decimals()));

        // save (and derive) the uniswap router and factory addresses
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());

        // save the rest of the initial contract state variables
        endTime = _endTime;
        _negativeWeight = negativeWeight;
        marketPurchase = _marketPurchase;

        // deploy an instance of the Rewards contract, making this contract it's "owner"
        rewards = new Rewards(address(this), _uniswapV2Router, _endTime);

        minEthers = _minEthers;
        minLpTokens = _minLpTokens;

        // MAX_UINT256 approval
        _approve(address(rewards), address(_uniswapV2Router), 2**256 - 1); 
    }

    /**
     * @notice reverts if there is not yet an existing Uniswap pair for this Token and Ether
     */
    modifier pairExists() {
        require(getUniswapPair() != address(0), "Game::pairExists: pair has not been created");
        _;
    }

    /**
     * @notice reverts if the endTime has passed, which indicates that the game is over
     */
    modifier active() {
        require(endTime > block.timestamp, "Game::active: game is over! distribute and claim your rewards");
        _;
    }

    /**
     * @notice reverts if the endTime has not passed, which indicates that the game is still being played
     */
    modifier over() {
        require(endTime <= block.timestamp, "Game::over: game is still active");
        _;
    }

    /**
     * @notice Accept any amount of Token and Ether, add as much liquidity to Uniswap as possible, refund any leftovers
     * @param tokenAmount the amount of Tokens to attempt to add as liquidity
     * @param account the account which should receive points
     * @dev Payable function accepts Ether input, will attempt to add all of it as liquidity
     * @dev Requires that the user has previously `approve`d Token transfers for this contract
     * @return scoreIncrease the delta between an account's old score, and their score after this function is complete
     * @return newScore the account's new score, after increasing it
     * @return newPayout the account's new payout amount
     */
    function provideLiquidity(uint256 tokenAmount, address account) pairExists active public payable returns (uint256 scoreIncrease, uint256 newScore, uint256 newPayout) {
        // send `tokenAmount` number of tokens from msg.sender to the `rewards` contract
        _transfer(msg.sender, address(rewards), tokenAmount);

        // add as much liquidity to Uniswap Pair as possible
        // function returns with the actual amount of Tokens and Eth added, since it safely adds liquidity at the current price ratio
        // the `addLiquidityETH` call is proxied to the `rewards` contract, which is where the new LP tokens will belong to
        (uint256 amountTokenAdded, uint256 amountEthAdded, uint256 liquidity) = rewards.addLiquidityETH{ value: msg.value }(tokenAmount);

        // since there will likely be a small amount of either Tokens or Ether leftover, refund that back to the msg.sender
        refund(msg.sender, tokenAmount, msg.value, amountTokenAdded, amountEthAdded);

        // an account's score is directly calculated by the amount of liquidity tokens they've created for the game
        scoreIncrease = liquidity;
        newScore = addScore(account, scoreIncrease);

        // get the updated reward payout information for the account
        newPayout = getAccountRewards(account);

        emit ProvidedLiquidity(msg.sender, account, scoreIncrease, newScore, newPayout);
    }

    /**
     * @notice Accept any amount of Uniswap Token-ETH LP tokens
     * @param tokenAmount the amount of Uniswap Token-ETH LP tokens to take control of
     * @param account the account which should receive points
     * @dev Requires that the user has `approve`d this contract to be able to spend their Uniswap Token-ETH LP tokens
     * @return scoreIncrease the delta between an account's old score, and their score after this function is complete
     * @return newScore the account's new score, after increasing it
     * @return newPayout the account's new payout amount
     */
    function depositLP(uint256 tokenAmount, address account) pairExists active public returns (uint256 scoreIncrease, uint256 newScore, uint256 newPayout) {
        require(tokenAmount >= minLpTokens, "Game::depositLP: LP token amount below minimum");

        // grab the Uniswap pair address and cast it into an IUniswapV2Pair instance...
        IUniswapV2Pair pair = IUniswapV2Pair(getUniswapPair());
        // ...so that we can `transferFrom` the tokens to the `rewards` contract
        pair.transferFrom(msg.sender, address(rewards), tokenAmount);

        // an account's score is directly calculated by the amount of liquidity tokens they've given to the game
        scoreIncrease = tokenAmount;
        newScore = addScore(account, scoreIncrease);

        // get the updated reward payout information for the account
        newPayout = getAccountRewards(account);

        emit DepositedLP(msg.sender, account, scoreIncrease, newScore, newPayout);
    }

    /**
     * @notice Accept any amount of Ether, market buy some Tokens, mint more Tokens, add liquidity
     * @param account the account which should receive points
     * @param minTokensToPurchased The minimum amount of GAME tokens that must be received from the ETH->GAME purchase
     * @dev Payable function accepts Ether input
     * @return scoreIncrease the delta between an account's old score, and their score after this function is complete
     * @return newScore the account's new score, after increasing it
     * @return newPayout the account's new payout amount
     */
    function purchaseTokensAndDepositLP(address account, uint256 minTokensToPurchased) pairExists active public payable returns (uint256 scoreIncrease, uint256 newScore, uint256 newPayout) {
        require(msg.value >= minEthers, "Game::purchaseTokensAndDepositLP: ETH amount below minimum");

        // of the Ether passed in, calculate a small piece of it to be used for market buying tokens on Uniswap
        // we do this beacuse we want to have the optics of continued market buying
        uint256 ethForMarket = msg.value.mul(marketPurchase).div(10**18);
        uint256 ethForLiquidity = msg.value.sub(ethForMarket);

        // use the Ether reserved for the market buy, to do a market buy
        // hold onto the number of tokens that were purchased
        // these tokens that were purchased, belong to the `rewards` contract
        uint256 tokensPurchased = rewards.swapExactETHForTokens{ value: ethForMarket }(minTokensToPurchased);

        // get a quote for the number of tokens that are currently "equivalent" to the remaining Ether
        IUniswapV2Pair pair = IUniswapV2Pair(getUniswapPair());
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        uint256 tokensForLiquidity = uniswapV2Router.quote(
            ethForLiquidity,
            pair.token0() == uniswapV2Router.WETH() ? _reserve0 : _reserve1,
            pair.token1() == uniswapV2Router.WETH() ? _reserve0 : _reserve1
        );

        // calculate the "difference" -- that is, the amount of tokens that the `rewards` contract needs
        // which are equal to the token number we just calculated
        if (tokensForLiquidity > tokensPurchased) {
            // (stack too deep, so did an inline calculation to determine `tokensToMint`, the second argument of _mint)
            // mint those tokens and give them to the `rewards` contract (which also contains the Tokens received from the above swap)
            _mint(address(rewards), tokensForLiquidity.sub(tokensPurchased));
        } else if (tokensForLiquidity < tokensPurchased) {
            // Use `tokensPurchased` for liquidity if it's greater than `tokensForLiquidity`
            tokensForLiquidity = tokensPurchased;
        }

        // add as much liquidity to Uniswap Pair as possible
        // function returns with the actual amount of Tokens and Eth added, since it safely adds liquidity at the current price ratio
        // the `addLiquidityETH` call is proxied to the `rewards` contract, which is where the new LP tokens will belong to
        (uint256 amountTokenAdded, uint256 amountEthAdded, uint256 liquidity) = rewards.addLiquidityETH{ value: ethForLiquidity }(tokensForLiquidity);

        // since there will likely be a small amount of either Tokens or Ether leftover, refund that back to the msg.sender
        refund(msg.sender, tokensForLiquidity, ethForLiquidity, amountTokenAdded, amountEthAdded);

        // an account's score is directly calculated by the amount of liquidity tokens they've created for the game
        scoreIncrease = liquidity;
        newScore = addScore(account, scoreIncrease);

        // get the updated reward payout information for the account
        newPayout = getAccountRewards(account);

        emit PurchasedGameTokensAndDepositedLP(msg.sender, account, scoreIncrease, newScore, newPayout);
    }

    /**
     * @notice Perform simple subtractions to determine if there is any leftover Tokens and Ether, and transfers that value to the specified account
     * @dev The SafeMath subtractions in here are safe, since it's not possible for `amount...Added` to be greater than `...amount`
     * @dev There is an assumption that this function is called after adding liquidity, and not all of the input value was used
     * @param to the account to send refunded Tokens or Ether to
     * @param tokenAmount the amount of Tokens that were attempted to be added to liquidity
     * @param ethAmount the amount of Ether that were attempted to be added to liquidity
     * @param amountTokenAdded the amount of Tokens that were actually added to liquidity
     * @param amountEthAdded the amount of Ether that were actually added to liquidity
     */    
    function refund(address payable to, uint256 tokenAmount, uint256 ethAmount, uint256 amountTokenAdded, uint256 amountEthAdded) private {
        // calculate if there is any "leftover" Tokens
        uint256 leftoverToken = tokenAmount.sub(amountTokenAdded);
        if (leftoverToken > 0) {
            // transfer the leftover Tokens from the `rewards` contract (where they exist) to `to`
            _transfer(address(rewards), to, leftoverToken);
        }

        // calculate if there is any "leftover" Ether
        uint256 leftoverEth = ethAmount.sub(amountEthAdded);
        if (leftoverEth > 0) {
            // transfer the leftover Ether from the `rewards` contract (where they exist) to `to`
            rewards.sendEther(to, leftoverEth);
        }
    }

    /**
     * @notice Executed one time, by anyone, only after the game is over
     * @dev Does everything it can do to suck all liquidity out of Uniswap, which is then used as rewards for users
     */
    function distribute() over public {
        // revert if this function has already been called (see last line in this function)
        require(_distributed == false, "Game::distribute: rewards have already been distributed");
        
        // set the flag which will cause this function to revert if called a second time
        _distributed = true;

        // grab the Uniswap Token-ETH pair
        IUniswapV2Pair pair = IUniswapV2Pair(getUniswapPair());

        // if any Uniswap Token-ETH LP tokens exist on this contract (accidently sent), send them to the `rewards` contract
        uint256 myLPBalance = pair.balanceOf(address(this));
        if (myLPBalance > 0) {
            pair.transfer(address(rewards), myLPBalance);
        }

        // get the Token-ETH LP token balance of `rewards`, and remove all of that liquidity
        // the resultant Ether and Tokens will belong to the `rewards` contract
        uint256 liquidityBalance = pair.balanceOf(address(rewards));
        rewards.removeLiquidityETH(pair, liquidityBalance);

        // if any Tokens belong to this contract, send them to the `rewards` contract
        uint256 myTokenBalance = balanceOf(address(this));
        if (myTokenBalance > 0) {
            _transfer(address(this), address(rewards), myTokenBalance);
        }

        // get the Tokens balance of the `rewards` contract
        uint256 rewardsTokenBalance = balanceOf(address(rewards));

        // swap all of the `rewards` contract's Token balance into any more Ether that might be in the Uniswap pair
        rewards.swapExactTokensForETH(rewardsTokenBalance);

        // store the Ether balance of the `rewards` contract, so that we can calulcate individual rewards later
        _totalRewards = address(rewards).balance;
    }

    /**
     * @notice Allows an account to claim their rewards, after the game is over
     * @param account the address which has Ether to claim
     */
    function claim(address payable account) over external {
        // helper logic -- if the game is over and someone is attemping to claim rewards,
        // but `distribute` has not yet been called, then call it
        if (!_distributed) {
            distribute();
        }

        // revert if the given account has already claimed their rewards
        require(claimedRewards[account] == false, "Game::claim: this account has already claimed rewards");

        // set the flag indicating that rewards have been claimed for the given account
        claimedRewards[account] = true;

        // get the amount of Ether rewards for the given account
        uint256 accountRewards = getAccountRewards(account);

        // send those Ether rewards to the account, proxied through the `rewards` contract
        // which is where the Ether resides
        rewards.sendEther(account, accountRewards);
    }

    /**
     * @notice Get the total amount of rewards that the game is paying out.
     * @return the total amount of rewards that the game is paying out.
     * @dev If the game is over, the rewards are known and static
     * @dev If the game is ongoing, we can calculate what the rewards will be if the game ended right now.
     */
    function getTotalRewards() public view returns (uint256) {
        // if the game is over and we've sucked liquidity and distributed Ether to the `rewards` contract,
        // then we know the total amount of rewards already.
        if (_distributed) {
            return _totalRewards;
        }

        // if a pair hasn't been created yet, (contract was deployed but game is not fully set up),
        // return 0
        IUniswapV2Pair pair = IUniswapV2Pair(getUniswapPair());
        if (address(pair) == address(0)) {
            return 0;
        }

        // if there is no liquidity in the Uniswap Token-ETH pool, return 0
        uint256 totalLpSupply = pair.totalSupply();
        if (totalLpSupply == 0) {
            return 0;
        }

        // otherwise, calculate how much Ether we'd be able to suck out of the pool right now (but don't do it)

        // figure out how much Ether and how much Tokens exist in the pair pools
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        uint256 wethReserves = pair.token0() == uniswapV2Router.WETH() ? _reserve0 : _reserve1;
        uint256 gameTokenReserves = pair.token1() == uniswapV2Router.WETH() ? _reserve0 : _reserve1;

        // figure out the "percentage" (solidity, lol) of LP tokens that the `rewards` contract holds
        uint256 rewardsLpShare = (pair.balanceOf(address(rewards)).add(pair.balanceOf(address(this)))).mul(10**18).div(totalLpSupply);

        // use that percentage to calculate how much Tokens and Eth from the pools that the `rewards` contract _doesn't_ "control"
        uint256 pairWethRemaining = wethReserves.sub(rewardsLpShare.mul(wethReserves).div(10**18));
        uint256 pairGameTokenRemaining = gameTokenReserves.sub(rewardsLpShare.mul(gameTokenReserves).div(10**18));

        // calculate how many Tokens the `rewards` contract "controls" (both from liquidity, and that it directly owns,
        // and also include Tokens that this contract owns because during distribution we'll send those to `rewards` if they exist)
        uint256 rewardsGameTokenTotal = gameTokenReserves.sub(pairGameTokenRemaining).add(balanceOf(address(rewards))).add(balanceOf(address(this)));
        
        // if any of our main variables are 0, return 0, otherwise `getAmountsOut` will revert
        if (rewardsGameTokenTotal == 0 || pairGameTokenRemaining == 0 || pairWethRemaining == 0) {
            return 0;
        }

        // Use Uniswap's `getAmountOut` to figure out how much Ether we'd get if we attempted to swap all of our controlled
        // Tokens for the Ether in the contract, "after pulling liquidity". Then, add in the Ether that we would have pulled
        // from liquidity initially. Then, add in any Ether that the `rewards` contract currently has.
        // Return it.
        return uniswapV2Router.getAmountOut(rewardsGameTokenTotal, pairGameTokenRemaining, pairWethRemaining).add(wethReserves.sub(pairWethRemaining)).add(address(rewards).balance);
    }

    /**
     * @notice Get the total amount of Ether rewards that belong to (will be distributed to) the negative (losing) list
     * @return etherAmount the amount of Ether that belongs to the negative list
     */
    function getNegativeRewards() public view returns (uint256 etherAmount) {
        // get the total score, which is the sum of the scores of the two lists
        uint256 totalScore = getPositiveListTotalScore().add(getNegativeListTotalScore());

        // if the total score is 0, then there are no players, and early exit with 0
        if (totalScore == 0) {
            etherAmount = 0;
        } else {
            // how much of the total score, does the negative list contribute
            uint256 negativePercentage = getNegativeListTotalScore().mul(10**18).div(totalScore);

            // of that correctly-weighted percentage, reduce it by our defined factor
            // THIS IS WHERE THE WINNERS WIN, AND THE LOSERS LOSE
            uint256 negativeSlice = negativePercentage.mul(_negativeWeight).div(10**18);

            // calculate the negative list rewards by taking newly calculated "negative slice" fraction of the total rewards
            etherAmount = getTotalRewards().mul(negativeSlice).div(10**18);
        }
    }

    /**
     * @notice Get the total amount of Ether rewards that belong to (will be distributed to) the positive (winning) list
     * @return etherAmount the amount of Ether that belongs to the positive list
     */
    function getPositiveRewards() public view returns (uint256 etherAmount) {
        // get the total amount of Ether rewards
        uint256 totalRewards = getTotalRewards();

        // get the amount of rewards that belong to the negative list
        uint negativeRewards = getNegativeRewards();

        // the positive list rewards is then total minus negative
        etherAmount = totalRewards.sub(negativeRewards);
    }

    /**
     * @notice Given an account, returns the rewards that account will receive at any given moment, if the game ended at that moment
     * @param account the address of the account that we're interested in
     * @return etherAmount the amount of Ether which will be rewarded to the account
     */
    function getAccountRewards(address account) public view returns (uint256 etherAmount) {
        // check if the account is on the positive list or the negative list or neither
        if (getIsOnPositive(account)) {
            // an account's score is calculated as their score percentage of their list's total reward
            etherAmount = getAccountScore(account).mul(getPositiveRewards()).div(getPositiveListTotalScore());
        } else if (getIsOnNegative(account)) {
            // an account's score is calculated as their score percentage of their list's total reward
            etherAmount = getAccountScore(account).mul(getNegativeRewards()).div(getNegativeListTotalScore());
        } else {
            // if this account isn't on either list (they haven't played), return 0
            etherAmount = 0;
        }
    }

    /**
     * @notice Get the address of the Uniswap Token-ETH pair contract
     * @return pair the address of the Uniswap Token-ETH pair contract, returns 0x0 if the pair hasn't yet been created
     */
    function getUniswapPair() public view returns (address pair) {
        pair = uniswapV2Factory.getPair(address(this), uniswapV2Router.WETH());
    }

    /**
     * @notice Owner function to recover any unclaimed Ether, only callable once 90 days have passed since the game ended
     * @param to address to send the Ether to
     * @param amount the amount of Ether to send
     * @dev this call is proxied to the `rewards` contract, since that's where the Ether lives
     */
    function recoverEther(address payable to, uint256 amount) onlyOwner public {
        // revert if the game hasn't been over for at least 90 days
        require(block.timestamp > endTime.add(90 days), "Game::recoverEther: it has not been 90 days since the game ended");

        // proxy the call down to the `rewards` contract
        rewards.sendEther(to, amount);
    }

    /**
     * @notice Owner function to recover any token held by the Game and/or Rewards contracts, only callable once 90 days have passed since the game ended
     * @param to address to send the tokens to
     */
    function recoverToken(address token, address to) onlyOwner public {
        // revert if the game hasn't been over for at least 90 days
        require(block.timestamp > endTime.add(90 days), "Game::recoverToken: it has not been 90 days since the game ended");

        // Drain tokens from Rewards contract (if there is any)
        rewards.recoverToken(token);

        uint256 myBalance = IERC20(token).balanceOf(address(this));
        if (myBalance > 0) {
            IERC20(token).transfer(to, myBalance);
        }
    }

    /**
     * @notice Owner function to adjust the numbers used to calculate how much reward to "take" from the losing list (negative) and "give" to the winning list (positive)
     * @dev Only executable while the game is active
     * @param negativeWeight a multiplier number
     */
    function adjustSplitWeight(uint256 negativeWeight) active onlyOwner public {
        require(negativeWeight <= 10**18, "Game::adjustSplitWeight: attemping to set split weigth > 100%");

        _negativeWeight = negativeWeight;

        emit SplitAdjusted(negativeWeight);
    }

    /**
     * @notice Owner function to adjust the numbers used to calculate how much of the input Ether to `purchaseTokensAndDepositLP` will be used for market buying Tokens on Uniswap.
     * @dev if the number is above "50%", a subtraction underflow occurs and reverts the public function, so check for that here when setting the values
     * @param _marketPurchase a multiplier number
     */
    function adjustMarketPurchase(uint256 _marketPurchase) onlyOwner public {
        // revert if the input number is less than half of our constant divisor
        require(_marketPurchase <= MAX_MARKET_PURCHASE, "Game::adjustMarketPurchase: attemping to set purchase percentage > 50%");
        marketPurchase = _marketPurchase;

        emit MarketPurchaseAdjusted(_marketPurchase);
    }

    /**
     * @notice Owner function to adjust the min Ethers accepted to deposit
     * @dev Only executable while the game is active
     * @param _minEthers a multiplier number
     */
    function adjustMinEthers(uint256 _minEthers) active onlyOwner public {
        minEthers = _minEthers;

        emit MinEthersAdjusted(minEthers);
    }

    /**
     * @notice Owner function to adjust the min LP tokens accepted to deposit
     * @dev Only executable while the game is active
     * @param _minLpTokens a multiplier number
     */
    function adjustMinLpTokens(uint256 _minLpTokens) active onlyOwner public {
        minLpTokens = _minLpTokens;

        emit MinLpTokensAdjusted(minLpTokens);
    }
}
