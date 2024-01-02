//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./AddressUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";

import "./IOracle.sol";

interface Aggregator {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PresaleV2 is
    //Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    struct Round {
        uint256 amount;
        uint256 price;
        uint256 endTime;
    }

    struct User {
        uint id;
        address addr;
        address referrer;
        uint bought;
    }

    uint256 public totalTokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimStart;
    address public saleToken;
    uint256 public baseDecimals;
    uint256 public usdtDecimals;
    uint256 public tokenDecimals;
    uint256 public maxTokensToBuy;
    uint256 public currentStep;
    Round[] public rounds;
    uint256 public checkPoint;
    uint256 public usdRaised;
    uint256[] public prevCheckpoints;
    uint256[] public remainingTokensTracker;
    uint256 public timeConstant;
    address public paymentWallet;
    bool public dynamicTimeFlag;
    bool public whitelistClaimOnly;

    IERC20 public USDT;
    Aggregator public priceFeed;
    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasClaimed;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isWhitelisted;
    address public admin;

    //referral system
    mapping(address => User) public users;
    mapping(uint => address) public idToUser;
    uint public lastUserId;

    event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);
    event SaleTimeUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );
    event TokensBought(
        address indexed user,
        uint256 indexed tokensBought,
        address indexed purchaseToken,
        uint256 amountPaid,
        uint256 usdEq,
        uint256 timestamp
    );
    event ReferralReward(
        address indexed referrer,
        uint256 indexed reward,
        address indexed user,
        uint256 tokensBought,
        uint256 timestamp
    );
    event TokensAdded(
        address indexed token,
        uint256 noOfTokens,
        uint256 timestamp
    );
    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event ClaimStartUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );
    event MaxTokensUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    function initialize(
        address _priceFeed,
        address _usdt,
        uint256 _startTime,
        uint256 _endTime,
        Round[] memory _rounds
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        priceFeed = Aggregator(_priceFeed);
        USDT = IERC20(_usdt);

        baseDecimals = 10 ** 18;
        usdtDecimals = 10 ** IERC20Metadata(_usdt).decimals();

        startTime = _startTime;
        endTime = _endTime;

        dynamicTimeFlag = true;
        maxTokensToBuy = 9_999_999_999;

        admin = 0x9B9460204B24E605aCf5b98a68e44B09979779c6;

        _changeRoundsData(_rounds);
    }

    /**
     * @dev To pause the presale
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev To unpause the presale
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev To calculate the price in USD for given amount of tokens.
     * @param _amount No of tokens
     */
    function calculatePrice(uint256 _amount) public view returns (uint256) {
        uint256 USDTAmount;
        uint256 total = checkPoint == 0 ? totalTokensSold : checkPoint;
        require(_amount <= maxTokensToBuy, "Amount exceeds max tokens to buy");
        if (
            _amount + total > rounds[currentStep].amount ||
            block.timestamp >= rounds[currentStep].endTime
        ) {
            require(currentStep < (rounds.length - 1), "Wroong paarams");

            if (block.timestamp >= rounds[currentStep].endTime) {
                require(
                    rounds[currentStep].amount + _amount <=
                        rounds[currentStep + 1].amount,
                    "Cant Purchase More in individual tx"
                );
                USDTAmount = _amount * rounds[currentStep + 1].price;
            } else {
                uint256 tokenAmountForCurrentPrice = rounds[currentStep]
                    .amount - total;
                USDTAmount =
                    tokenAmountForCurrentPrice *
                    rounds[currentStep].price +
                    (_amount - tokenAmountForCurrentPrice) *
                    rounds[currentStep + 1].price;
            }
        } else USDTAmount = _amount * rounds[currentStep].price;
        return USDTAmount;
    }

    /**
     * @dev To update the sale times
     * @param _startTime New start time
     * @param _endTime New end time
     */
    function changeSaleTimes(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(_startTime > 0 || _endTime > 0, "Invalid parameters");
        if (_startTime > 0) {
            require(block.timestamp < startTime, "Saale already staarted");
            require(block.timestamp < _startTime, "SalE tIme iin past");
            uint256 prevValue = startTime;
            startTime = _startTime;
            emit SaleTimeUpdated(
                bytes32("START"),
                prevValue,
                _startTime,
                block.timestamp
            );
        }

        if (_endTime > 0) {
            require(_endTime > startTime, "Invaalid endTime");
            uint256 prevValue = endTime;
            endTime = _endTime;
            emit SaleTimeUpdated(
                bytes32("END"),
                prevValue,
                _endTime,
                block.timestamp
            );
        }
    }

    /**
     * @dev To get latest Native price in 10**18 format
     */
    function getLatestPrice() public view returns (uint256 price) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        price = uint256(answer) * (10 ** (18 - priceFeed.decimals()));
    }

    /**
     * @dev To get latest token price in 10**18 format
     */
    function getTokenPrice(address token) public view returns (uint256 price) {
        IOracle oracle = IOracle(0xddaD6a46f6a20B5c8e0B02AB7BC33949CEAAae0A);
        uint256 tokenPrice = oracle.getAssetPrice(token);
        price = tokenPrice * (10 ** (18 - 8)); // because chainlink decimals is 8
    }

    modifier checkSaleState(uint256 amount) {
        require(block.timestamp >= startTime, "Invaalid time foor buying");
        require(amount > 0, "Invaallid sale amount");
        _;
    }

    function addUserIfNot(address referrer) internal {
        if (users[_msgSender()].id == 0) {
            uint userId = lastUserId + 1;
            User memory user = User({
                id: userId,
                addr: _msgSender(),
                referrer: referrer,
                bought: 0
            });
            users[_msgSender()] = user;
            idToUser[userId] = _msgSender();
            lastUserId = userId;
        }
    }

    function updateRound(uint amount, uint amountInUSD) internal {
        totalTokensSold += amount;
        checkPoint += amount;

        uint256 total = totalTokensSold > checkPoint
            ? totalTokensSold
            : checkPoint;
        if (
            total > rounds[currentStep].amount ||
            block.timestamp >= rounds[currentStep].endTime
        ) {
            if (block.timestamp >= rounds[currentStep].endTime) {
                checkPoint = rounds[currentStep].amount + amount;
            } else {
                if (dynamicTimeFlag) {
                    manageTimeDiff();
                }
            }
            uint256 unsoldTokens = total > rounds[currentStep].amount
                ? 0
                : rounds[currentStep].amount - total;
            remainingTokensTracker.push(unsoldTokens);
            currentStep += 1;
        }

        users[_msgSender()].bought += (amount);
        usdRaised += amountInUSD;
    }

    /**
     * @dev To buy into a presale using given token
     * @param token token to buy
     * @param amount No of tokens to buy
     * @param referrer referrer address
     */
    function buyWith(
        address token,
        uint256 amount,
        address referrer
    )
        external
        payable
        checkSaleState(amount)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(
            _msgSender() != referrer,
            "must be different msg.sender and referrer"
        );

        uint256 tokenPrice = getTokenPrice(token);
        uint256 _tokenDecimals = token == address(0)
            ? baseDecimals
            : 10 ** IERC20Metadata(token).decimals();

        require(tokenPrice > 0, "Can't buy with the token");

        uint256 usdPrice = calculatePrice(amount);
        uint256 tokenAmount = (usdPrice * _tokenDecimals) / tokenPrice;

        if (token == address(0)) {
            require(msg.value >= tokenAmount, "Less payment");
            uint256 excess = msg.value - tokenAmount;
            if (excess > 0) sendValue(payable(_msgSender()), excess);
        } else {
            uint256 ourAllowance = IERC20(token).allowance(
                _msgSender(),
                address(this)
            );
            require(
                tokenAmount <= ourAllowance,
                "Make sure to add enough allowance"
            );
            IERC20(token).safeTransferFrom(
                _msgSender(),
                address(this),
                tokenAmount
            );
        }

        addUserIfNot(referrer);

        updateRound(amount, usdPrice);

        IERC20(saleToken).safeTransfer(_msgSender(), amount * tokenDecimals);
        emit TokensBought(
            _msgSender(),
            amount,
            token,
            tokenAmount,
            usdPrice,
            block.timestamp
        );

        if (users[_msgSender()].referrer != address(0)) {
            uint256 reward = (amount * 5) / 100;
            IERC20(saleToken).safeTransfer(
                users[_msgSender()].referrer,
                reward * tokenDecimals
            ); //Reward 5% of bought amount
            emit ReferralReward(
                users[_msgSender()].referrer,
                reward,
                _msgSender(),
                amount,
                block.timestamp
            );
        }

        return true;
    }

    /**
     * @dev Helper funtion to get Native price for given amount
     * @param amount No of tokens to buy
     */
    function nativeBuyHelper(
        uint256 amount
    ) external view returns (uint256 nativeAmount) {
        uint256 usdPrice = calculatePrice(amount);
        nativeAmount = (usdPrice * baseDecimals) / getLatestPrice();
    }

    /**
     * @dev Helper funtion to get USDT price for given amount
     * @param amount No of tokens to buy
     */
    function usdtBuyHelper(
        uint256 amount
    ) external view returns (uint256 usdPrice) {
        usdPrice = calculatePrice(amount);
        usdPrice = usdPrice / (baseDecimals / usdtDecimals);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Native Payment failed");
    }

    /**
     * @dev To set the claim start time and sale token address by the owner
     * @param _saleToken sale toke address
     */
    function startClaim(address _saleToken) external onlyOwner returns (bool) {
        require(_saleToken != address(0), "Zero token address");

        saleToken = _saleToken;
        tokenDecimals = 10 ** IERC20Metadata(_saleToken).decimals();

        return true;
    }

    /**
     * @dev To claim tokens after claiming starts
     */
    function claim() external whenNotPaused returns (bool) {
        require(saleToken != address(0), "Sale token not added");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint256 amount = userDeposits[_msgSender()] /
            (baseDecimals / tokenDecimals);
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        bool success = IERC20(saleToken).transfer(_msgSender(), amount);
        require(success, "Token transfer failed");
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        return true;
    }

    function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
        require(_maxTokensToBuy > 0, "Zero max tokens to buy value");
        uint256 prevValue = maxTokensToBuy;
        maxTokensToBuy = _maxTokensToBuy;
        emit MaxTokensUpdated(prevValue, _maxTokensToBuy, block.timestamp);
    }

    function _changeRoundsData(Round[] memory _rounds) private {
        delete rounds;
        for (uint256 i; i < _rounds.length; i++) {
            rounds.push(_rounds[i]);
        }
    }

    function changeRoundsData(Round[] memory _rounds) external onlyOwner {
        _changeRoundsData(_rounds);
    }

    /**
     * @dev To manage time gap between two rounds
     */
    function manageTimeDiff() internal {
        uint256 gap = rounds[currentStep].endTime - block.timestamp;
        for (uint256 i; i < rounds.length - currentStep; i++) {
            rounds[currentStep + i].endTime -= gap;
        }
    }

    /**
     * @dev To set time constant for manageTimeDiff()
     * @param _timeConstant time in <days>*24*60*60 format
     */
    function setTimeConstant(uint256 _timeConstant) external onlyOwner {
        timeConstant = _timeConstant;
    }

    /**
     * @dev To get array of round details at once
     * @param _no array index
     */
    function roundDetails(uint256 _no) external view returns (Round memory) {
        return rounds[_no];
    }

    /**
     * @dev To increment the rounds from backend
     */
    function incrementCurrentStep() external onlyOwner {
        prevCheckpoints.push(checkPoint);
        if (dynamicTimeFlag) {
            manageTimeDiff();
        }
        if (checkPoint < rounds[currentStep].amount) {
            remainingTokensTracker.push(
                rounds[currentStep].amount - checkPoint
            );
            checkPoint = rounds[currentStep].amount;
        }
        currentStep++;
    }

    /**
     * @dev To change details of the round
     * @param _step round for which you want to change the details
     * @param _checkpoint token tracker amount
     */
    function setCurrentStep(
        uint256 _step,
        uint256 _checkpoint
    ) external onlyOwner {
        currentStep = _step;
        checkPoint = _checkpoint;
    }

    /**
     * @dev To set time shift functionality on/off
     * @param _dynamicTimeFlag bool value
     */
    function setDynamicTimeFlag(bool _dynamicTimeFlag) external onlyOwner {
        dynamicTimeFlag = _dynamicTimeFlag;
    }

    function trackRemainingTokens() external view returns (uint256[] memory) {
        return remainingTokensTracker;
    }

    /**
     * @dev To set time shift functionality on/off
     * @param _index index of the round we need to change
     * @param _newNoOfTokens number of tokens to be sold
     * @param _newPrice price for the round
     * @param _newTime new end time
     */
    function changeIndividualRoundData(
        uint256 _index,
        uint256 _newNoOfTokens,
        uint256 _newPrice,
        uint256 _newTime
    ) external onlyOwner returns (bool) {
        require(_index <= rounds.length, "invalid index");
        if (_newNoOfTokens > 0) {
            rounds[_index].amount = _newNoOfTokens;
        }
        if (_newPrice > 0) {
            rounds[_index].price = _newPrice;
        }
        if (_newTime > 0) {
            rounds[_index].endTime = _newTime;
        }
        return true;
    }

    /**
     * @dev To set time shift functionality on/off
     * @param _newNoOfTokens number of tokens to be sold
     * @param _newPrice price for the round
     * @param _newTime new end time
     */
    function addNewRound(
        uint256 _newNoOfTokens,
        uint256 _newPrice,
        uint256 _newTime
    ) external onlyOwner returns (bool) {
        require(_newNoOfTokens > 0, "invalid no of tokens");
        require(_newPrice > 0, "invalid new price");
        require(_newTime > 0, "invalid new time");

        Round memory r;
        r.amount = _newNoOfTokens;
        r.price = _newPrice;
        r.endTime = _newTime;
        rounds.push(r);

        return true;
    }

    /**
     * @dev To withdraw funds
     */
    function withdraw(
        address recipient,
        uint256 _amount
    ) external onlyAdmin(msg.sender) {
        uint256 nativeBalance = address(this).balance;
        require(nativeBalance > 0, "Contract has no Native Token balance");
        require(_amount <= nativeBalance, "Amount exceed balance");
        (bool sent, ) = payable(recipient).call{value: nativeBalance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev To withdraw funds
     */
    function withdrawToken(
        address recipient,
        address token
    ) external onlyAdmin(msg.sender) {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        require(tokenBalance > 0, "Contract has no USDT balance");
        IERC20(token).safeTransfer(recipient, tokenBalance);
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        require(
            _newAdmin != address(0),
            "New admin should not be zero address"
        );
        admin = _newAdmin;
    }

    modifier onlyAdmin(address _caller) {
        require(_caller == admin, "Only admin can call this function");
        _;
    }
}
