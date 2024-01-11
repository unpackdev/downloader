// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.12;

import "./IERC20.sol";
import "./Initializable.sol";
import "./AggregatorV3Interface.sol";
import "./AccessControl.sol";
import "./OwnableUpgradeable.sol";

contract Presale is AccessControl, Initializable, OwnableUpgradeable {
    AggregatorV3Interface internal priceFeed;

    mapping(address => BuyerData) buyerInfo;
    mapping(string => TokenData) tokenInfo;
    mapping(address => bool) discountWhitelist;
    mapping(string => uint256) referralCodes;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalUnitAmount;
    uint256 public totalAmountSold;

    uint256 public unitPrice;
    uint256 public distrPercWithHYFI;
    uint256 public HYFIexchangeRate;
    address internal collectorWallet;
    address[] internal _buyersAddressList;
    string[] internal referralCodeList;

    struct BuyerData {
        uint256 totalAmountBought;
        uint256 referralAmountBought;
        mapping(string => uint256) referrals;
        string[] referralsList;
    }

    struct TokenData {
        IERC20 tokenAddress;
        uint256 totalAmountBought;
        uint256 decimals;
    }

    bytes32 public constant HYFI_SETTER_ROLE = keccak256("HYFI_SETTER_ROLE");

    event AllUnitsSold(uint256 unitAmount, uint256 endTime);
    event AddedToWhitelist(address indexed account);
    event CurrencyWithdrawn(address from, address to, uint256 amount);
    event ERC20Withdrawn(
        address from,
        address to,
        uint256 amount,
        address tokenAddress
    );
    event FundsRetrieved(address addr, uint256 amount);
    event UnitSold(string token, uint256 amount);
    event RemovedFromWhitelist(address indexed account);

    modifier addressNotZero(address addr) {
        require(
            addr != address(0),
            "Passed parameter has zero address declared"
        );
        _;
    }

    modifier amountNotZero(uint256 amount) {
        require(amount > 0, "Passed amount is equal to zero");
        _;
    }

    modifier limitedExchangeRate(uint256 rate) {
        require(
            rate > 0 && rate <= 10**18,
            "Exhange rate must be greater than 0 and less or equal to 10^18"
        );
        _;
    }

    modifier ongoingSale() {
        require(
            block.timestamp >= startTime,
            "You can not buy any units, sale has not started yet"
        );
        require(
            block.timestamp <= endTime,
            "You can no longer buy any units, time expired"
        );
        _;
    }

    modifier saleEnded() {
        require(
            block.timestamp >= endTime,
            "You can still buy items, sale has not ended yet"
        );
        _;
    }

    modifier possiblePurchaseUntilHardcap(uint256 amount) {
        require(
            totalAmountSold + amount <= totalUnitAmount,
            "Hardcap is reached, can not buy that many units"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function initialize(
        IERC20 USDTtokenAddress,
        IERC20 USDCtokenAddress,
        IERC20 HYFItokenAddress,
        address _collectorWallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _unitPrice,
        uint256 _HYFIexchangeRate
    ) public payable initializer {
        __Ownable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(HYFI_SETTER_ROLE, msg.sender);
        priceFeed = AggregatorV3Interface(
            /**
             * Eterscan: https://etherscan.io/address/0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419#readContract
             * Network: Ethereum Mainnet Link to this section
             * Aggregator: ETH/USD
             * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
             */
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );

        tokenInfo["USDT"].tokenAddress = USDTtokenAddress;
        tokenInfo["USDT"].decimals = tokenInfo["USDC"].decimals = 10**6;

        tokenInfo["USDC"].tokenAddress = USDCtokenAddress;

        tokenInfo["HYFI"].tokenAddress = HYFItokenAddress;
        tokenInfo["HYFI"].decimals = tokenInfo["ETH"].decimals = 10**18;

        collectorWallet = _collectorWallet;

        unitPrice = _unitPrice;
        distrPercWithHYFI = 50;
        HYFIexchangeRate = _HYFIexchangeRate;

        startTime = _startTime;
        endTime = _endTime;

        totalUnitAmount = 10_000;
        totalAmountSold = 0;
    }

    function buyWithTokens(
        string memory token,
        bool buyWithHYFI,
        uint256 amount,
        string memory referralCode
    )
        external
        payable
        addressNotZero(msg.sender)
        amountNotZero(amount)
        ongoingSale
        possiblePurchaseUntilHardcap(amount)
    {
        require(
            keccak256(abi.encodePacked(token)) ==
                keccak256(abi.encodePacked("USDT")) ||
                keccak256(abi.encodePacked(token)) ==
                keccak256(abi.encodePacked("USDC")),
            "No stable coin provided"
        );
        uint256 discount = _discountPercentageCalculator(amount, msg.sender);
        if (buyWithHYFI) {
            _buyWithHYFIToken(token, amount, discount);
            emit UnitSold(token, amount);
        } else {
            _buyWithMainToken(token, amount, discount);
            emit UnitSold(token, amount);
        }
        if (bytes(referralCode).length != 0) {
            _updateReferral(amount, referralCode, msg.sender);
        }
    }

    function buyWithCurrency(uint256 amount, string memory referralCode)
        external
        payable
        addressNotZero(msg.sender)
        amountNotZero(amount)
        ongoingSale
        possiblePurchaseUntilHardcap(amount)
    {
        _buyWithCurrency(
            amount,
            _discountPercentageCalculator(amount, msg.sender)
        );
        if (bytes(referralCode).length != 0) {
            _updateReferral(amount, referralCode, msg.sender);
        }
    }

    function _buyWithMainToken(
        string memory token,
        uint256 unitAmount,
        uint256 discount
    ) internal {
        uint256 priceTotal = simpleTokenPaymentCalculator(
            token,
            unitAmount,
            discount
        );
        require(
            tokenInfo[token].tokenAddress.balanceOf(msg.sender) >= priceTotal,
            "Buyer does not have enough funds to make this purchase"
        );
        tokenInfo[token].tokenAddress.transferFrom(
            msg.sender,
            collectorWallet,
            priceTotal
        );
        _updateData(token, unitAmount, msg.sender);
    }

    function _buyWithHYFIToken(
        string memory token,
        uint256 unitAmount,
        uint256 discount
    ) internal limitedExchangeRate(HYFIexchangeRate) {
        uint256 HYFItokenPayment;
        uint256 stableCoinPaymentAmount;
        (
            stableCoinPaymentAmount,
            HYFItokenPayment
        ) = mixedTokenPaymentCalculator(token, unitAmount, discount);
        tokenInfo[token].tokenAddress.transferFrom(
            msg.sender,
            collectorWallet,
            stableCoinPaymentAmount
        );
        tokenInfo["HYFI"].tokenAddress.transferFrom(
            msg.sender,
            collectorWallet,
            HYFItokenPayment
        );
        _updateData("HYFI", unitAmount, msg.sender);
    }

    function _buyWithCurrency(uint256 unitAmount, uint256 discount) internal {
        uint256 priceTotal = currencyPaymentCalculator(unitAmount, discount);
        require(
            msg.value == priceTotal,
            "Buyer does not have enough funds to make this purchase"
        );
        payable(collectorWallet).transfer(priceTotal);
        _updateData("ETH", unitAmount, msg.sender);
    }

    function _updateData(
        string memory token,
        uint256 unitAmount,
        address buyer
    ) internal {
        totalAmountSold += unitAmount;
        tokenInfo[token].totalAmountBought += unitAmount;
        if (buyerInfo[buyer].totalAmountBought == 0) {
            _buyersAddressList.push(buyer);
        }
        buyerInfo[buyer].totalAmountBought += unitAmount;
        if (totalAmountSold >= totalUnitAmount) {
            endTime = block.timestamp;
            emit AllUnitsSold(unitAmount, endTime);
        }
    }

    function _updateReferral(
        uint256 amount,
        string memory referralCode,
        address buyer
    ) internal {
        /* If the buyer has yet to buy any units using this referral code,
           add the code to the buyer referral list (which referral codes did they use) */
        if (buyerInfo[buyer].referrals[referralCode] == 0) {
            buyerInfo[buyer].referralsList.push(referralCode);
        }
        // Add bought unit amount corresponding to the referral used  during the purchase
        buyerInfo[buyer].referrals[referralCode] += amount;
        /* If the referral code (contract wise) was not used to buy items to this point,
           then add the referral code to the list of referrals in use*/
        if (referralCodes[referralCode] == 0) {
            referralCodeList.push(referralCode);
        }
        // Add to the total amount bought using referral code
        buyerInfo[buyer].referralAmountBought += amount;
        referralCodes[referralCode] += amount;
    }

    function withdrawCurrency(address recipient, uint256 amount)
        external
        onlyOwner
        amountNotZero(amount)
        addressNotZero(recipient)
    {
        require(
            address(this).balance >= amount,
            "Contract does not have enough currency"
        );
        payable(recipient).transfer(amount);
        emit CurrencyWithdrawn(recipient, msg.sender, amount);
    }

    function withdrawERC20Tokens(
        IERC20 tokenAddress,
        address recipient,
        uint256 amount
    )
        external
        onlyOwner
        amountNotZero(amount)
        addressNotZero(recipient)
        returns (bool)
    {
        require(
            tokenAddress.balanceOf(address(this)) >= amount,
            "Contract does not have enough ERC20 tokens"
        );
        tokenAddress.approve(address(this), amount);
        if (!tokenAddress.transferFrom(address(this), recipient, amount)) {
            return false;
        }
        emit ERC20Withdrawn(
            recipient,
            msg.sender,
            amount,
            address(tokenAddress)
        );
        return true;
    }

    function addToWhitelist(address _address) public onlyOwner {
        discountWhitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function addMultipleToWhitelist(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 addr = 0; addr < _addresses.length; addr++) {
            addToWhitelist(_addresses[addr]);
        }
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        discountWhitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return discountWhitelist[_address];
    }

    function setNewSaleTime(uint256 newStartTime, uint256 newEndTime)
        external
        onlyOwner
    {
        startTime = newStartTime;
        endTime = newEndTime;
    }

    function setCollectorWalletAddress(address newAddress) external onlyOwner {
        collectorWallet = newAddress;
    }

    function setTotalUnitAmount(uint256 newAmount) external onlyOwner {
        totalUnitAmount = newAmount;
    }

    function setHYFIexchangeRate(uint256 newExchangeRate)
        external
        onlyRole(HYFI_SETTER_ROLE)
        limitedExchangeRate(newExchangeRate)
    {
        HYFIexchangeRate = newExchangeRate;
    }

    function setUnitPrice(uint256 newPrice) external onlyOwner {
        unitPrice = newPrice;
    }

    function discountAmountCalculator(uint256 discount, uint256 value)
        public
        pure
        returns (uint256 discountAmount)
    {
        discountAmount = (value * discount) / 10000;
        return discountAmount;
    }

    function currencyPaymentCalculator(uint256 unitAmount, uint256 discount)
        public
        view
        returns (uint256 paymentAmount)
    {
        uint256 priceTotal = ((unitAmount * unitPrice * 10**8) *
            tokenInfo["ETH"].decimals) / uint256(getLatestETHPrice());
        priceTotal -= discountAmountCalculator(discount, priceTotal);
        return priceTotal;
    }

    function simpleTokenPaymentCalculator(
        string memory token,
        uint256 unitAmount,
        uint256 discount
    ) public view returns (uint256 paymentAmount) {
        uint256 priceTotal = (unitPrice * tokenInfo[token].decimals) *
            unitAmount;
        priceTotal -= discountAmountCalculator(discount, priceTotal);
        return priceTotal;
    }

    function mixedTokenPaymentCalculator(
        string memory token,
        uint256 unitAmount,
        uint256 discount
    )
        public
        view
        returns (uint256 stableCoinPaymentAmount, uint256 HYFIPaymentAmount)
    {
        uint256 baseTokenPayment = ((unitPrice * tokenInfo[token].decimals) *
            unitAmount *
            distrPercWithHYFI) / 100;
        baseTokenPayment -= discountAmountCalculator(
            discount,
            baseTokenPayment
        );
        uint256 HYFItokenPayment = ((((unitPrice * tokenInfo["HYFI"].decimals) *
            unitAmount *
            distrPercWithHYFI) / 100) / HYFIexchangeRate) * 10**18;
        HYFItokenPayment -= discountAmountCalculator(
            discount,
            HYFItokenPayment
        );
        return (baseTokenPayment, HYFItokenPayment);
    }

    function _discountPercentageCalculator(uint256 unitAmount, address buyer)
        internal
        view
        returns (uint256 discountPrecentage)
    {
        if (unitAmount <= 4) {
            discountPrecentage = 1000;
        } else if (unitAmount <= 50) {
            discountPrecentage = 1500;
        } else {
            discountPrecentage = 2000;
        }
        if (isWhitelisted(buyer)) {
            discountPrecentage += 500;
        }
        return discountPrecentage;
    }

    function getBuyerData(address addr)
        external
        view
        returns (
            uint256,
            uint256,
            string[] memory
        )
    {
        return (
            buyerInfo[addr].totalAmountBought,
            buyerInfo[addr].referralAmountBought,
            buyerInfo[addr].referralsList
        );
    }

    function getBuyerReferralData(address addr, string memory refferal)
        external
        view
        returns (uint256)
    {
        return (buyerInfo[addr].referrals[refferal]);
    }

    function getTokenData(string memory token)
        external
        view
        returns (TokenData memory)
    {
        return (tokenInfo[token]);
    }

    function getAmountBoughtWithReferral(string memory referralCode)
        external
        view
        returns (uint256)
    {
        return (referralCodes[referralCode]);
    }

    function getAllReferralCodeList()
        external
        view
        onlyOwner
        returns (string[] memory)
    {
        return (referralCodeList);
    }

    function getTotalAmountOfBuyers() external view returns (uint256) {
        return (_buyersAddressList.length);
    }

    function getBuyerFromListById(uint256 id) external view returns (address) {
        return (_buyersAddressList[id]);
    }

    function getAllBuyers() external view returns (address[] memory) {
        return (_buyersAddressList);
    }

    function getLatestETHPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }
}