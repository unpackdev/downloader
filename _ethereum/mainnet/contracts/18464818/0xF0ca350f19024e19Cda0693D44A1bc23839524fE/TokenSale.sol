// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./DateTime.sol";

contract TokenSale is Ownable, DateTime {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public BITFtoken; // BITF Token
    IERC20 public USDToken; // Tether USDT

    uint8 public constant PRESALE_PRICE = 1; // 0.01 USDT for presale
    uint8 public constant PRIVATE_SALE1_PRICE = 3; // 0.03 USDT for private sale#1
    uint8 public constant PRIVATE_SALE2_PRICE = 5; // 0.05 USDT for private sale#2
    uint8 public constant PUBLIC_SALE_PRICE = 7; // 0.07 USDT for public sale
    uint8 public constant PRIVATE_SALE_UNLOCK_PERCENTAGE = 12; // 15% unlocked per month in private sale#1,#2
    uint8 public constant PRESALE_BENIFIT_PERCENTAGE = 25; // 25% of Net Profit Sharing in presale
    uint8 public constant PRIVATE_SALE1_BENIFIT_PERCENTAGE = 20; // 20% of Net Profit Sharing in private sale#1
    uint8 public constant PRIVATE_SALE2_BENIFIT_PERCENTAGE = 15; // 15% of Net Profit Sharing in private sale#2
    uint8 public constant PUBLIC_SALE_BENIFIT_PERCENTAGE = 10; // 10% of Net Profit Sharing in public sale
    uint256 public constant PRESALE_MAX_USDT = 1500 * 10 ** 18; // Max contribution for presale - 1500 USDT
    uint256 public constant PUBLIC_SALE_MAX_USDT = 750 * 10 ** 18; // Max contribution for public sale - 750 USDT
    uint256 public constant PRIVATE_SALE1_MAX_USDT = 200000 * 10 ** 18; // Max contribution for private sale#1 - 200000 USDT
    uint256 public constant PRIVATE_SALE2_MAX_USDT = 350000 * 10 ** 18; // Max contribution for private sale#2 - 350000 USDT
    uint256 public constant PRESALE_DURATION = 2 * 30 days; // 2 months
    uint256 public constant PRIVATE_SALE1_DURATION = 2 * 30 days; // 2 months
    uint256 public constant PRIVATE_SALE2_DURATION = 1 * 30 days; // 1 month
    uint256 public constant PRESALE_LOCK_DURATION = 6 * 30 days; // 6 months
    uint256 public constant PRIVATE_SALE_LOCK_DURATION = 9 * 30 days; // 9 months
    uint256 public constant PRESALE_AMOUNT = 60000000 * 10 ** 18; // PRE SALE Token amount
    uint256 public constant PRIVATE_SALE1_AMOUNT = 80000000 * 10 ** 18; // Private Sale#1 Token amount
    uint256 public constant PRIVATE_SALE2_AMOUNT = 100000000 * 10 ** 18; // Public Sale#2 Token amount
    uint256 public constant PUBLIC_SALE_AMOUNT = 10000000 * 10 ** 18; // Public Sale Token amount

    uint256 public presaleStartTime;
    uint256 public privateSale1StartTime;
    uint256 public privateSale2StartTime;
    uint256 public publicSaleStartTime;
    uint256 public releaseTime;
    uint256 public profitReleaseTime;
    uint256 public presaleSold;
    uint256 public privateSale1Sold;
    uint256 public privateSale2Sold;
    uint256 public publicSaleSold;

    mapping(address => uint256) public presaleBalances;
    mapping(address => uint256) public privateSale1Balances;
    mapping(address => uint256) public privateSale2Balances;
    mapping(address => uint256) public publicSaleBalances;
    mapping(address => uint256) public privateSale1Claimed;
    mapping(address => uint256) public privateSale2Claimed;

    event PreSalePurchased(
        address indexed buyer,
        uint256 USDTamount,
        uint256 BITFamount
    );
    event PrivateSale1Purchased(
        address indexed buyer,
        uint256 USDTamount,
        uint256 BITFamount
    );
    event PrivateSale2Purchased(
        address indexed buyer,
        uint256 USDTamount,
        uint256 BITFamount
    );
    event PublicSalePurchased(
        address indexed buyer,
        uint256 USDTamount,
        uint256 BITFamount
    );

    event ClaimPresale(address indexed claimant, uint256 amount);
    event ClaimPrivateSale1(address indexed claimant, uint256 amount);
    event ClaimPrivateSale2(address indexed claimant, uint256 amount);
    event ClaimPublicSale(address indexed claimant, uint256 amount);

    /**
     @notice contructor of Token Sale, 
     @param _usdToken USDT Token contract address
     */
    constructor(address _usdToken) {
        require(_usdToken != address(0), "Invalid USDT token address");
        USDToken = IERC20(_usdToken);
    }

    /**
     @notice Set BITF Token contract address
     @dev Only Owner is accessible
     @param _bitfToken BITF Token contract address
     */
    function setToken(address _bitfToken) external onlyOwner {
        require(_bitfToken != address(0), "Invalid token address");
        BITFtoken = IERC20(_bitfToken);
    }

    /**
     @notice Set Pre Sale Start Time
     @dev Only Owner is accessible
     @param _year PRE SALE START Year
     @param _month PRESALE START Month
     @param _day PRE SALE START DAY
     */
    function setPresaleStartTime(
        uint16 _year,
        uint8 _month,
        uint8 _day
    ) external onlyOwner {
        uint256 _presaleStartTime = toTimestamp(_year, _month, _day);
        require(
            _presaleStartTime > block.timestamp,
            "Invalid presale start time"
        );
        presaleStartTime = _presaleStartTime;
    }

    function setPrivateSale1StartTime(
        uint16 _year,
        uint8 _month,
        uint8 _day
    ) external onlyOwner {
        uint256 _privatesale1StartTime = toTimestamp(_year, _month, _day);
        require(
            _privatesale1StartTime > block.timestamp &&
                _privatesale1StartTime >= presaleStartTime + PRESALE_DURATION,
            "Invalid private sale#1 start time"
        );
        privateSale1StartTime = _privatesale1StartTime;
    }

    function setPrivateSale2StartTime(
        uint16 _year,
        uint8 _month,
        uint8 _day
    ) external onlyOwner {
        uint256 _privatesale2StartTime = toTimestamp(_year, _month, _day);
        require(
            _privatesale2StartTime > block.timestamp &&
                _privatesale2StartTime >=
                privateSale1StartTime + PRIVATE_SALE1_DURATION,
            "Invalid private sale#2 start time"
        );
        privateSale2StartTime = _privatesale2StartTime;
    }

    function setPublicSaleStartTime(
        uint16 _year,
        uint8 _month,
        uint8 _day
    ) external onlyOwner {
        uint256 _publicSaleStartTime = toTimestamp(_year, _month, _day);
        require(
            _publicSaleStartTime > block.timestamp &&
                _publicSaleStartTime >=
                privateSale1StartTime + PRIVATE_SALE2_DURATION,
            "Invalid public sale start time"
        );
        publicSaleStartTime = _publicSaleStartTime;
    }

    /**
     @notice Set Release Time. Time Stamp Start date for Token release Jun 21 2024
     @dev OnlyOwner is accessible
     */
    function setReleaseTime(
        uint16 _year,
        uint8 _month,
        uint8 _day
    ) external onlyOwner {
        releaseTime = toTimestamp(_year, _month, _day);
    }

    /**
     @notice Set Profit Release Time. Time Stamp Start date for Token release August 21 2024
     @dev OnlyOwner is accessible
     */
    function setProfitReleaseTime(
        uint16 _year,
        uint8 _month,
        uint8 _day
    ) external onlyOwner {
        profitReleaseTime = toTimestamp(_year, _month, _day);
    }

    /**
     @notice Buy BITF tokens in Presale & Private Sale #1 & Private Sale #2 & Public Sale
     @dev After presale starts, this function would be available.
     @param _amount BITF token amount to buy
     */
    function buyBitfinder(uint256 _amount) external {
        uint256 currentTime = block.timestamp;
        uint256 poolBalance = BITFtoken.balanceOf(address(this));
        uint256 usdtamount;
        require(currentTime >= presaleStartTime, "Presale has not started yet");
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount <= poolBalance, "Buy token amount is exceeded");
        if (currentTime <= presaleStartTime + PRESALE_DURATION) {
            require(
                presaleSold + _amount <= PRESALE_AMOUNT,
                "Presale Cap reached"
            );
            uint256 _balance;
            _balance = presaleBalances[_msgSender()];
            require(
                ((_balance + _amount) * PRESALE_PRICE) / 100 <=
                    PRESALE_MAX_USDT,
                "Reached to Max Token contribuiton of Presale"
            );
            usdtamount = (_amount * PRESALE_PRICE) / 100;
            USDToken.safeTransferFrom(_msgSender(), address(this), usdtamount);
            presaleBalances[_msgSender()] += _amount;
            presaleSold += _amount;
            emit PreSalePurchased(_msgSender(), usdtamount, _amount);
        } else if (
            currentTime >= privateSale1StartTime &&
            currentTime <= privateSale1StartTime + PRIVATE_SALE1_DURATION
        ) {
            require(
                privateSale1Sold + _amount <= PRIVATE_SALE1_AMOUNT,
                "Private sale#1 Cap reached"
            );
            uint256 _balance;
            _balance = privateSale1Balances[_msgSender()];
            require(
                ((_balance + _amount) * PRIVATE_SALE1_PRICE) / 100 <=
                    PRIVATE_SALE1_MAX_USDT,
                "Reached to Max Token contribuiton of Private sale#1"
            );
            usdtamount = (_amount * PRIVATE_SALE1_PRICE) / 100;
            USDToken.safeTransferFrom(_msgSender(), address(this), usdtamount);
            privateSale1Balances[_msgSender()] += _amount;
            privateSale1Sold += _amount;
            emit PrivateSale1Purchased(_msgSender(), usdtamount, _amount);
        } else if (
            currentTime >= privateSale2StartTime &&
            currentTime <= privateSale2StartTime + PRIVATE_SALE2_DURATION
        ) {
            require(
                privateSale2Sold + _amount <= PRIVATE_SALE2_AMOUNT,
                "Private sale#2 Cap reached"
            );
            uint256 _balance;
            _balance = privateSale2Balances[_msgSender()];
            require(
                ((_balance + _amount) * PRIVATE_SALE2_PRICE) / 100 <=
                    PRIVATE_SALE2_MAX_USDT,
                "Reached to Max Token contribuiton of Private sale#2"
            );
            usdtamount = (_amount * PRIVATE_SALE2_PRICE) / 100;
            USDToken.safeTransferFrom(_msgSender(), address(this), usdtamount);
            privateSale2Balances[_msgSender()] += _amount;
            privateSale2Sold += _amount;
            emit PrivateSale2Purchased(_msgSender(), usdtamount, _amount);
        } else if (currentTime >= publicSaleStartTime) {
            require(
                publicSaleSold + _amount <= PUBLIC_SALE_AMOUNT,
                "Public sale Cap reached"
            );
            uint256 _balance;
            _balance = publicSaleBalances[_msgSender()];
            require(
                ((_balance + _amount) * PUBLIC_SALE_PRICE) / 100 <=
                    PUBLIC_SALE_MAX_USDT,
                "Reached to Max Token contribuiton of Public sale"
            );
            usdtamount = (_amount * PUBLIC_SALE_PRICE) / 100;
            USDToken.safeTransferFrom(_msgSender(), address(this), usdtamount);
            publicSaleBalances[_msgSender()] += _amount;
            publicSaleSold += _amount;
            emit PublicSalePurchased(_msgSender(), usdtamount, _amount);
        }
    }

    function claimPresaleToken(uint256 _amount) external {
        require(
            block.timestamp >= releaseTime,
            "Token is not available to release yet"
        );
        require(
            presaleBalances[_msgSender()] >= _amount,
            "Claim amount exceeds balance"
        );
        BITFtoken.safeTransfer(_msgSender(), _amount);
        presaleBalances[_msgSender()] -= _amount;
        emit ClaimPresale(_msgSender(), _amount);
    }

    function claimPrivateSale1Token(uint256 _amount) external {
        require(
            block.timestamp >= releaseTime,
            "Token is not available to release yet"
        );
        uint256 initialBalance = privateSale1Balances[_msgSender()] +
            privateSale1Claimed[_msgSender()];
        require(
            getPrivateSaleClaimAmount(initialBalance) >=
                _amount + privateSale1Claimed[_msgSender()],
            "Claim amount exceeds Available Amount"
        );
        BITFtoken.safeTransfer(_msgSender(), _amount);
        privateSale1Balances[_msgSender()] -= _amount;
        privateSale1Claimed[_msgSender()] += _amount;
        emit ClaimPrivateSale1(_msgSender(), _amount);
    }

    function claimPrivateSale2Token(uint256 _amount) external {
        require(
            block.timestamp >= releaseTime,
            "Token is not available to release yet"
        );
        uint256 initialBalance = privateSale2Balances[_msgSender()] +
            privateSale2Claimed[_msgSender()];
        require(
            getPrivateSaleClaimAmount(initialBalance) >=
                _amount + privateSale2Claimed[_msgSender()],
            "Claim amount exceeds Available Amount"
        );
        BITFtoken.safeTransfer(_msgSender(), _amount);
        privateSale2Balances[_msgSender()] -= _amount;
        privateSale2Claimed[_msgSender()] += _amount;
        emit ClaimPrivateSale2(_msgSender(), _amount);
    }

    function claimPublicSaleToken(uint256 _amount) external {
        require(
            block.timestamp >= releaseTime,
            "Token is not available to release yet"
        );
        require(
            publicSaleBalances[_msgSender()] >= _amount,
            "Claim amount exceeds balance"
        );
        BITFtoken.safeTransfer(_msgSender(), _amount);
        publicSaleBalances[_msgSender()] -= _amount;
        emit ClaimPublicSale(_msgSender(), _amount);
    }

    function getPrivateSaleClaimAmount(
        uint256 balance
    ) public view returns (uint256) {
        uint256 currentTimeStamp = block.timestamp;
        require(currentTimeStamp >= block.timestamp );
        uint16 currentYear = getYear(currentTimeStamp);
        uint8 currentMonth = getMonth(currentTimeStamp);
        uint16 releaseYear = getYear(releaseTime);
        uint8 releaseMonth = getMonth(releaseTime);
        uint256 months = (currentYear - releaseYear) * 12;
        if(releaseMonth > currentMonth) {
            months -= (releaseMonth - currentMonth);
        } else {
            months += (currentMonth - releaseMonth);
        }
        uint256 amount = balance
            .mul(PRIVATE_SALE_UNLOCK_PERCENTAGE)
            .div(100)
            .mul(months);
        if (amount > balance) return balance;
        return amount;
    }

    function withdrawToken() external onlyOwner {
        uint256 balance = BITFtoken.balanceOf(address(this));
        require(balance > 0, "No USDT tokens to withdraw");
        BITFtoken.safeTransfer(owner(), balance);
    }

    function withdrawUSDT() external onlyOwner {
        uint256 balance = USDToken.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        USDToken.safeTransfer(owner(), balance);
    }
}
