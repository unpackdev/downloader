//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

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

interface StakingManager {
    function depositByPresale(address _user, uint256 _amount) external;
}

interface IRouter {
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract PresaleV5 is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 public totalTokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimStart;
    address public saleToken;
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
    bool public whitelistClaimOnly;

    IERC20Upgradeable public USDTInterface;
    Aggregator public aggregatorInterface;
    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasClaimed;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public wertWhitelisted;
    address public admin;

    StakingManager public stakingManagerInterface;
    bool public stakeingWhitelistStatus;
    uint256 public totalBoughtAndStaked;

    uint256 public directTotalTokensSold;
    uint256 public directUsdPrice;
    bool public dynamicSaleState;
    uint256 public percent;
    uint256 public maxTokensToSell;
    IRouter public router;

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
    event TokensBoughtAndStaked(
        address indexed user,
        uint256 indexed tokensBought,
        address indexed purchaseToken,
        uint256 amountPaid,
        uint256 usdEq,
        uint256 timestamp
    );
    event TokensClaimedAndStaked(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

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
     * @dev To get latest ETH price in 10**18 format
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev To claim tokens after claiming starts
     */
    function claim() external whenNotPaused returns (bool) {
        require(saleToken != address(0), "Sale token not added");
        require(!isBlacklisted[_msgSender()], "This Address is Blacklisted");
        if (whitelistClaimOnly) {
            require(
                isWhitelisted[_msgSender()],
                "User not whitelisted for claim"
            );
        }
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint256 amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        bool success = IERC20Upgradeable(saleToken).transfer(
            _msgSender(),
            amount
        );
        require(success, "Token transfer failed");
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        return true;
    }

    function claimAndStake() external whenNotPaused returns (bool) {
        require(saleToken != address(0), "Sale token not added");
        require(!isBlacklisted[_msgSender()], "This Address is Blacklisted");
        if (stakeingWhitelistStatus) {
            require(
                isWhitelisted[_msgSender()],
                "User not whitelisted for stake"
            );
        }
        uint256 amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to stake");
        stakingManagerInterface.depositByPresale(_msgSender(), amount);
        delete userDeposits[_msgSender()];
        emit TokensClaimedAndStaked(_msgSender(), amount, block.timestamp);
        return true;
    }

    /**
     * @dev funtion to set price for direct buy token
     * @param price price of token in WEI
     */
    function setTokenPrice(uint256 price) external onlyOwner {
        directUsdPrice = price;
    }

    function setDynamicSaleState(
        bool state,
        address _router
    ) external onlyOwner {
        dynamicSaleState = state;
        router = IRouter(_router);
    }

    function fetchPrice(uint256 amountOut) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        path[1] = 0xB62E45c3Df611dcE236A6Ddc7A493d79F9DFadEf;
        uint256[] memory amounts = router.getAmountsIn(amountOut, path);
        return amounts[0] + ((amounts[0] * percent) / 100);
    }

    function setPercent(uint256 _percent) external onlyOwner {
        percent = _percent;
    }

    function setMaxTokensToSell(uint256 _maxTokensToSell) external onlyOwner {
        maxTokensToSell = _maxTokensToSell;
    }

