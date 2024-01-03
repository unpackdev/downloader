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
        uint256 indexed time
    );

    event Withdraval(
        address indexed account,
        uint256 value,
        uint256 indexed auctionId,
        uint256 indexed time,
        uint256 stakeDays
    );

    event AuctionIsOver(uint256 eth, uint256 token, uint256 indexed auctionId);

    /** Struct */
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

    /** Variables after initial contract launch must go below here. https://github.com/OpenZeppelin/openzeppelin-sdk/issues/37 */
    /** End Variables after launch */

    /** Store autoStake duration (auctionID, address) */
    mapping(uint256 => mapping(address => uint256)) public autoStakeDaysOf;
    uint256 public middlePriceDays;

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

    function initialize(address _manager, address _migrator)
        public
        initializer
    {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
        init_ = false;
    }

    function init(
        uint256 _stepTimestamp,
        address _mainTokenAddress,
        address _stakingAddress,
        address payable _uniswapAddress,
        address payable _recipientAddress,
        address _nativeSwapAddress,
        address _foreignSwapAddress,
        address _subbalancesAddress,
        address _auctionV1Address
    ) external onlyMigrator {
        require(!init_, 'Init is active');
        init_ = true;
        /** Roles */
        _setupRole(CALLER_ROLE, _nativeSwapAddress);
        _setupRole(CALLER_ROLE, _foreignSwapAddress);
        _setupRole(CALLER_ROLE, _stakingAddress);
        _setupRole(CALLER_ROLE, _subbalancesAddress);

        // Timer
        if (start == 0) {
            start = now;
        }

        stepTimestamp = _stepTimestamp;

        // Options
        options = Options({
            autoStakeDays: 14,
            referrerPercent: 20,
            referredPercent: 10,
            referralsOn: true,
            discountPercent: 20,
            premiumPercent: 0
        });

        // Addresses
        auctionV1 = IAuctionV1(_auctionV1Address);
        addresses = Addresses({
            mainToken: _mainTokenAddress,
            staking: _stakingAddress,
            uniswap: _uniswapAddress,
            recipient: _recipientAddress
        });
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

    function setDiscountPercent(uint256 percent) external onlyManager {
        options.discountPercent = percent;
    }

    function setPremiumPercent(uint256 percent) external onlyManager {
        options.premiumPercent = percent;
    }

    function setMiddlePriceDays(uint256 _middleDays) external onlyManager {
        middlePriceDays = _middleDays;
    }

    /** Public Getter functions */
    function auctionsOf_(address account)
        public
        view
        returns (uint256[] memory)
    {
        return auctionsOf[account];
    }

    function getUniswapLastPrice() public view returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = IUniswapV2Router02(addresses.uniswap).WETH();
        path[1] = addresses.mainToken;

        uint256 price =
            IUniswapV2Router02(addresses.uniswap).getAmountsOut(1e18, path)[1];

        return price;
    }

    function getUniswapMiddlePriceForDays() public view returns (uint256) {
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

    /** Core functionality */
    /** Internal */
    function _updatePrice() internal {
        uint256 stepsFromStart = calculateStepsFromStart();

        reservesOf[stepsFromStart].uniswapLastPrice = getUniswapLastPrice();

        reservesOf[stepsFromStart]
            .uniswapMiddlePrice = getUniswapMiddlePriceForDays();
    }

    /** Externals */
    function _swapEth(
        uint256 amountOutMin,
        uint256 amount,
        uint256 deadline
    ) private {
        address[] memory path = new address[](2);

        path[0] = IUniswapV2Router02(addresses.uniswap).WETH();
        path[1] = addresses.mainToken;

        IUniswapV2Router02(addresses.uniswap).swapExactETHForTokens{
            value: amount
        }(amountOutMin, path, addresses.staking, deadline);
    }

    function bid(
        uint256 amountOutMin,
        uint256 deadline,
        address ref
    ) external payable {
        _saveAuctionData();
        _updatePrice();

        require(_msgSender() != ref, 'msg.sender == ref');

        (uint256 toRecipient, uint256 toUniswap) =
            _calculateRecipientAndUniswapAmountsToSend();

        _swapEth(amountOutMin, toUniswap, deadline);

        uint256 stepsFromStart = calculateStepsFromStart();

        /** If referralsOn is true sallow to set ref */
        if (options.referralsOn == true) {
            auctionBidOf[stepsFromStart][_msgSender()].ref = ref;
        } else {
            // Else set ref to 0x0 for this auction bid
            auctionBidOf[stepsFromStart][_msgSender()].ref = address(0);
        }

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

        addresses.recipient.transfer(toRecipient);

        emit Bid(msg.sender, msg.value, stepsFromStart, now);
    }

    function withdraw(uint256 auctionId, uint256 stakeDays) external {
        _saveAuctionData();
        _updatePrice();

        require(stakeDays >= options.autoStakeDays, 'Auction: stakeDays < minimum days');
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

        require(stakeDays >= options.autoStakeDays, 'Auction: stakeDays < minimum days');
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

        withdrawInternal(
            ref,
            eth,
            auctionId,
            stepsFromStart,
            stakeDays
        );

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

            IStaking(addresses.staking).externalStake(
                toRefMintAmount,
                options.autoStakeDays,
                ref
            );
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

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }
}
