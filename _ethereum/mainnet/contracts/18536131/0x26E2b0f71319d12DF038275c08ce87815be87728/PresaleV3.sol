// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

interface Aggregator {
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

interface Vault {
    function depositByPresale(address user, uint256 amount) external;
}

contract PresaleV3 is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 public totalTokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public baseDecimals;
    uint256 public maxTokensToBuy;
    uint256 public currentStep;
    uint256[][3] public rounds;
    uint256 public checkPoint;
    uint256 public usdRaised;
    uint256[] public prevCheckpoints;
    uint256[] public remainingTokensTracker;
    uint256 public timeConstant;
    address public paymentWallet;
    bool public dynamicTimeFlag;
    address public admin;

    IERC20Upgradeable public USDTInterface;
    Aggregator public aggregatorInterface;
    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public wertWhitelisted;

    /**
     * @dev V2 additions
     */
    mapping(address => uint256) public userDeposits2;

    /**
     * @dev V3 additions
     */
    bool public claimStatus;
    bool public whitelistClaimOnly;
    IERC20Upgradeable public saleToken;
    Vault public vaultInterface;
    bytes32 public claimMerkleRoot;
    mapping(address => uint256) public userClaimed;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isWhitelisted;

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
    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event MaxTokensUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeV3(
        address _saleToken,
        address _vaultContract
    ) external reinitializer(3) {
        require(_saleToken != address(0), "Zero token address");
        require(_vaultContract != address(0), "Zero vault address");
        saleToken = IERC20Upgradeable(_saleToken);
        vaultInterface = Vault(_vaultContract);
        saleToken.approve(address(vaultInterface), type(uint256).max);
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
        if (
            _amount + total > rounds[0][currentStep] ||
            block.timestamp >= rounds[2][currentStep]
        ) {
            require(currentStep < (rounds[0].length - 1), "Wrong params");

            if (block.timestamp >= rounds[2][currentStep]) {
                require(
                    rounds[0][currentStep] + _amount <=
                        rounds[0][currentStep + 1],
                    "Cant Purchase More in individual tx"
                );
                USDTAmount = _amount * rounds[1][currentStep + 1];
            } else {
                require(
                    total + _amount <= rounds[0][currentStep + 1],
                    "Cant Purchase More in individual tx"
                );
                uint256 tokenAmountForCurrentPrice = rounds[0][currentStep] -
                    total;
                USDTAmount =
                    tokenAmountForCurrentPrice *
                    rounds[1][currentStep] +
                    (_amount - tokenAmountForCurrentPrice) *
                    rounds[1][currentStep + 1];
            }
        } else USDTAmount = _amount * rounds[1][currentStep];
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
            require(block.timestamp < startTime, "Sale already started");
            require(block.timestamp < _startTime, "Sale time in past");
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
            require(block.timestamp < endTime, "Sale already ended");
            require(_endTime > startTime, "Invalid endTime");
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
     * @dev To get latest ETH price in 10**18 format
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    modifier checkSaleState(uint256 amount) {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Invalid time for buying"
        );
        require(amount > 0, "Invalid sale amount");
        require(amount <= maxTokensToBuy, "Amount exceeds max tokens to buy");
        _;
    }

    /**
     * @dev To buy into a presale using USDT
     * @param amount No of tokens to buy
     */
    function buyWithUSDT(
        uint256 amount
    ) external checkSaleState(amount) whenNotPaused returns (bool) {
        _buyWithUSDT(amount);
        return true;
    }

