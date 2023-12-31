// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
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

interface StakingManager {
    function depositByPresale(address _user, uint256 _amount) external;
}

contract PresaleV1 is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 public tokenPrice;
    uint256 public totalTokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public baseDecimals;
    uint256 public maxTokensToBuy;
    uint256 public usdRaised;
    address public paymentWallet;
    bool public whitelistClaimOnly;

    Aggregator public aggregatorInterface;
    IERC20Upgradeable public saleToken;
    IERC20Upgradeable public USDTInterface;
    StakingManager public stakingManagerInterface;
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

    /**
     * @dev Initializes the contract and sets key parameters
     * @param _oracle Oracle contract to fetch ETH/USDT price
     * @param _usdt USDT token contract address
     * @param _saleToken sale token address
     * @param _stakingContract address of the staking smartcontract
     * @param _tokenPrice presale price of the token
     * @param _startTime start time of the presale
     * @param _endTime end time of the presale
     * @param _maxTokensToBuy amount of max tokens to buy
     * @param _paymentWallet address to recive payments
     */
    function initialize(
        address _oracle,
        address _usdt,
        address _saleToken,
        address _stakingContract,
        uint256 _tokenPrice,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokensToBuy,
        address _paymentWallet
    ) external initializer {
        require(_oracle != address(0), "Zero aggregator address");
        require(_usdt != address(0), "Zero USDT address");
        require(_saleToken != address(0), "Zero token address");
        require(_stakingContract != address(0), "Zero staking address");
        require(
            _startTime > block.timestamp && _endTime > _startTime,
            "Invalid time"
        );
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        baseDecimals = (10 ** 18);
        aggregatorInterface = Aggregator(_oracle);
        USDTInterface = IERC20Upgradeable(_usdt);
        saleToken = IERC20Upgradeable(_saleToken);
        stakingManagerInterface = StakingManager(_stakingContract);
        tokenPrice = _tokenPrice;
        startTime = _startTime;
        endTime = _endTime;
        maxTokensToBuy = _maxTokensToBuy;
        paymentWallet = _paymentWallet;
        saleToken.approve(_stakingContract, type(uint256).max);
        emit SaleTimeSet(startTime, endTime, block.timestamp);
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
        require(
            (amount * baseDecimals) <= saleToken.balanceOf(address(this)),
            "Amount exceeds tokens remaining for sale"
        );
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
        _transferTokens(amount * baseDecimals);
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
        _transferTokens(amount * baseDecimals);
        return true;
    }

    /**
     * @dev To buy into a presale and stake using USDT
     * @param amount No of tokens to buy
     */
    function buyWithUSDTAndStake(
        uint256 amount
    ) external checkSaleState(amount) whenNotPaused returns (bool) {
        _buyWithUSDT(amount);
        _stakeTokens(amount * baseDecimals);
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
        _buyWithEth(amount);
        _stakeTokens(amount * baseDecimals);
        return true;
    }

    function _buyWithUSDT(uint256 amount) internal {
        uint256 usdPrice = amount * tokenPrice;
        uint256 price = usdPrice / (10 ** 12);
        totalTokensSold += amount;
        usdRaised += usdPrice;
        uint256 ourAllowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
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
        uint256 usdPrice = amount * tokenPrice;
        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        require(msg.value >= ethAmount, "Less payment");
        totalTokensSold += amount;
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
        stakingManagerInterface.depositByPresale(_msgSender(), amount);
    }

    /**
     * @dev Helper funtion to get ETH price for given amount
     * @param amount No of tokens to buy
     */
    function ethBuyHelper(
        uint256 amount
    ) external view returns (uint256 ethAmount) {
        uint256 usdPrice = amount * tokenPrice;
        ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    }

    /**
     * @dev Helper funtion to get USDT price for given amount
     * @param amount No of tokens to buy
     */
    function usdtBuyHelper(
        uint256 amount
    ) external view returns (uint256 usdPrice) {
        usdPrice = amount * tokenPrice;
        usdPrice = usdPrice / (10 ** 12);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev To claim tokens
     */
    function claim(
        uint256 _amount,
        bytes32[] memory _proof
    ) external whenNotPaused returns (bool) {
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

    /**
     * @dev To update the sale times
     * @param _startTime New start time
     * @param _endTime New end time
     */
    function setSaleTimes(
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

    function setMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
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

    /**
     * @dev To set payment wallet address
     * @param _newPaymentWallet new payment wallet address
     */
    function setPaymentWallet(address _newPaymentWallet) external onlyOwner {
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
}