    function buyWithEthDynamic(
        uint256 amount
    ) external payable whenNotPaused nonReentrant returns (bool) {
        require(dynamicSaleState, "dynamic sale not active");
        require(
            amount <= maxTokensToSell - directTotalTokensSold,
            "amount exceeds max tokens to be sold"
        );
        directTotalTokensSold += amount;
        uint256 ethAmount = fetchPrice(amount * baseDecimals);
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;
        sendValue(payable(paymentWallet), ethAmount);
        if (excess > 0) sendValue(payable(_msgSender()), excess);
        stakingManagerInterface.depositByPresale(
            _msgSender(),
            amount * baseDecimals
        );
        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            ethAmount,
            0,
            block.timestamp
        );
        return true;
    }

    function buyWithEthWertDynamic(
        address user,
        uint256 amount
    ) external payable whenNotPaused nonReentrant returns (bool) {
        require(
            wertWhitelisted[_msgSender()],
            "Caller not whitelisted for wert"
        );
        require(dynamicSaleState, "dynamic sale not active");
        require(
            amount <= maxTokensToSell - directTotalTokensSold,
            "amount exceeds max tokens to be sold"
        );
        directTotalTokensSold += amount;
        uint256 ethAmount = fetchPrice(amount * baseDecimals);
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;
        sendValue(payable(paymentWallet), ethAmount);
        if (excess > 0) sendValue(payable(user), excess);
        stakingManagerInterface.depositByPresale(user, amount * baseDecimals);
        emit TokensBought(
            user,
            amount,
            address(0),
            ethAmount,
            0,
            block.timestamp
        );
        return true;
    }

    function buyWithUSDTDynamic(
        uint256 amount
    ) external whenNotPaused returns (bool) {
        require(dynamicSaleState, "dynamic sale not active");
        require(
            amount <= maxTokensToSell - directTotalTokensSold,
            "amount exceeds max tokens to be sold"
        );
        directTotalTokensSold += amount;
        uint256 ethAmount = fetchPrice(amount * baseDecimals);
        uint256 usdPrice = (ethAmount * getLatestPrice()) / baseDecimals;
        uint256 price = usdPrice / (10 ** 12);
        (bool success, ) = address(USDTInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                paymentWallet,
                price
            )
        );
        require(success, "Token payment failed");
        stakingManagerInterface.depositByPresale(
            _msgSender(),
            amount * baseDecimals
        );
        emit TokensBought(
            _msgSender(),
            amount,
            address(USDTInterface),
            price,
            usdPrice,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev Helper funtion to get ETH price for given amount
     * @param amount No of tokens to buy
     */
    function ethBuyHelper(uint256 amount) external view returns (uint256) {
        uint256 usdPrice = amount * directUsdPrice;
        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        return (ethAmount);
    }

    /**
     * @dev To add wert contract addresses to whitelist
     * @param _addressesToWhitelist addresses of the contract
     */
    function whitelistUsersForWERT(
        address[] calldata _addressesToWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _addressesToWhitelist.length; i++) {
            wertWhitelisted[_addressesToWhitelist[i]] = true;
        }
    }

    /**
     * @dev To remove wert contract addresses to whitelist
     * @param _addressesToRemoveFromWhitelist addresses of the contracts
     */
    function removeFromWhitelistForWERT(
        address[] calldata _addressesToRemoveFromWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _addressesToRemoveFromWhitelist.length; i++) {
            wertWhitelisted[_addressesToRemoveFromWhitelist[i]] = false;
        }
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

    /**
     * @dev To set status for claim whitelisting
     * @param _status bool value
     */
    function setClaimWhitelistStatus(bool _status) external onlyOwner {
        whitelistClaimOnly = _status;
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
     * @dev To get array of round details at once
     * @param _no array index
     */
    function roundDetails(
        uint256 _no
    ) external view returns (uint256[] memory) {
        return rounds[_no];
    }

    /**
     * @dev to update userDeposits for purchases made on BSC
     * @param _users array of users
     * @param _userDeposits array of userDeposits associated with users
     */
    function updateFromBSC(
        address[] calldata _users,
        uint256[] calldata _userDeposits
    ) external onlyOwner {
        require(_users.length == _userDeposits.length, "Length mismatch");
        for (uint256 i = 0; i < _users.length; i++) {
            userDeposits[_users[i]] += _userDeposits[i];
        }
    }

    /**
     * @dev to initialize staking manager with new addredd
     * @param _stakingManagerAddress address of the staking smartcontract
     */
    function setStakingManager(
        address _stakingManagerAddress
    ) external onlyOwner {
        require(
            _stakingManagerAddress != address(0),
            "staking manager cannot be inatialized with zero address"
        );
        stakingManagerInterface = StakingManager(_stakingManagerAddress);
        IERC20Upgradeable(saleToken).approve(
            _stakingManagerAddress,
            type(uint256).max
        );
    }
}
