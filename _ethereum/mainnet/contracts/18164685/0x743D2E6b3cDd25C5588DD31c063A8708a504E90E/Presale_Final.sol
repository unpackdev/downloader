// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract BLIVPreSale is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    uint256 public presaleId;
    uint256 public BASE_MULTIPLIER;
    uint256 public MONTH;

    struct Presale {
        address receiptToken;
        address saleToken;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 tokensToSell;
        uint256 baseDecimals;
        uint256 inSale;
        uint256 vestingStartTime;
        uint256 vestingCliff;
        uint256 vestingPeriod;
        uint256 enableBuyWithUsdt;
        uint256 minPurchase;
    }

    struct Vesting {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 claimStart;
        uint256 claimEnd;
        bool claimedTGE;
    }

    IERC20Upgradeable public USDTInterface;


    mapping(uint256 => bool) public paused;
    mapping(uint256 => Presale) public presale;
    mapping(address => mapping(uint256 => Vesting)) public userVesting;

    address payoutAddress;

    event PresaleCreated(
        uint256 indexed _id,
        uint256 _totalTokens,
        uint256 _startTime,
        uint256 _endTime,
        uint256 enableBuyWithUsdt
    );

    event PresaleUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    event TokensBought(
        address indexed user,
        uint256 indexed id,
        address indexed purchaseToken,
        uint256 tokensBought,
        uint256 amountPaid,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint256 indexed id,
        uint256 amount,
        uint256 timestamp
    );

    event PresaleTokenAddressUpdated(
        address indexed prevValue,
        address indexed newValue,
        uint256 timestamp
    );

    event PresaleReceiptAddressUpdated(
        address indexed prevValue,
        address indexed newValue,
        uint256 timestamp
    );

    event PresalePaused(uint256 indexed id, uint256 timestamp);
    event PresaleUnpaused(uint256 indexed id, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initializes the contract and sets key parameters
     */
    function initialize(address _usdt, address _payoutAddress) external initializer {
        require(_usdt != address(0), "Zero USDT address");
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        USDTInterface = IERC20Upgradeable(_usdt);
        payoutAddress = _payoutAddress;
        BASE_MULTIPLIER = (10**18);
        MONTH = (30 * 24 * 3600);
    }

    /**
     * @dev Creates a new presale
     * @param _startTime start time of the sale
     * @param _endTime end time of the sale
     * @param _price Per token price multiplied by (10**18)
     * @param _tokensToSell No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
     * @param _baseDecimals No of decimals for the token. (10**18), for 18 decimal token
     * @param _vestingStartTime Start time for the vesting - UNIX timestamp
     * @param _vestingCliff Cliff period for vesting in seconds
     * @param _vestingPeriod Total vesting period(after vesting cliff) in seconds
     * @param _enableBuyWithUsdt Enable/Disable buy of tokens with USDT
     */
    function createPresale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _price,
        uint256 _tokensToSell,
        uint256 _baseDecimals,
        uint256 _vestingStartTime,
        uint256 _vestingCliff,
        uint256 _vestingPeriod,
        uint256 _enableBuyWithUsdt
    ) external onlyOwner {
        require(
            _startTime > block.timestamp && _endTime > _startTime,
            "Invalid time"
        );
        require(_price > 0, "Zero price");
        require(_tokensToSell > 0, "Zero tokens to sell");
        require(_baseDecimals > 0, "Zero decimals for the token");
        require(
            _vestingStartTime >= _endTime,
            "Vesting starts before Presale ends"
        );

        presaleId++;

        presale[presaleId] = Presale(
            address(0),
            address(0),
            _startTime,
            _endTime,
            _price,
            _tokensToSell,
            _baseDecimals,
            _tokensToSell,
            _vestingStartTime,
            _vestingCliff,
            _vestingPeriod,
            _enableBuyWithUsdt,
            300
        );

        emit PresaleCreated(presaleId, _tokensToSell, _startTime, _endTime, _enableBuyWithUsdt);
    }

    /**
     * @dev To update the sale times
     * @param _id Presale id to update
     * @param _startTime New start time
     * @param _endTime New end time
     */
    function changeSaleTimes(
        uint256 _id,
        uint256 _startTime,
        uint256 _endTime
    ) external checkPresaleId(_id) onlyOwner {
        require(_startTime > 0 || _endTime > 0, "Invalid parameters");
        if (_startTime > 0) {
            require(
                block.timestamp < presale[_id].startTime,
                "Sale already started"
            );
            require(block.timestamp < _startTime, "Sale time in past");
            uint256 prevValue = presale[_id].startTime;
            presale[_id].startTime = _startTime;
            emit PresaleUpdated(
                bytes32("START"),
                prevValue,
                _startTime,
                block.timestamp
            );
        }

        if (_endTime > 0) {
            require(
                block.timestamp < presale[_id].endTime,
                "Sale already ended"
            );
            require(_endTime > presale[_id].startTime, "Invalid endTime");
            uint256 prevValue = presale[_id].endTime;
            presale[_id].endTime = _endTime;
            emit PresaleUpdated(
                bytes32("END"),
                prevValue,
                _endTime,
                block.timestamp
            );
        }
    }

    /**
     * @dev To update the vesting start time
     * @param _id Presale id to update
     * @param _vestingStartTime New vesting start time
     */
    function changeVestingStartTime(uint256 _id, uint256 _vestingStartTime)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(
            _vestingStartTime >= presale[_id].endTime,
            "Vesting starts before Presale ends"
        );
        uint256 prevValue = presale[_id].vestingStartTime;
        presale[_id].vestingStartTime = _vestingStartTime;
        emit PresaleUpdated(
            bytes32("VESTING_START_TIME"),
            prevValue,
            _vestingStartTime,
            block.timestamp
        );
    }


 
    function changePayoutAddress(address _newPayoutAddress)
        external
        onlyOwner
    {
        payoutAddress = _newPayoutAddress;

    }

    /**
     * @dev To update the sale token address
     * @param _id Presale id to update
     * @param _newAddress Sale token address
     */
    function changeSaleTokenAddress(uint256 _id, address _newAddress)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(_newAddress != address(0), "Zero token address");
        address prevValue = presale[_id].saleToken;
        presale[_id].saleToken = _newAddress;
        emit PresaleTokenAddressUpdated(
            prevValue,
            _newAddress,
            block.timestamp
        );
    }

        /**
     * @dev To update the sale token address
     * @param _id Presale id to update
     * @param _newAddress Sale token address
     */
    function changeReceiptTokenAddress(uint256 _id, address _newAddress)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(_newAddress != address(0), "Zero token address");
        address prevValue = presale[_id].receiptToken;
        presale[_id].receiptToken = _newAddress;
        emit PresaleReceiptAddressUpdated(
            prevValue,
            _newAddress,
            block.timestamp
        );
    }

    /**
     * @dev To update the price
     * @param _id Presale id to update
     * @param _newPrice New sale price of the token
     */
    function changePrice(uint256 _id, uint256 _newPrice)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(_newPrice > 0, "Zero price");
        require(
            presale[_id].startTime > block.timestamp,
            "Sale already started"
        );
        uint256 prevValue = presale[_id].price;
        presale[_id].price = _newPrice;
        emit PresaleUpdated(
            bytes32("PRICE"),
            prevValue,
            _newPrice,
            block.timestamp
        );
    }


    /**
     * @dev To update the number of tokens sold
     * @param _id Presale id to update
     * @param _newAmount amount of tokens sold
     */
    function changeSoldTokenAmount(uint256 _id, uint256 _newAmount)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(_newAmount > presale[_id].tokensToSell, "Cannot reduce amount of tokens sold");
        require(
            presale[_id].startTime > block.timestamp,
            "Sale already started"
        );
        uint256 prevValue = presale[_id].tokensToSell;
        presale[_id].tokensToSell = _newAmount;
        emit PresaleUpdated(
            bytes32("AMOUNT_SOLD"),
            prevValue,
            _newAmount,
            block.timestamp
        );
    }

    /**
     * @dev To update possibility to buy with Usdt
     * @param _id Presale id to update
     * @param _enableToBuyWithUsdt New value of enable to buy with Usdt
     */
    function changeEnableBuyWithUsdt(uint256 _id, uint256 _enableToBuyWithUsdt)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        uint256 prevValue = presale[_id].enableBuyWithUsdt;
        presale[_id].enableBuyWithUsdt = _enableToBuyWithUsdt;
        emit PresaleUpdated(
            bytes32("ENABLE_BUY_WITH_USDT"),
            prevValue,
            _enableToBuyWithUsdt,
            block.timestamp
        );
    }

    /**
     * @dev To pause the presale
     * @param _id Presale id to update
     */
    function pausePresale(uint256 _id) external checkPresaleId(_id) onlyOwner {
        require(!paused[_id], "Already paused");
        paused[_id] = true;
        emit PresalePaused(_id, block.timestamp);
    }

    /**
     * @dev To unpause the presale
     * @param _id Presale id to update
     */
    function unPausePresale(uint256 _id)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(paused[_id], "Not paused");
        paused[_id] = false;
        emit PresaleUnpaused(_id, block.timestamp);
    }


    modifier checkPresaleId(uint256 _id) {
        require(_id > 0 && _id <= presaleId, "Invalid presale id");
        _;
    }

    modifier checkSaleState(uint256 _id, uint256 amount) {
        require(
            block.timestamp >= presale[_id].startTime &&
                block.timestamp <= presale[_id].endTime,
            "Invalid time for buying"
        );
        require(
            amount > 0 && amount <= presale[_id].inSale,
            "Invalid sale amount"
        );
        _;
    }

    /**
     * @dev To buy into a presale using USDT
     * @param _id Presale id
     * @param amount No of tokens to buy
     */
    function buyWithUSDT(uint256 _id, uint256 amount)
        external
        checkPresaleId(_id)
        checkSaleState(_id, amount)
        returns (bool)
    {
        require(!paused[_id], "Presale paused");
        require(presale[_id].enableBuyWithUsdt > 0, "Not allowed to buy with USDT");
        require(amount >= presale[_id].minPurchase);
        uint256 usdPrice = amount * presale[_id].price;
        usdPrice = usdPrice / (10**12);
        presale[_id].inSale -= amount;

        Presale memory _presale = presale[_id];

        if (userVesting[_msgSender()][_id].totalAmount > 0) {
            userVesting[_msgSender()][_id].totalAmount += (amount *
                _presale.baseDecimals);
        } else {
            userVesting[_msgSender()][_id] = Vesting(
                (amount * _presale.baseDecimals),
                0,
                _presale.vestingStartTime + _presale.vestingCliff,
                _presale.vestingStartTime +
                    _presale.vestingCliff +
                    _presale.vestingPeriod,
                    false
            );
        }

        uint256 ourAllowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
        require(usdPrice <= ourAllowance, "Make sure to add enough allowance");
        (bool success, ) = address(USDTInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                // owner(),
                payoutAddress,
                usdPrice
            )
        );
        require(success, "Token payment failed");
        //transfer receipt token here
        require(
            presale[_id].receiptToken != address(0),
            "Receipt token address not set"
        );
        require(
            amount <=
                IERC20Upgradeable(presale[_id].receiptToken).balanceOf(
                    address(this)
                ),
            "Not enough BLIVX tokens in the contract"
        );
        
        bool status = IERC20Upgradeable(presale[_id].receiptToken).transfer(
            _msgSender(),
            amount * _presale.baseDecimals
        );

        emit TokensBought(
            _msgSender(),
            _id,
            address(USDTInterface),
            amount,
            usdPrice,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev To buy into a presale using USDT
     * @param _id Presale id
     * @param amount No of tokens to buy
     */
    function buyWithFiat(uint256 _id, address purchaser, uint256 amount)
        external
        onlyOwner
        checkPresaleId(_id)
        checkSaleState(_id, amount)
        returns (bool)
    {
        require(!paused[_id], "Presale paused");
        require(presale[_id].enableBuyWithUsdt > 0, "Not allowed to buy with USDT");
        presale[_id].inSale -= amount;

        Presale memory _presale = presale[_id];

        if (userVesting[purchaser][_id].totalAmount > 0) {
            userVesting[purchaser][_id].totalAmount += (amount *
                _presale.baseDecimals);
        } else {
            userVesting[purchaser][_id] = Vesting(
                (amount * _presale.baseDecimals),
                0,
                _presale.vestingStartTime + _presale.vestingCliff,
                _presale.vestingStartTime +
                    _presale.vestingCliff +
                    _presale.vestingPeriod
                    ,false
            );
        }

        //transfer receipt token here
        require(
            presale[_id].receiptToken != address(0),
            "Receipt token address not set"
        );
        require(
            amount <=
                IERC20Upgradeable(presale[_id].receiptToken).balanceOf(
                    address(this)
                ),
            "Not enough BLIVX tokens in the contract"
        );
        
        bool status = IERC20Upgradeable(presale[_id].receiptToken).transfer(
            purchaser,
            amount * presale[_id].baseDecimals
        );

        //emit some event here

        return true;
    }

    /**
     * @dev Helper funtion to get USDT price for given amount
     * @param _id Presale id
     * @param amount No of tokens to buy
     */
    function usdtBuyHelper(uint256 _id, uint256 amount)
        external
        view
        checkPresaleId(_id)
        returns (uint256 usdPrice)
    {
        usdPrice = amount * presale[_id].price;
        usdPrice = usdPrice / (10**12);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev Helper funtion to get claimable tokens for a given presale.
     * @param user User address
     * @param _id Presale id
     */
    function claimableAmount(address user, uint256 _id)
        public
        view
        checkPresaleId(_id)
        returns (uint256)
    {
        Vesting memory _user = userVesting[user][_id];

        uint256 tgeClaimAmount = (_user.totalAmount * BASE_MULTIPLIER) / (40 * BASE_MULTIPLIER);
        require(_user.totalAmount + tgeClaimAmount > 0, "Nothing to claim");
        uint256 amount = _user.totalAmount - _user.claimedAmount - tgeClaimAmount;
        uint256 amountToClaim;
        require(amount > 0, "Already claimed");

        if (block.timestamp < _user.claimStart) return 0;
        if (block.timestamp >= _user.claimEnd) return amount;


        uint256 noOfMonthsPassed = (block.timestamp - _user.claimStart) / MONTH;
        
        uint256 perMonthClaim = ((_user.totalAmount - tgeClaimAmount)  * BASE_MULTIPLIER * MONTH) /
            (_user.claimEnd - _user.claimStart);

            amountToClaim = ((noOfMonthsPassed * perMonthClaim) /
            BASE_MULTIPLIER) - _user.claimedAmount;

        
        return amountToClaim;
    }

        /**
     * @dev Helper funtion to get claimable tokens for a given presale.
     * @param user User address
     * @param _id Presale id
     */
    function claimableAmountTGE(address user, uint256 _id)
        public
        view
        checkPresaleId(_id)
        returns (uint256)
    {
        Vesting memory _user = userVesting[user][_id];
        require(_user.totalAmount > 0, "Nothing to claim");
        uint256 amount = _user.totalAmount - _user.claimedAmount;
        uint256 vestingCliff = presale[_id].vestingCliff;
        uint256 amountToClaim = (_user.totalAmount * BASE_MULTIPLIER) / (40 * BASE_MULTIPLIER);
        require(amount > 0, "Already claimed");
        require(!_user.claimedTGE, "Has already claimed TGE once.");
        require(amount >= amountToClaim, "Not enough left to claim from TGE");

        if (block.timestamp < (_user.claimStart - vestingCliff)) return 0;
        
        return amountToClaim;
    }

    /**
     * @dev To claim tokens after vesting cliff from a presale
     * @param user User address
     * @param _id Presale id
     */
    function claim(address user, uint256 _id) public returns (bool) {
        uint256 amount = claimableAmount(user, _id);
        require(amount > 0, "Zero claim amount");
        require(
            presale[_id].saleToken != address(0),
            "Presale token address not set"
        );
        require(
            amount <=
                IERC20Upgradeable(presale[_id].saleToken).balanceOf(
                    address(this)
                ),
            "Not enough tokens in the contract"
        );
        userVesting[user][_id].claimedAmount += amount;
        bool status = IERC20Upgradeable(presale[_id].saleToken).transfer(
            user,
            amount
        );
        require(status, "Token transfer failed");
        emit TokensClaimed(user, _id, amount, block.timestamp);
        return true;
    }

    /**
     * @dev To claim tokens after vesting cliff from a presale
     * @param users Array of user addresses
     * @param _id Presale id
     */
    function claimMultiple(address[] calldata users, uint256 _id)
        external
        returns (bool)
    {
        require(users.length > 0, "Zero users length");
        for (uint256 i; i < users.length; i++) {
            require(claim(users[i], _id), "Claim failed");
        }
        return true;
    }

    /**
     * @dev To claim tokens at TGE from a presale
     * @param user User address
     * @param _id Presale id
     */
    function claimTGE(address user, uint256 _id) public returns (bool) {
        uint256 amount = claimableAmountTGE(user, _id);
        require(amount > 0, "Zero claim amount");
        require(
            presale[_id].saleToken != address(0),
            "Presale token address not set"
        );
        require(
            amount <=
                IERC20Upgradeable(presale[_id].saleToken).balanceOf(
                    address(this)
                ),
            "Not enough tokens in the contract"
        );
        userVesting[user][_id].claimedTGE = true;
        bool status = IERC20Upgradeable(presale[_id].saleToken).transfer(
            user,
            amount
        );
        require(status, "Token transfer failed");
        emit TokensClaimed(user, _id, amount, block.timestamp);
        return true;
    }

        /**
     * @dev To claim tokens after vesting cliff from a presale
     * @param users Array of user addresses
     * @param _id Presale id
     */
    function claimTGEMultiple(address[] calldata users, uint256 _id)
        external
        returns (bool)
    {
        require(users.length > 0, "Zero users length");
        for (uint256 i; i < users.length; i++) {
            require(claimTGE(users[i], _id), "Claim failed");
        }
        return true;
    }

}