//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./AggregatorV3Interface.sol";
import "./ITreasuryXOX.sol";

contract OwnerWithdrawable is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function withdraw(address token, uint256 amt) public onlyOwner {
        IERC20Upgradeable(token).safeTransfer(msg.sender, amt);
    }

    function withdrawAll(address token) public onlyOwner {
        uint256 amt = IERC20Upgradeable(token).balanceOf(address(this));
        withdraw(token, amt);
    }

    function withdrawCurrency(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }
}

contract PreSaleETH is Initializable, OwnerWithdrawable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Exchange rate
    uint256 public constant BASE_DENOMINATOR = 10_000; // 10_000
    uint256 public _ONE_WEEK; // 604800
    uint256 public _ONE_HOUR; // 3600
    uint256 public _ONE_MONTH; // 2592000 seconds = 30 days

    uint256[10] public TOKEN_PRICE;
    uint256[10] public BONUS_PERCENTAGE;

    uint256[10] public DISTRIBUTION_TOKEN;

    uint256[10] public XOXS_BONUS;

    // Buy boundary
    uint256 public constant MINIMUM_BUY = 50_000_000;
    uint256 public constant MAXIMUM_BUY_WL = 5_000_000_000;

    uint256 public constant MAXIMUM_BUY = 10_000_000_000;

    uint256 public constant TOTAL_ROUND = 10;

    // Chainlink price feed
    AggregatorV3Interface internal priceFeed;

    // Treasury contract address for user receive a bonus of XOXS token
    address treasuryContractAddress;

    // Whitelist of tokens to buy from
    mapping(address => bool) public tokenWL;

    // Root of merkle tree, used to whitelist address on pre sale
    bytes32 public merkleRoot;

    IERC20Upgradeable public xoxToken;

    // Time launch DAPP
    uint256 public launchTime;
    uint256 public startTime;
    uint256 public endTime;

    // Amount each user has invested
    mapping(address => uint256) public userInvestedAmount;
    // Amount each user has invested USD
    mapping(address => uint256) private userInvestedUSDAmount;
    // Amount each user has invested USD in Whitelist round
    mapping(address => uint256) private whitelistInvestedUSDAmount;
    // Amount invested token (XOX) each user has claimed
    mapping(address => uint256) public userClaimedAmount;
    // Total amount of XOX that users has invested in each round
    mapping(uint256 => uint256) public totalRoundInvested;

    // operator is wallet can call next round
    address private operator;

    // force next round
    uint256 public forceRound;
    uint256 public forceTime;

    event PreSaleTokenInvested(
        address _sender,
        uint256 _valueUSD,
        uint256 _amountXOX,
        uint256 _amountXOXS,
        uint256 _round
    );
    event UserClaimedToken(address _sender, uint256 _amount);

    // Receive native token function
    receive() external payable {}

    fallback() external payable {}

    /* ========== CONSTRUCTOR ========== */
    /**
     * @dev constructor the contract
     * @param _xoxTokenAddress Address XOX
     * @param _whitelistTokens List of tokens accepted for payment
     * @param _treasuryContractAddress Treasury Address process logic XOXS
     * @param _priceFeedAddress Chainlink price feed
     * @param _operator Wallet can call nextRound
     * @notice Each parameters should be set carefully since it's not modifiable for each round
     */
    function initialize(
        address _xoxTokenAddress,
        address[2] memory _whitelistTokens,
        address _treasuryContractAddress,
        address _priceFeedAddress,
        address _operator,
        uint256 _startTime
    ) public initializer {
        __Ownable_init_unchained();
        xoxToken = IERC20Upgradeable(_xoxTokenAddress);
        treasuryContractAddress = _treasuryContractAddress;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        tokenWL[_whitelistTokens[0]] = true;
        tokenWL[_whitelistTokens[1]] = true;
        TOKEN_PRICE = [500, 540, 580, 620, 660, 700, 740, 780, 820, 860];
        BONUS_PERCENTAGE = [12, 11, 10, 9, 8, 7, 6, 5, 4, 3];
        DISTRIBUTION_TOKEN = [
            5_000_000 ether,
            6_000_000 ether,
            6_000_000 ether,
            7_000_000 ether,
            7_000_000 ether,
            8_000_000 ether,
            8_000_000 ether,
            8_000_000 ether,
            8_000_000 ether,
            9_000_000 ether
        ];
        XOXS_BONUS = [
            120000,
            110000,
            100000,
            90000,
            80000,
            70000,
            60000,
            50000,
            40000,
            30000
        ];
        startTime = _startTime;
        _ONE_WEEK = 604800; // 604800
        _ONE_HOUR = 3600; // 3600
        _ONE_MONTH = 2592000; // 2592000 seconds = 30 days
        endTime = _ONE_WEEK.mul(10).add(_startTime);
        operator = _operator;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    /**
     * @dev This function is designed to pause invest activity on this contract in case emergency happen
     */
    function pause() public onlyOperator {
        _pause();
    }

    /**
     * @dev Unpause the contract & let everything be normal
     */
    function unpause() public onlyOperator {
        _unpause();
    }

    /**
     * @dev Update list of addresses that are whitelisted to buy token
     */
    function updateMerkleRoot(bytes32 _merkleRoot) public onlyOperator {
        merkleRoot = _merkleRoot;
        // emit MerkleRootUpdated(_merkleRoot);
    }

    /**
     * @dev Update address of treasury contract
     */
    function updateTreasuryContractAddress(
        address _newContractAddress
    ) public onlyOwner {
        treasuryContractAddress = _newContractAddress;
    }

    /**
     * @dev Update list of tokens that are whitelisted to use for investing
     */
    function updateWhiteListToken(
        address _tokenAddress,
        bool _status
    ) public onlyOwner {
        tokenWL[_tokenAddress] = _status;
    }

    /**
     * @dev setup time for launch DAPP
     */
    function setupLaunchTime(uint256 _time) external onlyOwner {
        launchTime = _time;
    }

    /**
     * @dev If full raised of this round, call next round
     */
    function forceNextRound() external onlyOperator {
        uint256 currentRound = getCurrentRound();
        forceRound = currentRound.add(1);
        forceTime = block.timestamp;
        endTime = _ONE_WEEK.mul(TOTAL_ROUND.sub(currentRound)).add(
            block.timestamp
        );
    }

    /**
     * @dev setup startTime
     */
    function setupStartTime(uint256 _time) external onlyOperator {
        startTime = _time;
        endTime = _ONE_WEEK.mul(TOTAL_ROUND).add(_time);
    }

    /**
     * @dev setup operator: can call some function
     */
    function setupOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    /**
     * @dev Call this function to send whitelisted token to contract and get back XOX token
     * @notice Numbers of XOX token that user has invested will be locked in this contract to unlock through time (10% per month)
     * User will receive a bonus XOXS from their investment for farming & an additional bonus of XOXS on referral
     * Users can claim back their invested XOX token after unlocking time
     */
    function whiteListedInvest(
        address _tokenAddress,
        uint256 _amount,
        address _referralAddress,
        bytes32[] calldata _merkleProof
    ) public payable whenNotPaused {
        require(tokenWL[_tokenAddress], "PreSale: Token not in whitelist");
        require(
            msg.sender != _referralAddress,
            "PreSale: cannot referral yourself"
        );
        uint256 timestampCurrent = block.timestamp;
        require(
            timestampCurrent >= startTime,
            "PreSale: Not the time for Whitelist"
        );
        require(
            timestampCurrent <= startTime.add(_ONE_HOUR),
            "PreSale: Whitelist finished"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, leaf),
            "PreSale: Invalid proof!"
        );
        uint256 cash = _amount;
        if (_tokenAddress == address(0)) {
            cash = msg.value.mul(uint256(getLatestPrice())).div(1e20); // div(1e18).div(1e8).mul(1e6) => convert ETH,`, converDecimalPrice, converDecimalUSDT
        }
        require(cash >= MINIMUM_BUY, "PreSale: Minimum investment is required");
        require(
            whitelistInvestedUSDAmount[msg.sender].add(cash) <= MAXIMUM_BUY_WL,
            "PreSale: Exchange amount exceed limit!"
        );
        uint256 amounXOXToInvest = cash.mul(1e12).mul(BASE_DENOMINATOR).div(
            TOKEN_PRICE[0] // price of round1
        );
        require(
            totalRoundInvested[1].add(amounXOXToInvest) <=
                DISTRIBUTION_TOKEN[0],
            "PreSale: Invested amount has exceed total distribution of this round"
        );

        if (_tokenAddress != address(0)) {
            IERC20Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                cash
            );
        }
        whitelistInvestedUSDAmount[msg.sender] = whitelistInvestedUSDAmount[
            msg.sender
        ].add(cash);
        userInvestedUSDAmount[msg.sender] = userInvestedUSDAmount[msg.sender]
            .add(cash);
        userInvestedAmount[msg.sender] = userInvestedAmount[msg.sender].add(
            amounXOXToInvest
        );
        totalRoundInvested[1] = totalRoundInvested[1].add(amounXOXToInvest);
        uint256 amountXOXS = ITreasuryXOX(treasuryContractAddress).preSaleXOX(
            msg.sender,
            _referralAddress,
            cash,
            BONUS_PERCENTAGE[0],
            1
        );
        emit PreSaleTokenInvested(
            msg.sender,
            cash,
            amounXOXToInvest,
            amountXOXS,
            1
        );
    }

    /**
     * @dev Call this function to send whitelisted token to contract and get back XOX token
     * @notice Numbers of XOX token that user has invested will be locked in this contract to unlock through time (10% per month)
     * User will receive a bonus XOXS from their investment for farming & an additional bonus of XOXS on referral
     * Users can claim back their invested XOX token after unlocking time
     */
    function invest(
        address _tokenAddress,
        uint256 _amount,
        address _referralAddress
    ) public payable whenNotPaused {
        require(tokenWL[_tokenAddress], "PreSale: Token not in whitelist");
        require(
            msg.sender != _referralAddress,
            "PreSale: cannot referral yourself"
        );
        uint256 currentRound = getCurrentRound();
        uint256 timestampCurrent = block.timestamp;

        if (currentRound <= 1) {
            require(
                timestampCurrent >= startTime.add(1 hours),
                "PreSale: Not time to sale yet"
            );
        }
        require(timestampCurrent <= endTime, "PreSale: Sale finished");
        uint256 cash = _amount;
        if (_tokenAddress == address(0)) {
            cash = msg.value.mul(uint256(getLatestPrice())).div(1e20); // div(1e18).div(1e8).mul(1e6) => convert ETH,`, converDecimalPrice, converDecimalUSDT
        }
        require(cash >= MINIMUM_BUY, "PreSale: Minimum investment is required");
        // require(cash <= MAXIMUM_BUY, "PreSale: Maximum investment is required");
        uint256 amounXOXToInvest = cash.mul(1e12).mul(BASE_DENOMINATOR).div(
            TOKEN_PRICE[currentRound - 1]
        );

        require(
            totalRoundInvested[currentRound].add(amounXOXToInvest) <=
                DISTRIBUTION_TOKEN[currentRound - 1],
            "PreSale: Invested amount has exceed total distribution of this round"
        );

        if (_tokenAddress != address(0)) {
            IERC20Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                cash
            );
        }

        userInvestedUSDAmount[msg.sender] = userInvestedUSDAmount[msg.sender]
            .add(cash);
        userInvestedAmount[msg.sender] = userInvestedAmount[msg.sender].add(
            amounXOXToInvest
        );
        totalRoundInvested[currentRound] = totalRoundInvested[currentRound].add(
            amounXOXToInvest
        );
        uint256 amountXOXS = ITreasuryXOX(treasuryContractAddress).preSaleXOX(
            msg.sender,
            _referralAddress,
            cash,
            BONUS_PERCENTAGE[currentRound - 1],
            currentRound
        );
        emit PreSaleTokenInvested(
            msg.sender,
            cash,
            amounXOXToInvest,
            amountXOXS,
            currentRound
        );
    }

    /**
     * @dev Function for user to claim XOX token that they have invested
     */
    function claim() public whenNotPaused {
        uint256 releaseableAmount = pendingXOXInvest(msg.sender);
        require(releaseableAmount > 0, "PreSale: No tokens to claim yet");
        require(
            releaseableAmount <= xoxToken.balanceOf(address(this)),
            "PreSale: INSUFFICIENT_LIQUIDITY"
        );
        userClaimedAmount[msg.sender] = userClaimedAmount[msg.sender].add(
            releaseableAmount
        );
        xoxToken.safeTransfer(msg.sender, releaseableAmount);
        emit UserClaimedToken(msg.sender, releaseableAmount);
    }

    /**
     * @dev Function for user to view XOX token avaiable claim
     */
    function pendingXOXInvest(address account) public view returns (uint256) {
        if (block.timestamp <= launchTime) return 0;
        uint256 userInvestedBalance = userInvestedAmount[account];
        uint256 unlockedPercent = _caculateUnlockedPercent();
        uint256 unlockedAmount = userInvestedBalance.mul(unlockedPercent).div(
            100
        );
        return unlockedAmount.sub(userClaimedAmount[account]);
    }

    /**
     * @dev Get the current Round:
     * 0: not start
     * 1-10: processing
     * >10: finished
     */
    function getCurrentRound() public view returns (uint256) {
        if (block.timestamp < startTime) return 0;
        uint256 weeksPass = 1;
        if (forceRound == 0) {
            weeksPass = (block.timestamp.sub(startTime)).div(_ONE_WEEK).add(1);
        } else {
            weeksPass = (block.timestamp.sub(forceTime)).div(_ONE_WEEK).add(
                forceRound
            );
        }
        if (weeksPass > 10) return 10;
        return weeksPass;
    }

    /**
     * @dev Get the lastest price of token from price feed
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /* uint80 roundID */
            int256 price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * @dev Pre function to caculate how long has pass since round unlocked
     * @notice Current set is 10% each month, unlock all after 10 months pass
     */
    function _caculateUnlockedPercent() private view returns (uint256) {
        if (block.timestamp < launchTime) return 0;
        uint256 monthsPass = (block.timestamp.sub(launchTime))
            .div(_ONE_MONTH)
            .add(1);
        if (monthsPass > 10) return 100;
        return monthsPass.mul(10);
    }

    /**
     * @dev Throws if the sender is not the operator.
     */
    function _checkOperator() internal view virtual {
        require(
            owner() == _msgSender() || operator == _msgSender(),
            "Ownable: caller is not the owner"
        );
    }
}