    /**
     * @dev To buy into a presale using ETH
     * @param amount No of tokens to buy
     */
    function buyWithEth(
        uint256 amount
    )
        external
        payable
        checkSaleState(amount)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        _buyWithEth(amount);
        return true;
    }

    /**
     * @dev To buy into a presale and stake using USDT
     * @param amount No of tokens to buy
     */
    function buyWithUSDTAndStake(
        uint256 amount
    ) external checkSaleState(amount) whenNotPaused returns (bool) {
        uint256 amountDecimals = amount * baseDecimals;
        require(
            amountDecimals <= saleToken.balanceOf(address(this)),
            "Amount exceeds tokens remaining for sale"
        );
        _buyWithUSDT(amount);
        _stakeTokens(amountDecimals);
        userClaimed[_msgSender()] += amountDecimals;
        emit TokensClaimed(_msgSender(), amountDecimals, block.timestamp);
        return true;
    }

    /**
     * @dev To buy into a presale and stake using ETH
     * @param amount No of tokens to buy
     */
    function buyWithEthAndStake(
        uint256 amount
    )
        external
        payable
        checkSaleState(amount)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        uint256 amountDecimals = amount * baseDecimals;
        require(
            amountDecimals <= saleToken.balanceOf(address(this)),
            "Amount exceeds tokens remaining for sale"
        );
        _buyWithEth(amount);
        _stakeTokens(amountDecimals);
        userClaimed[_msgSender()] += amountDecimals;
        emit TokensClaimed(_msgSender(), amountDecimals, block.timestamp);
        return true;
    }

    function _buyWithUSDT(uint256 amount) internal {
        uint256 usdPrice = calculatePrice(amount);
        totalTokensSold += amount;
        if (checkPoint != 0) checkPoint += amount;
        uint256 total = totalTokensSold > checkPoint
            ? totalTokensSold
            : checkPoint;
        if (
            total > rounds[0][currentStep] ||
            block.timestamp >= rounds[2][currentStep]
        ) {
            if (block.timestamp >= rounds[2][currentStep]) {
                checkPoint = rounds[0][currentStep] + amount;
            } else {
                if (dynamicTimeFlag) {
                    manageTimeDiff();
                }
            }
            uint256 unsoldTokens = total > rounds[0][currentStep]
                ? 0
                : rounds[0][currentStep] - total;
            remainingTokensTracker.push(unsoldTokens);
            currentStep += 1;
        }
        userDeposits2[_msgSender()] += (amount * baseDecimals);
        usdRaised += usdPrice;
        uint256 ourAllowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
        uint256 price = usdPrice / (10 ** 12);
        require(price <= ourAllowance, "Make sure to add enough allowance");
        (bool success, ) = address(USDTInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                paymentWallet,
                price
            )
        );
        require(success, "Token payment failed");
        emit TokensBought(
            _msgSender(),
            amount,
            address(USDTInterface),
            price,
            usdPrice,
            block.timestamp
        );
    }

    function _buyWithEth(uint256 amount) internal {
        uint256 usdPrice = calculatePrice(amount);
        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        require(msg.value >= ethAmount, "Less payment");
        totalTokensSold += amount;
        if (checkPoint != 0) checkPoint += amount;
        uint256 total = totalTokensSold > checkPoint
            ? totalTokensSold
            : checkPoint;
        if (
            total > rounds[0][currentStep] ||
            block.timestamp >= rounds[2][currentStep]
        ) {
            if (block.timestamp >= rounds[2][currentStep]) {
                checkPoint = rounds[0][currentStep] + amount;
            } else {
                if (dynamicTimeFlag) {
                    manageTimeDiff();
                }
            }
            uint256 unsoldTokens = total > rounds[0][currentStep]
                ? 0
                : rounds[0][currentStep] - total;
            remainingTokensTracker.push(unsoldTokens);
            currentStep += 1;
        }
        userDeposits2[_msgSender()] += (amount * baseDecimals);
        usdRaised += usdPrice;
        sendValue(payable(paymentWallet), ethAmount);
        uint256 excess = msg.value - ethAmount;
        if (excess > 0) sendValue(payable(_msgSender()), excess);
        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            ethAmount,
            usdPrice,
            block.timestamp
        );
    }

    function _transferTokens(uint256 amount) internal {
        bool success = saleToken.transfer(_msgSender(), amount);
        require(success, "Token transfer failed");
    }

    function _stakeTokens(uint256 amount) internal {
        vaultInterface.depositByPresale(_msgSender(), amount);
    }

    /**
     * @dev Helper funtion to get ETH price for given amount
     * @param amount No of tokens to buy
     */
    function ethBuyHelper(
        uint256 amount
    ) external view returns (uint256 ethAmount) {
        uint256 usdPrice = calculatePrice(amount);
        ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    }

    /**
     * @dev Helper funtion to get USDT price for given amount
     * @param amount No of tokens to buy
     */
    function usdtBuyHelper(
        uint256 amount
    ) external view returns (uint256 usdPrice) {
        usdPrice = calculatePrice(amount);
        usdPrice = usdPrice / (10 ** 12);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    function startClaim() external onlyOwner returns (bool) {
        require(claimStatus == false, "Claim already set");
        claimStatus = true;
        return true;
    }

    /**
     * @dev To claim tokens
     */
    function claim(
        uint256 _amount,
        bytes32[] memory _proof
    ) external whenNotPaused returns (bool) {
        require(claimStatus, "Claim has not started yet");
        uint256 tokensToClaim = _claim(_amount, _proof);
        _transferTokens(tokensToClaim);
        return true;
    }

    /**
     * @dev To claim and stake tokens
     */
    function claimAndStake(
        uint256 _amount,
        bytes32[] memory _proof
    ) external whenNotPaused returns (bool) {
        uint256 tokensToClaim = _claim(_amount, _proof);
        _stakeTokens(tokensToClaim);
        return true;
    }

    function _claim(
        uint256 _amount,
        bytes32[] memory _proof
    ) internal returns (uint256) {
        require(claimMerkleRoot != 0, "Merkle root not set");
        require(!isBlacklisted[_msgSender()], "This Address is Blacklisted");
        if (whitelistClaimOnly) {
            require(
                isWhitelisted[_msgSender()],
                "User not whitelisted for claim"
            );
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, _amount)))
        );
        require(
            MerkleProofUpgradeable.verify(_proof, claimMerkleRoot, leaf),
            "Invalid proof"
        );
        uint256 tokensToClaim = _amount - userClaimed[_msgSender()];
        require(tokensToClaim > 0, "Nothing to claim");
        require(
            tokensToClaim <= saleToken.balanceOf(address(this)),
            "Amount exceeds tokens remaining for claim"
        );
        userClaimed[_msgSender()] += tokensToClaim;
        emit TokensClaimed(_msgSender(), tokensToClaim, block.timestamp);
        return tokensToClaim;
    }

    /**
     * @dev To withdraw all sale tokens from contract
     */
    function withdrawRemainingTokens() external onlyOwner {
        uint256 balance = saleToken.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        _transferTokens(balance);
    }

    /**
     * @dev To add users to blacklist which restricts blacklisted users from claiming
     * @param _usersToBlacklist addresses of the users
     */
    function blacklistUsers(
        address[] calldata _usersToBlacklist
    ) external onlyOwner {
        for (uint256 i = 0; i < _usersToBlacklist.length; i++) {
            isBlacklisted[_usersToBlacklist[i]] = true;
        }
    }

    /**
     * @dev To remove users from blacklist which restricts blacklisted users from claiming
     * @param _userToRemoveFromBlacklist addresses of the users
     */
    function removeFromBlacklist(
        address[] calldata _userToRemoveFromBlacklist
    ) external onlyOwner {
        for (uint256 i = 0; i < _userToRemoveFromBlacklist.length; i++) {
            isBlacklisted[_userToRemoveFromBlacklist[i]] = false;
        }
    }

    /**
     * @dev To add users to whitelist which restricts users from claiming if claimWhitelistStatus is true
     * @param _usersToWhitelist addresses of the users
     */
    function whitelistUsers(
        address[] calldata _usersToWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _usersToWhitelist.length; i++) {
            isWhitelisted[_usersToWhitelist[i]] = true;
        }
    }

    /**
     * @dev To remove users from whitelist which restricts users from claiming if claimWhitelistStatus is true
     * @param _userToRemoveFromWhitelist addresses of the users
     */
    function removeFromWhitelist(
        address[] calldata _userToRemoveFromWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _userToRemoveFromWhitelist.length; i++) {
            isWhitelisted[_userToRemoveFromWhitelist[i]] = false;
        }
    }

    function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
        require(_maxTokensToBuy > 0, "Zero max tokens to buy value");
        uint256 prevValue = maxTokensToBuy;
        maxTokensToBuy = _maxTokensToBuy;
        emit MaxTokensUpdated(prevValue, _maxTokensToBuy, block.timestamp);
    }

    /**
     * @dev To set status for claim whitelisting
     * @param _status bool value
     */
    function setClaimWhitelistStatus(bool _status) external onlyOwner {
        whitelistClaimOnly = _status;
    }

    function changeRoundsData(uint256[][3] memory _rounds) external onlyOwner {
        rounds = _rounds;
    }

    /**
     * @dev To set payment wallet address
     * @param _newPaymentWallet new payment wallet address
     */
    function changePaymentWallet(address _newPaymentWallet) external onlyOwner {
        require(_newPaymentWallet != address(0), "address cannot be zero");
        paymentWallet = _newPaymentWallet;
    }

    /**
     * @dev to set merkleroot for claim verification
     * @param _merkleRoot bytes32
     */
    function setClaimMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        claimMerkleRoot = _merkleRoot;
    }

    /**
     * @dev To manage time gap between two rounds
     */
    function manageTimeDiff() internal {
        for (uint256 i; i < rounds[2].length - currentStep; i++) {
            rounds[2][currentStep + i] = block.timestamp + i * timeConstant;
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
    function roundDetails(
        uint256 _no
    ) external view returns (uint256[] memory) {
        return rounds[_no];
    }

    /**
     * @dev To increment the rounds from backend
     */
    function incrementCurrentStep() external {
        require(
            msg.sender == admin || msg.sender == owner(),
            "caller not admin or owner"
        );
        prevCheckpoints.push(checkPoint);
        if (dynamicTimeFlag) {
            manageTimeDiff();
        }
        if (checkPoint < rounds[0][currentStep]) {
            remainingTokensTracker.push(rounds[0][currentStep] - checkPoint);
            checkPoint = rounds[0][currentStep];
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
        require(_index < rounds[0].length, "invalid index");
        if (_newNoOfTokens > 0) {
            rounds[0][_index] = _newNoOfTokens;
        }
        if (_newPrice > 0) {
            rounds[1][_index] = _newPrice;
        }
        if (_newTime > 0) {
            rounds[2][_index] = _newTime;
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
        rounds[0].push(_newNoOfTokens);
        rounds[1].push(_newPrice);
        rounds[2].push(_newTime);
        return true;
    }

    /**
     * @dev To set admin
     * @param _admin new admin wallet address
     */
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }
}
