// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

/** OpenZeppelin Dependencies */
// import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
/** Uniswap */
import "./IUniswapV2Router02.sol";
/** Local Interfaces */
import "./IToken.sol";
import "./IAuction.sol";
import "./IStaking.sol";
import "./IAuctionV1.sol";

contract Auction is IAuction, Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    /** Events */
    event Bid(
        address indexed account,
        uint256 value,
        uint256 indexed auctionId,
        uint256 time
    );

    event VentureBid(
        address indexed account,
        uint256 ethBid,
        uint256 indexed auctionId,
        uint256 time,
        address[] coins,
        uint256[] amountBought
    );

    event Withdraval(
        address indexed account,
        uint256 value,
        uint256 indexed auctionId,
        uint256 time,
        uint256 stakeDays
    );

    event AuctionIsOver(uint256 eth, uint256 token, uint256 indexed auctionId);

    /** Structs */
    struct AuctionReserves {
        uint256 eth; // Amount of Eth in the auction
        uint256 token; // Amount of Axn in auction for day
        uint256 uniswapLastPrice; // Last known uniswap price from last bid
        uint256 uniswapMiddlePrice; // Using middle price days to calculate avg price
    }

    struct UserBid {
        uint256 eth; // Amount of ethereum
        address ref; // Referrer address for bid
        bool withdrawn; // Determine withdrawn
    }

    struct Addresses {
        address mainToken; // Axion token address
        address staking; // Staking platform
        address payable uniswap; // Uniswap Main Router
        address payable recipient; // Origin address for excess ethereum in auction
    }

    struct Options {
        uint256 autoStakeDays; // # of days bidder must stake once axion is won from auction
        uint256 referrerPercent; // Referral Bonus %
        uint256 referredPercent; // Referral Bonus %
        bool referralsOn; // If on referrals are used on auction
        uint256 discountPercent; // Discount in comparison to uniswap price in auction
        uint256 premiumPercent; // Premium in comparions to unsiwap price in auction
    }

    /** Roles */
    bytes32 public constant MIGRATOR_ROLE = keccak256('MIGRATOR_ROLE');
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    bytes32 public constant CALLER_ROLE = keccak256('CALLER_ROLE');

    /** Mapping */
    mapping(uint256 => AuctionReserves) public reservesOf; // [day],
    mapping(address => uint256[]) public auctionsOf;
    mapping(uint256 => mapping(address => UserBid)) public auctionBidOf;
    mapping(uint256 => mapping(address => bool)) public existAuctionsOf;

    /** Simple types */
    uint256 public lastAuctionEventId; // Index for Auction
    uint256 public lastAuctionEventIdV1; // Last index for layer 1 auction
    uint256 public start; // Beginning of contract
    uint256 public stepTimestamp; // # of seconds per "axion day" (86400)

    Options public options; // Auction options (see struct above)
    Addresses public addresses; // (See Address struct above)
    IAuctionV1 public auctionV1; // V1 Auction contract for backwards compatibility

    bool public init_; // Unneeded legacy variable to ensure init is only called once.

    mapping(uint256 => mapping(address => uint256)) public autoStakeDaysOf; // NOT USED

    uint256 public middlePriceDays; // When calculating auction price this is used to determine average

    struct VentureToken {
        address coin; // address of token to buy from swap
        uint96 percentage; // % of token to buy NOTE: (On a VCA day all Venture tokens % should add up to 100%)
    }

    struct AuctionData {
        uint8 mode; // 1 = VCA, 0 = Normal Auction
        VentureToken[] tokens; // Tokens to buy in VCA
    }

    AuctionData[7] internal auctions; // 7 values for 7 days of the week
    uint8 internal ventureAutoStakeDays; // # of auto stake days for VCA Auction

    /* UGPADEABILITY: New variables must go below here. */

    /** modifiers */
    modifier onlyCaller() {
        require(
            hasRole(CALLER_ROLE, _msgSender()),
            'Caller is not a caller role'
        );
        _;
    }

    modifier onlyManager() {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            'Caller is not a manager role'
        );
        _;
    }

    modifier onlyMigrator() {
        require(
            hasRole(MIGRATOR_ROLE, _msgSender()),
            'Caller is not a migrator'
        );
        _;
    }

    /** Update Price of current auction
        Get current axion day
        Get uniswapLastPrice
        Set middlePrice
     */
    function _updatePrice() internal {
        uint256 currentAuctionId = getCurrentAuctionId();

        /** Set reserves of */
        reservesOf[currentAuctionId].uniswapLastPrice = getUniswapLastPrice();
        reservesOf[currentAuctionId]
            .uniswapMiddlePrice = getUniswapMiddlePriceForDays();
    }

    /**
        Get token paths
        Use uniswap to buy tokens back and send to staking platform using (addresses.staking)

        @param tokenAddress {address} - Token to buy from uniswap
        @param amountOutMin {uint256} - Slippage tolerance for router
        @param amount {uint256} - Min amount expected
        @param deadline {uint256} - Deadline for trade (used for uniswap router)
     */
    function _swapEthForToken(
        address tokenAddress,
        uint256 amountOutMin,
        uint256 amount,
        uint256 deadline
    ) private returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = IUniswapV2Router02(addresses.uniswap).WETH();
        path[1] = tokenAddress;

        return
            IUniswapV2Router02(addresses.uniswap).swapExactETHForTokens{
                value: amount
            }(amountOutMin, path, addresses.staking, deadline)[1];
    }

    /**
        Bid function which routes to either venture bid or bid internal

        @param amountOutMin {uint256[]} - Slippage tolerance for uniswap router 
        @param deadline {uint256} - Deadline for trade (used for uniswap router)
        @param ref {address} - Referrer Address to get % axion from bid
     */
    function bid(
        uint256[] calldata amountOutMin,
        uint256 deadline,
        address ref
    ) external payable {
        uint256 currentDay = getCurrentDay();
        uint8 auctionMode = auctions[currentDay].mode;

        if (auctionMode == 0) {
            bidInternal(amountOutMin[0], deadline);
        } else if (auctionMode == 1) {
            ventureBid(amountOutMin, deadline, currentDay);
        }
    }

    /**
        BidInternal - Buys back axion from uniswap router and sends to staking platform

        @param amountOutMin {uint256} - Slippage tolerance for uniswap router 
        @param deadline {uint256} - Deadline for trade (used for uniswap router)
     */
    function bidInternal(uint256 amountOutMin, uint256 deadline) internal {
        _saveAuctionData();
        _updatePrice();

        /** Get percentage for recipient and uniswap (Extra function really unnecessary) */
        (uint256 toRecipient, uint256 toUniswap) =
            _calculateRecipientAndUniswapAmountsToSend();

        /** Buy back tokens from uniswap and send to staking contract */
        _swapEthForToken(
            addresses.mainToken,
            amountOutMin,
            toUniswap,
            deadline
        );

        /** Get Auction ID */
        uint256 auctionId = getCurrentAuctionId();

        /** Run common shared functionality between VCA and Normal */
        bidCommon(auctionId);

        /** Transfer any eithereum in contract to recipient address */
        addresses.recipient.transfer(toRecipient);

        /** Send event to blockchain */
        emit Bid(msg.sender, msg.value, auctionId, now);
    }

    /**
        BidInternal - Buys back axion from uniswap router and sends to staking platform

        @param amountOutMin {uint256[]} - Slippage tolerance for uniswap router 
        @param deadline {uint256} - Deadline for trade (used for uniswap router)
        @param currentDay {uint256} - currentAuctionId
     */
    function ventureBid(
        uint256[] memory amountOutMin,
        uint256 deadline,
        uint256 currentDay
    ) internal {
        _saveAuctionData();
        _updatePrice();

        /** Get the token(s) of the day */
        VentureToken[] storage tokens = auctions[currentDay].tokens;
        /** Create array to determine amount bought for each token */
        address[] memory coinsBought = new address[](tokens.length);
        uint256[] memory amountsBought = new uint256[](tokens.length);

        /** Loop over tokens to purchase */
        for (uint8 i = 0; i < tokens.length; i++) {
            /** Determine amount to purchase based on ethereum bid */
            uint256 amountBought;
            uint256 amountToBuy = msg.value.mul(tokens[i].percentage).div(100);

            /** If token is 0xFFfFfF... we buy no token and just distribute the bidded ethereum */
            if (
                tokens[i].coin !=
                address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)
            ) {
                amountBought = _swapEthForToken(
                    tokens[i].coin,
                    amountOutMin[i],
                    amountToBuy,
                    deadline
                );

                IStaking(addresses.staking).updateTokenPricePerShare(
                    msg.sender,
                    addresses.recipient,
                    tokens[i].coin,
                    amountBought
                );
            } else {
                amountBought = amountToBuy;

                IStaking(addresses.staking).updateTokenPricePerShare{
                    value: amountToBuy
                }(msg.sender, addresses.recipient, tokens[i].coin, amountToBuy); // Payable amount
            }

            coinsBought[i] = tokens[i].coin;
            amountsBought[i] = amountBought;
        }

        uint256 currentAuctionId = getCurrentAuctionId();
        bidCommon(currentAuctionId);

        emit VentureBid(
            msg.sender,
            msg.value,
            currentAuctionId,
            now,
            coinsBought,
            amountsBought
        );
    }

    /**
        Bid Common - Set common values for bid

        @param auctionId (uint256) - ID of auction
     */
    function bidCommon(uint256 auctionId) internal {
        /** Set auctionBid for bidder */
        auctionBidOf[auctionId][_msgSender()].eth = auctionBidOf[auctionId][
            _msgSender()
        ]
            .eth
            .add(msg.value);

        /** Set existsOf in order to include all auction bids for current user into one */
        if (!existAuctionsOf[auctionId][_msgSender()]) {
            auctionsOf[_msgSender()].push(auctionId);
            existAuctionsOf[auctionId][_msgSender()] = true;
        }

        reservesOf[auctionId].eth = reservesOf[auctionId].eth.add(msg.value);

        /** auction oversell check */
        uint256 tokensSold =
            (reservesOf[auctionId].eth *
                reservesOf[auctionId].uniswapMiddlePrice) / 1e18;

        uint256 tokensSoldFinal =
            tokensSold
                .add(tokensSold.mul(options.discountPercent).div(100))
                .sub(tokensSold.mul(options.premiumPercent).div(100));

        require(
            tokensSoldFinal <= reservesOf[auctionId].token,
            'Auction reached capacity'
        );
    }

    /**
        getUniswapLastPrice - Use uniswap router to determine current price based on ethereum
    */
    function getUniswapLastPrice() internal view returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = IUniswapV2Router02(addresses.uniswap).WETH();
        path[1] = addresses.mainToken;

        uint256 price =
            IUniswapV2Router02(addresses.uniswap).getAmountsOut(1e18, path)[1];

        return price;
    }

    /**
        getUniswapMiddlePriceForDays
            Use the "last known price" for the last {middlePriceDays} days to determine middle price by taking an average
     */
    function getUniswapMiddlePriceForDays() internal view returns (uint256) {
        uint256 currentAuctionId = getCurrentAuctionId();

        uint256 index = currentAuctionId;
        uint256 sum;
        uint256 points;

        while (points != middlePriceDays) {
            if (reservesOf[index].uniswapLastPrice != 0) {
                sum = sum.add(reservesOf[index].uniswapLastPrice);
                points = points.add(1);
            }

            if (index == 0) break;

            index = index.sub(1);
        }

        if (sum == 0) return getUniswapLastPrice();
        else return sum.div(points);
    }

    /**
        withdraw - Withdraws an auction bid and stakes axion in staking contract

        @param auctionId {uint256} - Auction to withdraw from
        @param stakeDays {uint256} - # of days to stake in portal
     */
    function withdraw(uint256 auctionId, uint256 stakeDays) external {
        _saveAuctionData();
        _updatePrice();

        /** Require the # of days staking > options */
        uint8 auctionMode = auctions[auctionId.mod(7)].mode;
        if (auctionMode == 0) {
            require(
                stakeDays >= options.autoStakeDays,
                'Auction: stakeDays < minimum days'
            );
        } else if (auctionMode == 1) {
            require(
                stakeDays >= ventureAutoStakeDays,
                'Auction: stakeDays < minimum days'
            );
        }

        /** Require # of staking days < 5556 */
        require(stakeDays <= 5555, 'Auction: stakeDays > 5555');

        UserBid storage userBid = auctionBidOf[auctionId][_msgSender()];

        require(
            userBid.eth > 0 && userBid.withdrawn == false,
            'Auction: Zero bid or withdrawn'
        );

        /** Set Withdrawn to true */
        userBid.withdrawn = true;

        /** Call common withdraw functions */
        withdrawInternal(userBid.ref, userBid.eth, auctionId, stakeDays);
    }

    /**
        withdraw - Withdraws an auction bid and stakes axion in staking contract

        @param auctionId {uint256} - Auction to withdraw from
        @param stakeDays {uint256} - # of days to stake in portal
        NOTE: No longer needed, as there is most likely not more bids from v1 that have not been withdraw 
     */
    function withdrawV1(uint256 auctionId, uint256 stakeDays) external {
        _saveAuctionData();
        _updatePrice();

        // Backward compatability with v1 auction
        require(
            auctionId <= lastAuctionEventIdV1,
            'Auction: Invalid auction id'
        );
        /** Ensure stake days > options  */
        require(
            stakeDays >= options.autoStakeDays,
            'Auction: stakeDays < minimum days'
        );
        require(stakeDays <= 5555, 'Auction: stakeDays > 5555');

        /** This stops a user from using WithdrawV1 twice, since the bid is put into memory at the end */
        UserBid storage userBid = auctionBidOf[auctionId][_msgSender()];
        require(
            userBid.eth == 0 && userBid.withdrawn == false,
            'Auction: Invalid auction ID'
        );

        (uint256 eth, address ref) =
            auctionV1.auctionBetOf(auctionId, _msgSender());
        require(eth > 0, 'Auction: Zero balance in auction/invalid auction ID');

        /** Common withdraw functionality */
        withdrawInternal(ref, eth, auctionId, stakeDays);

        /** Bring v1 auction bid to v2 */
        auctionBidOf[auctionId][_msgSender()] = UserBid({
            eth: eth,
            ref: ref,
            withdrawn: true
        });

        auctionsOf[_msgSender()].push(auctionId);
    }

    function withdrawInternal(
        address ref,
        uint256 eth,
        uint256 auctionId,
        uint256 stakeDays
    ) internal {
        require(
            getCurrentAuctionId() > auctionId,
            'Auction: Auction is active'
        );

        /** Calculate payout for bidder */
        uint256 payout = _calculatePayout(auctionId, eth);
        uint256 uniswapPayoutWithPercent =
            _calculatePayoutWithUniswap(auctionId, eth, payout);

        /** If auction is undersold, send overage to weekly auction */
        if (payout > uniswapPayoutWithPercent) {
            uint256 nextWeeklyAuction = calculateNearestWeeklyAuction();

            reservesOf[nextWeeklyAuction].token = reservesOf[nextWeeklyAuction]
                .token
                .add(payout.sub(uniswapPayoutWithPercent));

            payout = uniswapPayoutWithPercent;
        }

        /** Burn tokens and then call external stake on staking contract */
        IToken(addresses.mainToken).burn(address(this), payout);

        if (auctionId <= 202) {
            /** If referrer is empty simple task */
            if (address(ref) != address(0)) {
                (uint256 toRefMintAmount, uint256 toUserMintAmount) =
                    _calculateRefAndUserAmountsToMint(payout);

                /** Add referral % to payout */
                payout = payout.add(toUserMintAmount);
                payout = payout.add(payout.div(10));

                /** We do not want to mint if the referral address is the dEaD address */
                if (
                    address(ref) !=
                    address(0x000000000000000000000000000000000000dEaD)
                ) {
                    IStaking(addresses.staking).externalStake(
                        toRefMintAmount,
                        14,
                        ref
                    );
                }
            }
        } else {
            uint256 oldPayout = payout;
            //add bonus percentage based on years stake length
            if (stakeDays >= 350) {
                payout = payout.add(
                    payout.mul(stakeDays.div(350).add(5)).div(100)
                ); // multiply by percent divide by 100
            }

            //add 10% payout bonus if auction mode is regular
            uint8 auctionMode = auctions[auctionId.mod(7)].mode;

            if (auctionMode == 0) {
                uint256 payoutBonus = oldPayout.div(10);
                payout = payout.add(payoutBonus);
            }
        }

        /** Call external stake for referrer and bidder */
        IStaking(addresses.staking).externalStake(
            payout,
            stakeDays,
            _msgSender()
        );

        emit Withdraval(msg.sender, payout, auctionId, now, stakeDays);
    }

    /** External Contract Caller functions 
        @param amount {uint256} - amount to add to next dailyAuction
    */
    function callIncomeDailyTokensTrigger(uint256 amount)
        external
        override
        onlyCaller
    {
        // Adds a specified amount of axion to tomorrows auction
        uint256 currentAuctionId = getCurrentAuctionId();
        uint256 nextAuctionId = currentAuctionId + 1;

        reservesOf[nextAuctionId].token = reservesOf[nextAuctionId].token.add(
            amount
        );
    }

    /** Add Reserves to specified Auction
        @param daysInFuture {uint256} - CurrentAuctionId + daysInFuture to send Axion to
        @param amount {uint256} - Amount of axion to add to auction
     */
    function addReservesToAuction(uint256 daysInFuture, uint256 amount)
        external
        override
        onlyCaller
        returns (uint256)
    {
        // Adds a specified amount of axion to a future auction
        require(
            daysInFuture <= 365,
            'AUCTION: Days in future can not be greater then 365'
        );

        uint256 currentAuctionId = getCurrentAuctionId();
        uint256 auctionId = currentAuctionId + daysInFuture;

        reservesOf[auctionId].token = reservesOf[auctionId].token.add(amount);

        return auctionId;
    }

    /** Add reserves to next weekly auction
        @param amount {uint256} - Amount of axion to add to auction
     */
    function callIncomeWeeklyTokensTrigger(uint256 amount)
        external
        override
        onlyCaller
    {
        // Adds a specified amount of axion to the next nearest weekly auction
        uint256 nearestWeeklyAuction = calculateNearestWeeklyAuction();

        reservesOf[nearestWeeklyAuction].token = reservesOf[
            nearestWeeklyAuction
        ]
            .token
            .add(amount);
    }

    /** Calculate functions */
    function calculateNearestWeeklyAuction() public view returns (uint256) {
        uint256 currentAuctionId = getCurrentAuctionId();
        return currentAuctionId.add(uint256(7).sub(currentAuctionId.mod(7)));
    }

    /** Get current day of week
     * EX: friday = 0, saturday = 1, sunday = 2 etc...
     */
    function getCurrentDay() internal view returns (uint256) {
        uint256 currentAuctionId = getCurrentAuctionId();
        return currentAuctionId.mod(7);
    }

    function getCurrentAuctionId() public view returns (uint256) {
        return now.sub(start).div(stepTimestamp);
    }

    function calculateStepsFromStart() public view returns (uint256) {
        return now.sub(start).div(stepTimestamp);
    }

    /** Determine payout and overage
        @param auctionId {uint256} - Auction id to calculate price from
        @param amount {uint256} - Amount to use to determine overage
        @param payout {uint256} - payout
     */
    function _calculatePayoutWithUniswap(
        uint256 auctionId,
        uint256 amount,
        uint256 payout
    ) internal view returns (uint256) {
        // Get payout for user
        uint256 uniswapPayout =
            reservesOf[auctionId].uniswapMiddlePrice.mul(amount).div(1e18);

        // Get payout with percentage based on discount, premium
        uint256 uniswapPayoutWithPercent =
            uniswapPayout
                .add(uniswapPayout.mul(options.discountPercent).div(100))
                .sub(uniswapPayout.mul(options.premiumPercent).div(100));

        if (payout > uniswapPayoutWithPercent) {
            return uniswapPayoutWithPercent;
        } else {
            return payout;
        }
    }

    /** Determine payout based on amount of token and ethereum
        @param auctionId {uint256} - auction to determine payout of
        @param amount {uint256} - amount of axion
     */
    function _calculatePayout(uint256 auctionId, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return
            amount.mul(reservesOf[auctionId].token).div(
                reservesOf[auctionId].eth
            );
    }

    /** Get Percentages for recipient and uniswap for ethereum bid Unnecessary function */
    function _calculateRecipientAndUniswapAmountsToSend()
        private
        returns (uint256, uint256)
    {
        uint256 toRecipient = msg.value.mul(20).div(100);
        uint256 toUniswap = msg.value.sub(toRecipient);

        return (toRecipient, toUniswap);
    }

    /** Determine amount of axion to mint for referrer based on amount
        @param amount {uint256} - amount of axion

        @return (uint256, uint256)
     */
    function _calculateRefAndUserAmountsToMint(uint256 amount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 toRefMintAmount = amount.mul(options.referrerPercent).div(100);
        uint256 toUserMintAmount = amount.mul(options.referredPercent).div(100);

        return (toRefMintAmount, toUserMintAmount);
    }

    /** Save auction data
        Determines if auction is over. If auction is over set lastAuctionId to currentAuctionId
    */
    function _saveAuctionData() internal {
        uint256 currentAuctionId = getCurrentAuctionId();
        AuctionReserves memory reserves = reservesOf[lastAuctionEventId];

        if (lastAuctionEventId < currentAuctionId) {
            emit AuctionIsOver(
                reserves.eth,
                reserves.token,
                lastAuctionEventId
            );
            lastAuctionEventId = currentAuctionId;
        }
    }

    function initialize(address _manager, address _migrator)
        public
        initializer
    {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
        init_ = false;
    }

    /** Public Setter Functions */
    function setReferrerPercentage(uint256 percent) external onlyManager {
        options.referrerPercent = percent;
    }

    function setReferredPercentage(uint256 percent) external onlyManager {
        options.referredPercent = percent;
    }

    function setReferralsOn(bool _referralsOn) external onlyManager {
        options.referralsOn = _referralsOn;
    }

    function setAutoStakeDays(uint256 _autoStakeDays) external onlyManager {
        options.autoStakeDays = _autoStakeDays;
    }

    function setVentureAutoStakeDays(uint8 _autoStakeDays)
        external
        onlyManager
    {
        ventureAutoStakeDays = _autoStakeDays;
    }

    function setDiscountPercent(uint256 percent) external onlyManager {
        options.discountPercent = percent;
    }

    function setPremiumPercent(uint256 percent) external onlyManager {
        options.premiumPercent = percent;
    }

    function setMiddlePriceDays(uint256 _middleDays) external onlyManager {
        middlePriceDays = _middleDays;
    }

    function setRecipient(address payable newRecipient) external onlyManager {
        addresses.recipient = newRecipient;
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }

    /** VCA Setters */
    /**
        @param _day {uint8} 0 - 6 value. 0 represents Saturday, 6 Represents Friday
        @param _mode {uint8} 0 or 1. 1 VCA, 0 Normal
     */
    function setAuctionMode(uint8 _day, uint8 _mode) external onlyManager {
        auctions[_day].mode = _mode;
    }

    /**
        @param day {uint8} 0 - 6 value. 0 represents Saturday, 6 Represents Friday
        @param coins {address[]} - Addresses to buy from uniswap
        @param percentages {uint8[]} - % of coin to buy, must add up to 100%
     */
    function setTokensOfDay(
        uint8 day,
        address[] calldata coins,
        uint8[] calldata percentages
    ) external onlyManager {
        AuctionData storage auction = auctions[day];

        auction.mode = 1;
        delete auction.tokens;

        uint8 percent = 0;
        for (uint8 i; i < coins.length; i++) {
            auction.tokens.push(VentureToken(coins[i], percentages[i]));
            percent = percentages[i] + percent;
            IStaking(addresses.staking).addDivToken(coins[i]);
        }

        require(
            percent == 100,
            'AUCTION: Percentage for venture day must equal 100'
        );
    }

    /** Getter functions */
    function auctionsOf_(address account)
        external
        view
        returns (uint256[] memory)
    {
        return auctionsOf[account];
    }

    function getAuctionModes() external view returns (uint8[7] memory) {
        uint8[7] memory auctionModes;

        for (uint8 i; i < auctions.length; i++) {
            auctionModes[i] = auctions[i].mode;
        }

        return auctionModes;
    }

    function getTokensOfDay(uint8 _day)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        VentureToken[] memory ventureTokens = auctions[_day].tokens;

        address[] memory tokens = new address[](ventureTokens.length);
        uint256[] memory percentages = new uint256[](ventureTokens.length);

        for (uint8 i; i < ventureTokens.length; i++) {
            tokens[i] = ventureTokens[i].coin;
            percentages[i] = ventureTokens[i].percentage;
        }

        return (tokens, percentages);
    }

    function getVentureAutoStakeDays() external view returns (uint8) {
        return ventureAutoStakeDays;
    }
}
