///SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";

contract AiGoldPresale is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    ///Custom errors
    error ZeroAmountNotAllowed();
    error ZeroAddressNotAllowed();
    error InvalidRound();
    error ClaimsAreNotAvailableYet();
    error TokenClaimFailed();
    error CannotClaimNativeTokens();
    error MaxWalletCapReached();
    error AmountExceedsAvailableTokens();
    error USDPaymentFailed();
    error ETHTransferFailed();
    error MinimumAmountIs10USD();
    error PresaleRoundIsAlreadyOver();
    error AlreadyClaimed();
    error ClaimsAreEnabledAlready();
    error CannotSetDateInPast();
    error CannotSetThePastRoundPrice();
    error PresaleIsPaused();
    error AmountMustBeLessThanAvailableTokens();
    error PresaleIsOver();
    error ETHRefundFailed();
    error ValuesAlreadyExists();
    error PriceCantNotBeZero();
    error UpdateBoolValue();
    error AlreadyAMultiSigWallet();

    ////struct for Round details
    struct Round {
        uint256 currentPrice;
        uint256 nextPrice;
        uint256 totalTokens;
        uint256 totalSold;
        uint256 startTime;
        uint256 endTime;
    }

    /// struct for user information
    struct User {
        uint256 totalUSDContributed;
        uint256 totalTokensBought;
        uint256 totalTokensClaimed;
    }
    //// CONSTANTS ////

    /// @notice token decimals
    uint256 private constant TOKEN_DECIMALS = 9;
    /// @notice usdt decimals
    uint256 private constant USDT_DECIMALS = 6;
    /// @notice base decimals (wei)
    uint256 private constant BASE_DECIMALS = 18;
    /// @notice max wallet limit for user, how much tokens a user can buy
    uint256 private constant MAX_WALLET_CAP = 30_000_000 * 10 ** TOKEN_DECIMALS;
    /// @notice no. of tokens in each round
    uint256 private constant tokensPerRound = 112_500_000 * 10 ** TOKEN_DECIMALS;
    /// @notice total no. of rounds
    uint256 private constant totalRounds = 12;

    /// @notice token that will be accepted in presale with eth
    IERC20 public immutable USDT;
    /// @notice chainlink price feed
    AggregatorV3Interface private immutable priceFeed;

    /// @notice multisig, where all funds will be stored
    address public multiSig;
    /// @notice token for sale
    IERC20 public token;

    /// @notice total tokens for sale
    uint256 public totalTokensForSale = tokensPerRound * totalRounds;
    /// @notice total usdt raised
    uint256 public totalUSDRaised;
    /// @notice total tokens sold
    uint256 public totalTokensSold;
    /// @notice current round
    uint256 public currentRound = 1;
    /// @notice claim enabled status
    bool private claimEnabled = false;
    /// @notice presale status if paused or not 
    bool private paused = false;

    /// @notice mapping for user info
    mapping(address => User) public users;
    /// @notice mapping for rounds info
    mapping(uint256 => Round) public rounds;

    //// Events
    event TokensClaimed(address indexed user, uint256 indexed amount);
    event TokensBought(address indexed user, uint256 indexed usd);
    event ClaimEnabled (bool indexed value);
    event PresalePaused (bool indexed value);
    event PriceUpdated (uint256 indexed currentRoundPrice, uint256 indexed nextRoundPrice);
    event PresaleDateUpdated (uint256 indexed newEndTime);
    event MultiSigUpdated(address indexed newMultiSig);
    event NextRoundStarted(uint256 indexed round);

    /// @dev create a presale contract using openzeppelin ownable2Step, ReentrancyGuard and
    /// using safeERC20, chainlink aggregator interface. Initilizing the token, usdt and price feed values
    /// along with multisig and starting first round.
    constructor() Ownable(msg.sender) {
        USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        
        multiSig = 0x6cAaD4f38661a9fC783758CAAf0b1e8713e68E8B; 
        switchRound(1);
    }

    //// modifier which checks if round is valid and user is buying
    /// within valid time (that's within round start and end date)
    modifier validRoundCheck() {
        if (paused) {
            revert PresaleIsPaused();
        }
        if ( currentRound > 12) {
            revert InvalidRound();
        }
        Round storage liveRound = rounds[currentRound];
        uint256 availableTokens = liveRound.totalTokens - liveRound.totalSold;
        if (availableTokens == 0 && currentRound == 12) {
            revert PresaleIsOver();
        }
        if (
             block.timestamp > liveRound.endTime
        ) {
            revert PresaleRoundIsAlreadyOver();
        }

        _;
    }

    /// internal function to switch to next round
    /// @param _round: round to switch
    function switchRound(uint256 _round) internal {
        if ( _round > 12) {
            revert InvalidRound();
        }
        if (_round == 1) {
            Round storage round = rounds[_round];
            round.currentPrice = 3500;
            round.nextPrice = 4500;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;

        } else if (_round == 2) {
            Round storage round = rounds[_round];
            round.currentPrice = 4500;
            round.nextPrice = 5500;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;

        } else if (_round == 3) {
            Round storage round = rounds[_round];
            round.currentPrice = 5500;
            round.nextPrice = 7500;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;

        } else if (_round == 4) {
            Round storage round = rounds[_round];
            round.currentPrice = 7500;
            round.nextPrice = 10000;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;

        } else if (_round == 5) {
            Round storage round = rounds[_round];
            round.currentPrice = 10000;
            round.nextPrice = 12500;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;

        } else if (_round == 6) {
            Round storage round = rounds[_round];
            round.currentPrice = 12500;
            round.nextPrice = 15000;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;

        } else if (_round == 7) {
            Round storage round = rounds[_round];
            round.currentPrice = 15000;
            round.nextPrice = 17500;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;
        
        } else if (_round == 8) {
            Round storage round = rounds[_round];
            round.currentPrice = 17500;
            round.nextPrice = 20000;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;
            
        } else if (_round == 9) {
            Round storage round = rounds[_round];
            round.currentPrice = 20000;
            round.nextPrice = 22500;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;
            
        } else if (_round == 10) {
            Round storage round = rounds[_round];
            round.currentPrice = 22500;
            round.nextPrice = 25000;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;
            
        }

        else if (_round == 11) {
            Round storage round = rounds[_round];
            round.currentPrice = 25000;
            round.nextPrice = 30000;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;
            
        } else {
            Round storage round = rounds[_round];
            round.currentPrice = 30000;
            round.nextPrice = 35000;
            round.totalTokens = tokensPerRound;
            round.totalSold = 0;
            round.startTime = block.timestamp;
            round.endTime = block.timestamp + 14 days;
            
        }
    }

    /// users can buy tokens using usdt
    /// @param _usdAmount: usd amount user want to spend to buy tokens
    function buyWithUSDT(
        uint256 _usdAmount
    ) external validRoundCheck nonReentrant {
        buyTokens(_usdAmount, true);
    }

    /// @dev buys tokens using ether
    /// users can buy tokens by inputting the ether amount.
    function buyWithETH() external payable validRoundCheck nonReentrant {
        uint256 _usdAmount = ethUSDHelper(msg.value);
        buyTokens(_usdAmount, false);
    }

    /// @notice users can claim tokens, as soon as claims are enabled
    function claim() external nonReentrant {
        if (!claimEnabled) {
            revert ClaimsAreNotAvailableYet();
        }
        User storage user = users[msg.sender];
        if (user.totalTokensClaimed > 0) {
            revert AlreadyClaimed();
        }
        uint256 availableToClaim = user.totalTokensBought;
        user.totalTokensClaimed = availableToClaim;

        uint256 balanceBefore = token.balanceOf(msg.sender);
        token.safeTransfer(msg.sender, availableToClaim);
        uint256 balanceAfter = token.balanceOf(msg.sender);

        if (balanceAfter - balanceBefore != availableToClaim) {
            revert TokenClaimFailed();
        }
        emit TokensClaimed(msg.sender, availableToClaim);
    }

    /// @dev manage token buy for eth, usd
    ///Requirements -
    /// Minimum amount is 10 usd
    /// user can buy within duration of sale
    /// if user USD amount is more than worth existing round tokens, it will
    /// calculate the remaining usd for next round price.
    /// Example - if token price for round 1 is 0.01 usd and 100 tokens are left.
    /// now user input 100 usd, so he will get 100 tokens at the rate of 0.01 usd (1 usd)
    /// For remaing 99 usd, he will get price of round 2. (which can be say 0.015 usd per token)
    /// In case it's round 12, then extra amount is refunded. If he is buying using usdt, then
    /// only required amount is deducted. In case of eth, any extra supplied eth is sent back to
    /// user within same tx
    /// user can max buy upto maxWalletLimit.
    function buyTokens(uint256 _usdAmount, bool value) private {
        if (_usdAmount < 10e6) {
            revert MinimumAmountIs10USD();
        }
        
        User storage user = users[msg.sender];
        Round storage round = rounds[currentRound];
        uint256 availableTokens = round.totalTokens - round.totalSold;
        uint256 outputTokens = getTokenAmount(_usdAmount);

        if (availableTokens >= outputTokens) {
            round.totalSold = round.totalSold + outputTokens;
        } else {
            round.totalSold = round.totalSold + availableTokens;
        }

        if (outputTokens > availableTokens && currentRound < 12) {
            /// cache round price from prev round
            uint256 currentRoundPrice = round.nextPrice;
            currentRound = currentRound + 1;
            switchRound(currentRound);
            Round storage roundNext = rounds[currentRound];
            roundNext.totalSold =
                roundNext.totalSold +
                (outputTokens - availableTokens);
            /// if price is updated in prev round for this round,
            /// should reflect here as well    
            if(roundNext.currentPrice != currentRoundPrice){
                roundNext.currentPrice = currentRoundPrice;
            }    
        }

        
        uint256 extraUsd = 0;
        if (currentRound == 12 && outputTokens > availableTokens) {
           uint256 usdRequired =
                (availableTokens * round.currentPrice) /
                10 ** TOKEN_DECIMALS;
            /// When user input is say 100 usd, but tokens available are worth 
            /// 80 usd only, then only 80 usd is deducted by the presale contract
            /// 20 stays in his wallet    
            /// When he pays in eth, then as he is sending msg.value worth 100 usd,
            /// so 20 usd worth is returned to user within same tx.
            if (usdRequired > 0) {
                 extraUsd = _usdAmount - usdRequired;
                _usdAmount = usdRequired; /// only deduct required usd amount
                outputTokens = availableTokens;
            }
        }
       
        if (user.totalTokensBought + outputTokens > MAX_WALLET_CAP) {
            revert MaxWalletCapReached();
        }
         
        if (value) {
            uint256 multiSigBalanceBefore = USDT.balanceOf(multiSig);
            USDT.safeTransferFrom(msg.sender, multiSig, _usdAmount);
            uint256 multiSigBalanceAfter = USDT.balanceOf(multiSig);

            if (multiSigBalanceAfter <= multiSigBalanceBefore) {
                revert USDPaymentFailed();
            }
        } else  {
            uint256 refund = 0;
            uint256 ethRequired = msg.value;
            if (extraUsd > 0) {
                uint256 oneETH = getLatestPrice();
                uint256 priceFeedDecimals = priceFeed.decimals();
                ///using multiplier to keep eth calculation upto 18 decimals (wei)
                uint256 multiplier = BASE_DECIMALS + priceFeedDecimals - USDT_DECIMALS;
                ethRequired = (_usdAmount * 10 ** multiplier) / oneETH;
                refund  = msg.value - ethRequired;
            }
             
             /// send required eth to multisig
            (bool success, ) = payable(multiSig).call{value: ethRequired}("");
            if (!success) {
                revert ETHTransferFailed();
            }
            /// if user has refund, sent that back to user
            if (refund > 0) {
                (bool sent, ) = payable(msg.sender).call{value: refund}("");
                if (!sent) {
                    revert ETHRefundFailed();
                }
            }
        }

        user.totalUSDContributed = user.totalUSDContributed + _usdAmount;
        user.totalTokensBought = user.totalTokensBought + outputTokens;

        totalTokensSold = totalTokensSold + outputTokens;
        totalUSDRaised = totalUSDRaised + _usdAmount;
        emit TokensBought(msg.sender, _usdAmount);
    }

    /// @dev enables claims globally, once enabled user can claim there tokens
    /// make sure the contract has enough tokens in it
    function enableClaims() external onlyOwner {
        if (claimEnabled) {
            revert ClaimsAreEnabledAlready();
        }
        
        claimEnabled = true;
        emit ClaimEnabled(true);
    }

    /// @dev update the current round end date
    /// @param endDate: unixTimestamp for new end date for current round
    function setEndDateForCurrentRound(uint256 endDate) external onlyOwner {
        Round storage round = rounds[currentRound];
        if (endDate < block.timestamp) {
            revert CannotSetDateInPast();
        }
        round.endTime = endDate;
        emit PresaleDateUpdated(endDate);
    }

    /// @dev update the price of token for current round
    /// @param _newPrice: price in wei format (usd has 6 decimals only so set
    /// @param _nextPrice; token price in wei format for next round than input
    ///                  accordingly.
    ///                  eg. 100 - 0.0001 usd
    ///                      1000 - 0.001 usd, 10000 - 0.01 usd
    function setPrice(
        uint256 _newPrice,
        uint256 _nextPrice
    ) external onlyOwner {
        if(_newPrice == 0 || _nextPrice == 0){
            revert PriceCantNotBeZero();
        }

        Round storage round = rounds[currentRound];
        
        /// one of value can stay same if owner want to update only one value 
        if(_newPrice == round.currentPrice && _nextPrice == round.nextPrice){
            revert ValuesAlreadyExists();
        }
        round.currentPrice = _newPrice;
        round.nextPrice = _nextPrice;

        emit PriceUpdated(_newPrice, _nextPrice);
    }

    /// @dev set the sale token address
    /// @param _token: address of sale token
    function setToken(address _token) external onlyOwner {
        if (_token == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        token = IERC20(_token);
    }

    /// @dev update multisig/payment wallet address
    /// @param _multisig: new wallet address
    function updateMultiSigWallet (address _multisig) external onlyOwner {
        if(_multisig == address(0)){
            revert ZeroAddressNotAllowed();
        }
        if(_multisig == multiSig){
            revert AlreadyAMultiSigWallet();
        }
        multiSig = _multisig;
        emit MultiSigUpdated (_multisig);
    }

    /// @dev claim other erc20 tokens
    function claimOtherERC20(
        address othertkn,
        uint256 amount
    ) external onlyOwner {
        if (othertkn == address(token)) {
            revert CannotClaimNativeTokens();
        }
        IERC20 otherToken = IERC20(othertkn);
        otherToken.safeTransfer(owner(), amount);
    }

    /// @dev switch to next round
    /// Requirements -
    /// can't switch if it's already a last round
    function switchToNextRound() external onlyOwner {
        currentRound = currentRound + 1;
        switchRound(currentRound);
        emit NextRoundStarted (currentRound);
    }

    /// @dev claim ether if any
    function claimEther() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /// @dev pause/unpause presale
    function togglePauseUnpause() external onlyOwner {
        paused = !paused;
        emit PresalePaused(paused);
    }


    /// @dev add tokens to current sale round
    /// @param amount: token amount to add
    function addTokensToSale(uint256 amount) external onlyOwner {
        Round storage round = rounds[currentRound];
        round.totalTokens = round.totalTokens + amount;
        totalTokensForSale = totalTokensForSale + amount;
    }

    /// @dev remove tokens to current sale round
    /// @param amount: token amount to remove
    function removeTokensFromSale(uint256 amount) external onlyOwner {
        Round storage round = rounds[currentRound];
        if (amount > round.totalTokens - round.totalSold) {
            revert AmountMustBeLessThanAvailableTokens();
        }
        round.totalTokens = round.totalTokens - amount;
        totalTokensForSale = totalTokensForSale - amount;
    }


    /////// Getters ////////

    /// @notice returns tokens for given usd amount
    /// @param _usdAmount: usdt amount
    /// @return tokensOutput : returns the tokens amount
    function getTokenAmount(
        uint256 _usdAmount
    ) public view returns (uint256 tokensOutput) {
        Round storage round = rounds[currentRound];
        uint256 totalAvailableTokens = round.totalTokens - round.totalSold;
        uint256 tokensAtCurrentPrice = (_usdAmount * 10 ** TOKEN_DECIMALS) /
            round.currentPrice;

        if (totalAvailableTokens >= tokensAtCurrentPrice) {
            return tokensAtCurrentPrice;
        } else if (
            totalAvailableTokens < tokensAtCurrentPrice
        ) {
            uint256 usdUsed = (totalAvailableTokens * round.currentPrice) /
                10 ** TOKEN_DECIMALS;
            uint256 usdLeft = _usdAmount - usdUsed;
            uint256 tokensFromNewRound;
            if(currentRound < 12){
                tokensFromNewRound = (usdLeft * 10 ** TOKEN_DECIMALS) /
                round.nextPrice;
            } else {
                tokensFromNewRound = (usdLeft * 10 ** TOKEN_DECIMALS) /
                round.currentPrice;
                }
            return tokensFromNewRound + totalAvailableTokens;
        } 
    }

    /// @dev Helper funtion to get USDT price for given amount of eth
    /// @param amount No of tokens to buy
    /// @return usdAmount for given input eth
    function ethUSDHelper(
        uint256 amount
    ) public view returns (uint256 usdAmount) {
        /// chainlink oracle return price upto 8 decimals
        uint256 perEthPrice = getLatestPrice(); 
        /// as per chainlink docs, for non-eth pair(x/usd), oracles return values
        /// upto 8 decimals. For eth pairs(x/eth) it return upto 18 decimals.
        /// here, it's 8 decimals
        uint256 priceFeedDecimals = priceFeed.decimals();
        /// calculate difference b/w base decimals and usdt decimals
        uint256 divisor  = BASE_DECIMALS + priceFeedDecimals - USDT_DECIMALS;
        /// return usd amount upto 6 decimals
        usdAmount = (perEthPrice * amount) / 10 ** divisor;
    
    }

    /// @return Latest ETH price in usd
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }


    /// @return  hardcap of current round in usd
    function getHardcapCurrentRound() public view returns (uint256 hardcap) {
        uint256 totalTokens = rounds[currentRound].totalTokens;
        uint256 currentPrice = rounds[currentRound].currentPrice;
        hardcap = (totalTokens * currentPrice) / 10 ** TOKEN_DECIMALS;
       
    }

    /// @return raised amount of usd for current round
    function getRaisedAmountCurrentRound()
        public
        view
        returns (uint256 raised)
    {
        uint256 totalSold = rounds[currentRound].totalSold;
        uint256 currentPrice = rounds[currentRound].currentPrice;
        raised = (totalSold * currentPrice) / 10 ** TOKEN_DECIMALS;
    }

    /// @return endDate of current round
    function getEndDateOfCurrentRound() public view returns (uint256 endDate) {
        return rounds[currentRound].endTime;

    }

    /// @return claim status if enabled or not
    function getClaimStatus() public view returns (bool) {
        return claimEnabled;
    }

    /// @return if presale is paused or not
    function presalePausedStatus() public view returns (bool) {
        return paused;
    }
}