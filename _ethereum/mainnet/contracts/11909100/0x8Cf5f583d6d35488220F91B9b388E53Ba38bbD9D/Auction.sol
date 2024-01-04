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

    struct AuctionReserves {
        uint256 eth;
        uint256 token;
        uint256 uniswapLastPrice;
        uint256 uniswapMiddlePrice;
    }

    struct UserBid {
        uint256 eth;
        address ref;
        bool withdrawn;
    }

    struct Addresses {
        address mainToken;
        address staking;
        address payable uniswap;
        address payable recipient;
    }

    struct Options {
        uint256 autoStakeDays;
        uint256 referrerPercent;
        uint256 referredPercent;
        bool referralsOn;
        uint256 discountPercent;
        uint256 premiumPercent;
    }

    /** Roles */
    bytes32 public constant MIGRATOR_ROLE = keccak256('MIGRATOR_ROLE');
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    bytes32 public constant CALLER_ROLE = keccak256('CALLER_ROLE');

    /** Mapping */
    mapping(uint256 => AuctionReserves) public reservesOf;
    mapping(address => uint256[]) public auctionsOf;
    mapping(uint256 => mapping(address => UserBid)) public auctionBidOf;
    mapping(uint256 => mapping(address => bool)) public existAuctionsOf;

    /** Simple types */
    uint256 public lastAuctionEventId;
    uint256 public lastAuctionEventIdV1;
    uint256 public start;
    uint256 public stepTimestamp;

    Options public options;
    Addresses public addresses;
    IAuctionV1 public auctionV1;

    bool public init_;

    mapping(uint256 => mapping(address => uint256)) public autoStakeDaysOf; // NOT USED

    uint256 public middlePriceDays;

    struct VentureToken {
        // total bit 256
        address coin; // 160 bits
        uint96 percentage; // 96 bits
    }

    struct AuctionData {
        uint8 mode;
        VentureToken[] tokens;
    }

    AuctionData[7] internal auctions;
    uint8 internal ventureAutoStakeDays;

    /* New variables must go below here. */

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

    function _updatePrice() internal {
        uint256 stepsFromStart = calculateStepsFromStart();

        reservesOf[stepsFromStart].uniswapLastPrice = getUniswapLastPrice();

        reservesOf[stepsFromStart]
            .uniswapMiddlePrice = getUniswapMiddlePriceForDays();
    }

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

    function bid(
        uint256[] calldata amountOutMin,
        uint256 deadline,
        address ref
    ) external payable {
        uint256 currentDay = getCurrentDay();
        uint8 auctionMode = auctions[currentDay].mode;

        if (auctionMode == 0) {
            bidInternal(amountOutMin[0], deadline, ref);
        } else if (auctionMode == 1) {
            ventureBid(amountOutMin, deadline, currentDay);
        }
    }

    function bidInternal(
        uint256 amountOutMin,
        uint256 deadline,
        address ref
    ) internal {
        _saveAuctionData();
        _updatePrice();

        require(_msgSender() != ref, 'msg.sender == ref');

        (uint256 toRecipient, uint256 toUniswap) =
            _calculateRecipientAndUniswapAmountsToSend();

        _swapEthForToken(
            addresses.mainToken,
            amountOutMin,
            toUniswap,
            deadline
        );

        uint256 stepsFromStart = calculateStepsFromStart();

        /** If referralsOn is true allow to set ref */
        if (options.referralsOn == true) {
            auctionBidOf[stepsFromStart][_msgSender()].ref = ref;
        }

        bidCommon(stepsFromStart);

        addresses.recipient.transfer(toRecipient);

        emit Bid(msg.sender, msg.value, stepsFromStart, now);
    }

    function ventureBid(
        uint256[] memory amountOutMin,
        uint256 deadline,
        uint256 currentDay
    ) internal {
        _saveAuctionData();
        _updatePrice();

        VentureToken[] storage tokens = auctions[currentDay].tokens;

        address[] memory coinsBought = new address[](tokens.length);
        uint256[] memory amountsBought = new uint256[](tokens.length);

        for (uint8 i = 0; i < tokens.length; i++) {
            uint256 amountBought;

            uint256 amountToBuy = msg.value.mul(tokens[i].percentage).div(100);

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
                }(msg.sender, addresses.recipient, tokens[i].coin, amountToBuy);
            }

            coinsBought[i] = tokens[i].coin;
            amountsBought[i] = amountBought;
        }

        uint256 stepsFromStart = calculateStepsFromStart();
        bidCommon(stepsFromStart);

        emit VentureBid(
            msg.sender,
            msg.value,
            stepsFromStart,
            now,
            coinsBought,
            amountsBought
        );
    }

    function bidCommon(uint256 stepsFromStart) internal {
        auctionBidOf[stepsFromStart][_msgSender()].eth = auctionBidOf[
            stepsFromStart
        ][_msgSender()]
            .eth
            .add(msg.value);

        if (!existAuctionsOf[stepsFromStart][_msgSender()]) {
            auctionsOf[_msgSender()].push(stepsFromStart);
            existAuctionsOf[stepsFromStart][_msgSender()] = true;
        }

        reservesOf[stepsFromStart].eth = reservesOf[stepsFromStart].eth.add(
            msg.value
        );
    }

    function getUniswapLastPrice() internal view returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = IUniswapV2Router02(addresses.uniswap).WETH();
        path[1] = addresses.mainToken;

        uint256 price =
            IUniswapV2Router02(addresses.uniswap).getAmountsOut(1e18, path)[1];

        return price;
    }

    function getUniswapMiddlePriceForDays() internal view returns (uint256) {
        uint256 stepsFromStart = calculateStepsFromStart();

        uint256 index = stepsFromStart;
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

    function withdraw(uint256 auctionId, uint256 stakeDays) external {
        _saveAuctionData();
        _updatePrice();

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

        require(stakeDays <= 5555, 'Auction: stakeDays > 5555');

        uint256 stepsFromStart = calculateStepsFromStart();

        UserBid storage userBid = auctionBidOf[auctionId][_msgSender()];

        require(stepsFromStart > auctionId, 'Auction: Auction is active');
        require(
            userBid.eth > 0 && userBid.withdrawn == false,
            'Auction: Zero bid or withdrawn'
        );

        userBid.withdrawn = true;

        withdrawInternal(
            userBid.ref,
            userBid.eth,
            auctionId,
            stepsFromStart,
            stakeDays
        );
    }

    function withdrawV1(uint256 auctionId, uint256 stakeDays) external {
        _saveAuctionData();
        _updatePrice();

        // CHECK LAST ID HERE
        require(
            auctionId <= lastAuctionEventIdV1,
            'Auction: Invalid auction id'
        );

        require(
            stakeDays >= options.autoStakeDays,
            'Auction: stakeDays < minimum days'
        );
        require(stakeDays <= 5555, 'Auction: stakeDays > 5555');

        uint256 stepsFromStart = calculateStepsFromStart();
        require(stepsFromStart > auctionId, 'Auction: Auction is active');

        /** This stops a user from using WithdrawV1 twice, since the bid is put into memory at the end */
        UserBid storage userBid = auctionBidOf[auctionId][_msgSender()];
        require(
            userBid.eth == 0 && userBid.withdrawn == false,
            'Auction: Invalid auction ID'
        );

        (uint256 eth, address ref) =
            auctionV1.auctionBetOf(auctionId, _msgSender());
        require(eth > 0, 'Auction: Zero balance in auction/invalid auction ID');

        withdrawInternal(ref, eth, auctionId, stepsFromStart, stakeDays);

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
        uint256 stepsFromStart,
        uint256 stakeDays
    ) internal {
        uint256 payout = _calculatePayout(auctionId, eth);

        uint256 uniswapPayoutWithPercent =
            _calculatePayoutWithUniswap(auctionId, eth, payout);

        if (payout > uniswapPayoutWithPercent) {
            uint256 nextWeeklyAuction = calculateNearestWeeklyAuction();

            reservesOf[nextWeeklyAuction].token = reservesOf[nextWeeklyAuction]
                .token
                .add(payout.sub(uniswapPayoutWithPercent));

            payout = uniswapPayoutWithPercent;
        }

        if (address(ref) == address(0)) {
            IToken(addresses.mainToken).burn(address(this), payout);

            IStaking(addresses.staking).externalStake(
                payout,
                stakeDays,
                _msgSender()
            );

            emit Withdraval(msg.sender, payout, stepsFromStart, now, stakeDays);
        } else {
            IToken(addresses.mainToken).burn(address(this), payout);

            (uint256 toRefMintAmount, uint256 toUserMintAmount) =
                _calculateRefAndUserAmountsToMint(payout);

            payout = payout.add(toUserMintAmount);

            IStaking(addresses.staking).externalStake(
                payout,
                stakeDays,
                _msgSender()
            );

            emit Withdraval(msg.sender, payout, stepsFromStart, now, stakeDays);

            IStaking(addresses.staking).externalStake(toRefMintAmount, 14, ref);
        }
    }

    /** External Contract Caller functions */
    function callIncomeDailyTokensTrigger(uint256 amount)
        external
        override
        onlyCaller
    {
        // Adds a specified amount of axion to tomorrows auction
        uint256 stepsFromStart = calculateStepsFromStart();
        uint256 nextAuctionId = stepsFromStart + 1;

        reservesOf[nextAuctionId].token = reservesOf[nextAuctionId].token.add(
            amount
        );
    }

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

        uint256 stepsFromStart = calculateStepsFromStart();
        uint256 auctionId = stepsFromStart + daysInFuture;

        reservesOf[auctionId].token = reservesOf[auctionId].token.add(amount);

        return auctionId;
    }

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
        uint256 stepsFromStart = calculateStepsFromStart();
        return stepsFromStart.add(uint256(7).sub(stepsFromStart.mod(7)));
    }

    /**
     * @dev
     * friday = 0, saturday = 1, sunday = 2 etc...
     */
    function getCurrentDay() internal view returns (uint256) {
        uint256 stepsFromStart = calculateStepsFromStart();
        return stepsFromStart.mod(7);
    }

    function calculateStepsFromStart() public view returns (uint256) {
        return now.sub(start).div(stepTimestamp);
    }

    function _calculatePayoutWithUniswap(
        uint256 auctionId,
        uint256 amount,
        uint256 payout
    ) internal view returns (uint256) {
        uint256 uniswapPayout =
            reservesOf[auctionId].uniswapMiddlePrice.mul(amount).div(1e18);

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

    function _calculateRecipientAndUniswapAmountsToSend()
        private
        returns (uint256, uint256)
    {
        uint256 toRecipient = msg.value.mul(20).div(100);
        uint256 toUniswap = msg.value.sub(toRecipient);

        return (toRecipient, toUniswap);
    }

    function _calculateRefAndUserAmountsToMint(uint256 amount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 toRefMintAmount = amount.mul(options.referrerPercent).div(100);
        uint256 toUserMintAmount = amount.mul(options.referredPercent).div(100);

        return (toRefMintAmount, toUserMintAmount);
    }

    /** Storage Functions */
    function _saveAuctionData() internal {
        uint256 stepsFromStart = calculateStepsFromStart();
        AuctionReserves memory reserves = reservesOf[lastAuctionEventId];

        if (lastAuctionEventId < stepsFromStart) {
            emit AuctionIsOver(
                reserves.eth,
                reserves.token,
                lastAuctionEventId
            );
            lastAuctionEventId = stepsFromStart;
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

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }

    function setAuctionMode(uint8 _day, uint8 _mode) external onlyManager {
        auctions[_day].mode = _mode;
    }

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
