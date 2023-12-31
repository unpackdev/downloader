//SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "./Ownable.sol";
import "./Clones.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./SteroidsToken.sol";

/**
 * @title SteroidsGame
 * @author gotbit
 * @notice Steroids Game contract
 */
contract SteroidsGame is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct TokenData {
        address pair;
        bool hasLiquidity;
    }

    struct Settings {
        uint256 swapDays;
        uint256 winDays;
        uint256 tokenCount;
    }

    uint256 public constant MAX_TOKENS = 10;
    uint256 public constant LP_DELTA = 1000; // 10**3
    uint256 public constant STABLE_TOKEN_SHARE = 20; // 20%
    uint256 public constant ONE_HUNDRED = 100; // 100%

    address public immutable TOKEN_IMPL;
    address public immutable STABLE_TOKEN;
    IUniswapV2Router02 public immutable ROUTER;
    IUniswapV2Factory public immutable FACTORY;

    Settings public settings;
    uint256 public startTimestamp;
    bool public gameStopped;

    mapping(address => TokenData) public tokenData;
    mapping(uint256 => address) public pairs;
    mapping(uint256 => address) public tokens;

    uint256 public pairsFilledCount;
    uint256 public pairsCount;
    uint256 public lastBuyTimestamp;
    uint256 public lastValidWinnerTimestamp;
    address public ownerTokenWallet;

    uint256 public stableWinPoolAmount;
    uint256 public stableTotalPoolAmount;

    mapping(uint256 => address) public winnerToken;
    address public lastBuyDayWinnerToken;
    address public lastValidWinnerToken;
    mapping(uint256 => mapping(address => int256)) public dailyVolume;
    mapping(address => mapping(address => int256)) public totalVolumePerUser;
    mapping(address => uint256) public positiveTotalUserAmountPerPool;
    mapping(address => bool) public hasClaimed;
    mapping(address => uint256) public winCountPerPool;
    uint256 public maxWinCount;
    uint256 public initialLiquidityStable;

    /// @notice Creates new contract
    /// @param router_ - UniswapV2 router
    /// @param stableToken_ - stable token address
    /// @param settings_ - game settings struct
    /// @param owner_ - game owner role
    /// @param ownerTokenWallet_ - owner wallet for sending and receiving tokens (can be the same as owner)
    /// @param tokenImpl_ - steroids token base implementation address
    constructor(
        IUniswapV2Router02 router_,
        address stableToken_,
        Settings memory settings_,
        address owner_,
        address ownerTokenWallet_,
        address tokenImpl_
    ) {
        require(settings_.tokenCount <= MAX_TOKENS, 'Max tokens exceed limit');
        require(settings_.tokenCount != 0, 'Max tokens zero');
        require(
            settings_.swapDays <= settings_.winDays,
            'Swap days > max days'
        );
        require(0 != settings_.winDays, 'Win days == 0');
        require(owner_ != address(0), 'Invalid owner');
        require(address(router_) != address(0), 'Invalid router');
        require(stableToken_ != address(0), 'Invalid stable');
        require(ownerTokenWallet_ != address(0), 'Invalid wallet');
        require(tokenImpl_ != address(0), 'Invalid impl');

        _transferOwnership(owner_);
        ROUTER = router_;
        STABLE_TOKEN = stableToken_;
        settings = settings_;
        TOKEN_IMPL = tokenImpl_;
        FACTORY = IUniswapV2Factory(router_.factory());
        ownerTokenWallet = ownerTokenWallet_;
    }

    /// @notice Checks if transfer from and to of the game token can be made, calculates the amounts of users` spent stable tokens
    /// @param from - game token spender
    /// @param to - game token recepient
    /// @param to - game token amount
    function trackTransfer(address from, address to, uint256 amount) external {
        if (from == address(0)) return; // mint of steriods is allowed only once, when token is being initialized (created)

        // TRANSFER
        address token = msg.sender;
        TokenData memory data = tokenData[token];

        // dataToken[msg.sender] has been initialized => sender token is game token
        require(data.pair != address(0), 'Not valid sender');

        // gameStopped = true => before any transfer after game is finished
        // gameStopped = true => isOver = true
        if (!gameStopped) {
            require(!isOver(), 'Game over');
            if (!data.hasLiquidity) {
                if (to == data.pair) {
                    tokenData[token].hasLiquidity = true;
                    // add liquidity
                } else revert('Only add liquidity allowed for now');
            } else {
                require(startTimestamp != 0, 'Game not started');
                // sell/buy
                if (to == data.pair) {
                    // sell
                    require(!isSellsTurnedOff(), 'Sells turned off');
                    lastBuyTimestamp = block.timestamp;
                    uint256 day = getToday();
                    int256 stableAmount = _getStableTokenEqivalentForAmount(
                        token,
                        amount,
                        false
                    );

                    int256 totalVolumePerUserBefore = totalVolumePerUser[from][
                        token
                    ];

                    // volumes can be negative due to price volatility
                    dailyVolume[day][token] -= stableAmount;
                    totalVolumePerUser[from][token] -= stableAmount;

                    int256 totalVolumePerUserAfter = totalVolumePerUserBefore -
                        stableAmount;

                    // can stay > 0
                    // can stay < 0
                    // can move from > 0 to < 0
                    if (
                        totalVolumePerUserBefore > 0 &&
                        totalVolumePerUserAfter < 0
                    ) {
                        // before > 0
                        // after < 0
                        // cross over 0 => sub the last positive amount
                        positiveTotalUserAmountPerPool[token] -= uint256(
                            totalVolumePerUserBefore
                        );
                    } else if (totalVolumePerUserAfter >= 0) {
                        // before > 0
                        // after > 0
                        positiveTotalUserAmountPerPool[token] -= uint256(
                            stableAmount
                        );
                    }
                    // else
                    // before < 0
                    // after < 0
                    // do nothing

                    address lastBuyDayWinnerTokenPrevious = lastBuyDayWinnerToken;
                    lastBuyDayWinnerToken = _findMaxVolumeToken(day); // keep last winner token always actual
                    winnerToken[day] = lastBuyDayWinnerToken;
                    _updateWinCountPerPool(day, lastBuyDayWinnerTokenPrevious);
                    if (lastBuyDayWinnerToken != address(0)) {
                        lastValidWinnerToken = lastBuyDayWinnerToken; // memorize only valid winner
                        lastValidWinnerTimestamp = block.timestamp;
                    }
                } else if (from == data.pair) {
                    // buy
                    lastBuyTimestamp = block.timestamp;
                    uint256 day = getToday();
                    int256 stableAmount = _getStableTokenEqivalentForAmount(
                        token,
                        amount,
                        true
                    );

                    int256 totalVolumePerUserBefore = totalVolumePerUser[to][
                        token
                    ];

                    dailyVolume[day][token] += stableAmount; // converted to stable token equivalent
                    totalVolumePerUser[to][token] += stableAmount; // converted to stable token equivalent, to => recepient

                    int256 totalVolumePerUserAfter = totalVolumePerUserBefore +
                        stableAmount;

                    // can stay >= 0
                    // can stay < 0
                    // can move from < 0 to > 0
                    if (
                        totalVolumePerUserBefore < 0 &&
                        totalVolumePerUserAfter > 0
                    ) {
                        // cross over 0 => add the new positive amount
                        positiveTotalUserAmountPerPool[token] += uint256(
                            totalVolumePerUserAfter
                        );
                    } else if (totalVolumePerUserBefore >= 0) {
                        // before >= 0
                        // after > 0
                        positiveTotalUserAmountPerPool[token] += uint256(
                            stableAmount
                        );
                    }
                    /*
                    else 
                    before < 0
                    after < 0
                    */
                    address lastBuyDayWinnerTokenPrevious = lastBuyDayWinnerToken;
                    lastBuyDayWinnerToken = _findMaxVolumeToken(day); // keep last winner token always actual
                    winnerToken[day] = lastBuyDayWinnerToken;
                    _updateWinCountPerPool(day, lastBuyDayWinnerTokenPrevious);
                    if (lastBuyDayWinnerToken != address(0)) {
                        lastValidWinnerToken = lastBuyDayWinnerToken; // memorize only valid winner
                        lastValidWinnerTimestamp = block.timestamp;
                    }
                } else {
                    // not to pair and not from pair
                    // other transfers forbidden
                    revert('Transfers to and from pair allowed only');
                }
            }
        } else {
            // game stopped
            // allowed to remove liquidity and distribute rewards from the contract
            if (from == data.pair) {
                // remove liquidity
            } else if (from == address(this)) {
                // distribure rewards
            } else {
                revert('Invalid token transfer after game finish');
            }
        }
    }

    /// @notice Update win count and max win count for the current trading pool if needed
    /// @param today - the current day number
    /// @param lastBuyDayWinnerTokenPrevious - address of the winner token at the moment of the last buy day
    function _updateWinCountPerPool(
        uint256 today,
        address lastBuyDayWinnerTokenPrevious
    ) private {
        if (lastBuyDayWinnerTokenPrevious == address(0)) return; // no valid winner
        uint256 lastValidWinnerTimestampLocal = lastValidWinnerTimestamp; // != 0 because here lastValidWinner != 0

        // last valid winner has already been set
        uint256 previousValidWinnerTokenDay = lastValidWinnerTimestampLocal >=
            startTimestamp
            ? _getDay(lastValidWinnerTimestampLocal)
            : 0;
        if (previousValidWinnerTokenDay != today) {
            // the winner in the past is defined
            // valid winner in another day, no valid winner today yet
            uint256 winCountLocal = ++winCountPerPool[
                lastBuyDayWinnerTokenPrevious
            ];
            // overwrite max win count if required
            if (winCountLocal > maxWinCount) {
                maxWinCount = winCountLocal;
            }
        } else return;
        // the winner is not defined
    }

    /// @notice Claims user reward
    function claimReward() external nonReentrant {
        if (gameStopped) {
            _claim(msg.sender);
            return;
        }
        // GAME HAS NOT BEEN STOPPED
        if (isOver()) {
            // game will not stop if there is no winner yet
            _stopGame();
            _claim(msg.sender);
            return;
        } else {
            revert('Game is in progress');
        }
    }

    /// @notice Find token with max daily volume for the current day
    /// @param day - day number
    /// @return winToken - address of the winner token
    function _findMaxVolumeToken(
        uint256 day
    ) private view returns (address winToken) {
        uint256 pairsCountLocal = pairsCount;
        int256 maxVolume = dailyVolume[day][tokens[0]];
        winToken = tokens[0];
        for (uint256 i = 1; i < pairsCountLocal; ) {
            address curToken = tokens[i];
            int256 curVolume = dailyVolume[day][curToken];
            if (maxVolume < curVolume) {
                maxVolume = curVolume;
                winToken = curToken; // set win token only if one pool has higher volume
            } else if (maxVolume == curVolume) {
                winToken = address(0); // no winner if there is no pool with higher volume
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Internal function for claiming user reward
    /// @param user - user address
    function _claim(address user) private {
        // check user stable token share in each pool
        // transfer amount if a user has share in winning pool
        require(!hasClaimed[user], 'Already claimed');
        hasClaimed[user] = true;

        int256 totalVolumePerUserLocal = totalVolumePerUser[user][
            lastValidWinnerToken
        ];
        require(
            totalVolumePerUserLocal > 0,
            'User has <= 0 funds in the winning pool'
        );

        uint256 stableWinnigPoolUserAmount = uint256(totalVolumePerUserLocal);

        // 0.8 * totalUserPosAmount * userWinPoolAmount / totalWinPoolAmount
        uint256 userStableTokenAmount = (stableTotalPoolAmount *
            stableWinnigPoolUserAmount) / stableWinPoolAmount;

        // userStableTokenAmount
        IERC20(STABLE_TOKEN).safeTransfer(user, userStableTokenAmount);
    }

    /// @notice Internal function for getting the stable token equivalent amount for game token amount (when selling or buying)
    /// @param token - game token address
    /// @param amount - game token amount
    /// @param tokensIn - true if game tokens in, else - false
    /// @return amount of stable token
    function _getStableTokenEqivalentForAmount(
        address token,
        uint256 amount,
        bool tokensIn
    ) private view returns (int256) {
        address[] memory path = new address[](2);

        if (tokensIn) {
            path[1] = token;
            path[0] = STABLE_TOKEN;
            // slippage affects this value
            return int256((ROUTER.getAmountsIn(amount, path))[0]);
        } else {
            path[0] = token;
            path[1] = STABLE_TOKEN;
            // slippage affects this value
            return int256((ROUTER.getAmountsOut(amount, path))[1]);
        }
    }

    /// @notice Internal function stopping game and sending the owner reward to owner token wallet
    function _stopGame() private {
        gameStopped = true;

        address winToken = lastBuyDayWinnerToken; // is already defined
        address ownerWalletLocal = ownerTokenWallet;

        // small amount of stable tokens gets stuck in the pair
        uint256 stableTokenPairBalance;

        uint256 pairsCountLocal = pairsCount;
        for (uint256 i; i < pairsCountLocal; ) {
            IUniswapV2Pair pair = IUniswapV2Pair(pairs[i]);
            uint256 lpTokens = pair.balanceOf(address(this));
            address token0 = pair.token0();
            address token1 = pair.token1();
            IERC20 gameToken = token0 == STABLE_TOKEN
                ? IERC20(token1)
                : IERC20(token0);

            // Send all LP tokens back to pair, receive tokens on the contract
            pair.approve(address(ROUTER), lpTokens);
            ROUTER.removeLiquidity(
                token0,
                token1,
                lpTokens,
                0,
                0,
                address(this),
                block.timestamp + 1
            );

            uint256 positiveTotalUserAmountPerPoolLocal = positiveTotalUserAmountPerPool[
                    address(gameToken)
                ];

            if (address(gameToken) == winToken) {
                // count only win pool stable token amount (positive user investments)
                stableWinPoolAmount = positiveTotalUserAmountPerPoolLocal;
            }

            // SEND 100% of game tokens to owner wallet
            gameToken.safeTransfer(
                ownerWalletLocal,
                gameToken.balanceOf(address(this))
            );

            stableTokenPairBalance += IERC20(STABLE_TOKEN).balanceOf(
                address(pair)
            );

            unchecked {
                ++i;
            }
        }

        // read from storage
        uint256 initialLiquidityStableLocal = initialLiquidityStable;

        uint256 stableTokenContractBalance = IERC20(STABLE_TOKEN).balanceOf(
            address(this)
        );

        // final stable liquidity amount >= initial stable liquidity
        // owner takes initial amount + 20% of user invested funds, users get 80% of final amount - initial amount
        // always >= 0
        uint256 userStableTotalFunds = stableTokenContractBalance -
            initialLiquidityStableLocal;

        // initial + 20% of users funds
        uint256 ownerStableAmount = (initialLiquidityStableLocal *
            ONE_HUNDRED +
            userStableTotalFunds *
            STABLE_TOKEN_SHARE) / ONE_HUNDRED;

        // remaining 80% of users funds => users are allowed to claim rewards
        // transfer, except for the value, which got stuck inside the pair
        IERC20(STABLE_TOKEN).safeTransfer(
            ownerWalletLocal,
            ownerStableAmount - stableTokenPairBalance
        );

        // all stable tokens from all pools (remaining user investments)
        stableTotalPoolAmount = IERC20(STABLE_TOKEN).balanceOf(address(this));
    }

    /// @notice Checks if the game is over
    /// @return true if the game is over, else - false
    function isOver() public view returns (bool) {
        return _triggerActionForAtLeastKTimes(settings.winDays);
    }

    /// @notice Checks if the swaps of game token for stable token are stopped
    /// @return true if the swaps are stopped, else - false
    function isSellsTurnedOff() public view returns (bool) {
        if (settings.swapDays == 0) return true; // sells are forbidden in case of swap days = 0
        return _triggerActionForAtLeastKTimes(settings.swapDays);
    }

    /// @notice Internal function for checking if the trigger action has occured at least K times in total
    /// @param times_ - the K number of days
    /// @return true if the trigger action has occured at least K times, else - false
    function _triggerActionForAtLeastKTimes(
        uint256 times_
    ) private view returns (bool) {
        if (maxWinCount >= times_) return true;
        else if (maxWinCount == times_ - 1) {
            for (uint256 i; i < settings.tokenCount; ) {
                address curToken = tokens[i];
                if (winCountPerPool[curToken] == times_ - 1) {
                    // potential winner
                    uint256 lastValidWinDay = _getDay(lastValidWinnerTimestamp);
                    uint256 today = getToday();
                    if (lastValidWinDay == today) {
                        unchecked {
                            ++i;
                        }
                        continue; // the last day has not passed
                    }
                    if (
                        lastValidWinnerToken == curToken &&
                        lastBuyDayWinnerToken != address(0)
                    ) return true;
                }
                unchecked {
                    ++i;
                }
            }
            return false;
        } else {
            return false;
        }
    }

    /// @notice Creates new game token and sets a uniswap pair with game token and stable token
    /// @param name - token name
    /// @param symbol - token symbol
    /// @param supply - token supply
    function createToken(
        string memory name,
        string memory symbol,
        uint256 supply
    ) external onlyOwner {
        address token = Clones.clone(TOKEN_IMPL);
        SteroidsToken(token).initialize(
            name,
            symbol,
            supply,
            address(this),
            SteroidsGame(address(this))
        );

        address pair = FACTORY.createPair(STABLE_TOKEN, token);
        tokenData[token] = TokenData({pair: pair, hasLiquidity: false});

        // ADD NEW PAIR
        uint256 prevPairsCount = pairsCount++;
        pairs[prevPairsCount] = pair;
        tokens[prevPairsCount] = token;
        require(
            prevPairsCount < settings.tokenCount,
            'Pairs count exceeds limit'
        );
    }

    /// @notice Starts the new game after checking that all pairs have liquidity
    function startGame() external onlyOwner {
        require(startTimestamp == 0, 'Game already started');
        require(
            pairsFilledCount == settings.tokenCount,
            'Missing pairs or liquidity'
        );
        startTimestamp = block.timestamp;
    }

    /// @notice Adds liquidity to the desired game / stable tokens pair on Uniswap
    /// @param token - game token
    /// @param amountToken - game token amount in
    /// @param amountTokenStable - stable token amount in
    function addLiquidity(
        address token,
        uint256 amountToken,
        uint256 amountTokenStable
    ) external onlyOwner nonReentrant {
        require(lastBuyTimestamp == 0, 'Transfers already started');
        require(token != STABLE_TOKEN, 'Provide game token as param');
        address pair = tokenData[token].pair;
        require(tokenData[token].pair != address(0), 'Invalid token');
        require(!tokenData[token].hasLiquidity, 'Pair already filled');
        require(
            amountToken != 0 && amountTokenStable != 0,
            'Can not add zero tokens'
        );

        ++pairsFilledCount;

        IERC20(token).safeApprove(address(ROUTER), amountToken);
        IERC20(STABLE_TOKEN).safeTransferFrom(
            ownerTokenWallet,
            address(this),
            amountTokenStable
        );
        IERC20(STABLE_TOKEN).safeApprove(address(ROUTER), amountTokenStable);

        // add liquidity to a desired pair, no limits on real amounts in, any price
        // LP stays on the contract
        ROUTER.addLiquidity(
            token,
            STABLE_TOKEN,
            amountToken,
            amountTokenStable,
            0,
            0,
            address(this),
            block.timestamp + 1
        );

        // current pair LP balance
        uint256 lpBalanceNew = IUniswapV2Pair(pair).balanceOf(address(this));
        // increse liquidity for stable token => it is common for all pairs
        // UniSwapV2 takes lp delta fee => real liquidity is less than added
        initialLiquidityStable +=
            (amountTokenStable * lpBalanceNew) /
            (lpBalanceNew + LP_DELTA);
    }

    /// @notice Returns the slice of the tokens array from _offset index, the slice is _limit length
    /// @param offset - offset index
    /// @param limit - slice length
    /// @return Array slice
    function getTokensSlice(
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory) {
        require(offset + limit <= pairsCount, 'Invalid offset || limit');
        address[] memory tokensRes = new address[](limit);

        for (uint256 i = 0; i < limit; ) {
            tokensRes[i] = tokens[i + offset];

            unchecked {
                ++i;
            }
        }

        return tokensRes;
    }

    /// @notice Returns the game / stable token pair reserves
    /// @param token - game token
    /// @return reserveToken - reserve of game token, reserveStable - reserve of stable token
    function getPairReserves(
        address token
    ) public view returns (uint256 reserveToken, uint256 reserveStable) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            FACTORY.getPair(token, STABLE_TOKEN)
        );
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        if (pair.token0() == token) {
            reserveToken = reserve0;
            reserveStable = reserve1;
        } else {
            reserveToken = reserve1;
            reserveStable = reserve0;
        }
    }

    /// @notice Returns the current day number (starting from the startTimestamp)
    /// @return Day number
    function getToday() public view returns (uint256) {
        return _getDay(block.timestamp);
    }

    /// @notice Internal function which returns the day number with a given timestamp (starting from the startTimestamp)
    /// @return Day number
    function _getDay(uint256 timestamp) internal view returns (uint256) {
        return (timestamp - startTimestamp) / 1 days + 1;
    }
}
