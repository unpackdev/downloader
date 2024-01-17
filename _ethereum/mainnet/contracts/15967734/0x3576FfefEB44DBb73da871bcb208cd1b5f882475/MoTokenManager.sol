// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StableCoin.sol";
import "./MoToken.sol";
import "./RWADetails.sol";
import "./AccessControlManager.sol";

/// @title Token manager for open/senior token
/// @notice This is a token manager which handles all operations related to the token

contract MoTokenManager {
    /// @dev All assets are stored with 4 decimal shift
    uint8 public constant MO_DECIMALS = 4;

    /// @dev RWA Details contract address which stores real world asset details
    address public rWADetails;

    /// @dev Limits the total supply of the token.
    uint256 public tokenSupplyLimit;

    /// @dev Token Supply in the NAV approval flow
    uint256 public tokenSupplyUnapproved;

    /// @dev Implements RWA manager and whitelist access
    address public accessControlManagerAddress;

    /// @dev Address of the associated MoToken
    address public token;

    /// @dev Holds exponential value for MO token decimals
    uint256 public tokenDecimals;

    /// @dev OraclePriceExchange Address contract associated with the stable coin
    address public currencyOracleAddress;

    /// @dev fiatCurrency associated with tokens
    bytes32 public fiatCurrency = "USD";

    /// @dev platform fee currency associated with tokens
    bytes32 public platformFeeCurrency = "USDC";

    /// @dev Accrued fee amount charged by the platform
    uint256 public accruedPlatformFee;

    /// @dev stableCoin Address contract used for stable coin operations
    address public stableCoinAddress;

    /// @dev Holds the corresponding senior RWA Unit ID of the junior token
    uint256 public linkedSrRwaUnitId;

    /** @notice This struct stores all the properties associated with the token
     *  id - MoToken id
     *  navDeviationAllowance - Percentage of NAV change allowed without approval flow
     *  daysInAYear - Number of days in a year, used to calculate fee
     *  platformFee - Platform fee in basis points
     *  navUpdateTimestamp - Timestamp when NAV was last updated
     *  navApprovalRequestTimestamp - Timestamp of last instance when NAV went to approval flow
     *  nav - NAV of the token
     *  navUnapproved - NAV unapproved value stored for approval flow
     *  pipeFiatStash - Fiat amount which is in transmission between the stable coin pipe and the RWA bank account
     *  fiatInTransit - Fiat amount in transit to stash
     */

    struct TokenDetails {
        uint16 id;
        uint16 navDeviationAllowance; // in percent
        uint16 daysInAYear;
        uint32 platformFee; // in basis points
        uint32 navUpdateTimestamp; // timestamp
        uint32 navApprovalRequestTimestamp;
        uint64 nav; // 4 decimal shifted
        uint64 navUnapproved;
        uint64 pipeFiatStash; // 4 decimal shifted
        uint64 fiatInTransit;
    }

    TokenDetails public tokenData;

    event Purchase(address indexed user, uint256 indexed tokens);
    event RWADetailsSet(address indexed rwaAddress);
    event FiatCurrencySet(bytes32 indexed currency);
    event FiatCredited(uint64 indexed amount, uint32 indexed date);
    event FiatDebited(uint64 indexed amount, uint32 indexed date);
    event NAVUpdated(uint64 indexed nav, uint32 indexed date);
    event TokenSupplyLimitSet(uint256 indexed tokenSupplyLimit);
    event NAVApprovalRequest(
        uint64 indexed navUnapproved,
        uint32 indexed stashUpdateDate
    );
    event PlatformFeeSet(uint32 indexed platformFee);
    event PlatformFeeCurrencySet(bytes32 indexed currency);
    event FeeTransferred(uint256 indexed fee);
    event AccessControlManagerSet(address indexed accessControlAddress);
    event CurrencyOracleAddressSet(address indexed currencyOracleAddress);
    event StableCoinAddressSet(address indexed stableCoinAddress);
    event dividend(address account, uint256 dividendAmount, uint256 moBal);

    /// @notice Constructor instantiates access control

    constructor(address _accessControlManager) {
        accessControlManagerAddress = _accessControlManager;
        emit AccessControlManagerSet(_accessControlManager);
    }

    /// @notice Access modifier to restrict access only to owner

    modifier onlyOwner() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isOwner(msg.sender), "NO");
        _;
    }

    /// @notice Access modifier to restrict access only to RWA manager addresses

    modifier onlyRWAManager() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isRWAManager(msg.sender), "NR");
        _;
    }

    /// @notice Access modifier to restrict access only to Admin addresses

    modifier onlyAdmin() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isAdmin(msg.sender), "NA");
        _;
    }

    /// @notice Access modifier to restrict access only to Cron Admin addresses

    modifier onlyCronManager() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isCronManager(msg.sender), "NC");
        _;
    }

    /// @notice returns the owner address

    function owner() public view returns (address) {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        return acm.owner();
    }

    /// @notice Initializes basic properties associated with the token
    /// @param _id MoToken Id
    /// @param _token token address
    /// @param _stableCoin StableCoin contract address
    /// @param _initNAV Initial NAV value
    /// @param _rWADetails RWADetails contract address

    function initialize(
        uint16 _id,
        address _token,
        address _stableCoin,
        uint64 _initNAV,
        address _rWADetails
    ) external {
        require(tokenData.id == 0, "AE");

        tokenData.id = _id;
        token = _token;
        tokenDecimals = 10**MO_DECIMALS;
        stableCoinAddress = _stableCoin;
        rWADetails = _rWADetails;
        tokenData.nav = _initNAV;
        tokenData.navDeviationAllowance = 10;
        tokenData.daysInAYear = 365;
        tokenData.navUpdateTimestamp =
            uint32(block.timestamp) -
            (uint32(block.timestamp) % 1 days);
    }

    /// @notice Setter for accessControlManagerAddress
    /// @param _accessControlManagerAddress Set accessControlManagerAddress to this address

    function setAccessControlManagerAddress(
        address _accessControlManagerAddress
    ) external onlyOwner {
        accessControlManagerAddress = _accessControlManagerAddress;
        emit AccessControlManagerSet(_accessControlManagerAddress);
    }

    /// @notice Setter for stableCoin
    /// @param _stableCoinAddress Set stableCoin to this address

    function setStableCoinAddress(address _stableCoinAddress)
        external
        onlyOwner
    {
        stableCoinAddress = _stableCoinAddress;
        emit StableCoinAddressSet(stableCoinAddress);
    }

    /// @notice Setter for RWADetails contract associated with the MoToken
    /// @param _rWADetails Address of contract storing RWADetails

    function setRWADetailsAddress(address _rWADetails) external onlyOwner {
        rWADetails = _rWADetails;
        emit RWADetailsSet(rWADetails);
    }

    /// @notice Allows setting currencyOracleAddress
    /// @param _currencyOracleAddress address of the currency oracle

    function setCurrencyOracleAddress(address _currencyOracleAddress)
        external
        onlyOwner
    {
        currencyOracleAddress = _currencyOracleAddress;
        emit CurrencyOracleAddressSet(currencyOracleAddress);
    }

    /// @notice Allows setting fiatCurrecy associated with tokens
    /// @param _fiatCurrency fiatCurrency

    function setFiatCurrency(bytes32 _fiatCurrency) external onlyOwner {
        fiatCurrency = _fiatCurrency;
        emit FiatCurrencySet(fiatCurrency);
    }

    /// @notice Setter for platform fee currency
    /// @param _feeCurrency platform fee currency

    function setPlatformFeeCurrency(bytes32 _feeCurrency)
        external
        onlyRWAManager
    {
        platformFeeCurrency = _feeCurrency;
        emit PlatformFeeCurrencySet(platformFeeCurrency);
    }

    /// @notice Setter for platform fee
    /// @param _fee platform fee

    function setFee(uint32 _fee) external onlyOwner {
        require(_fee < 10000, "NA");
        tokenData.platformFee = _fee;
        emit PlatformFeeSet(_fee);
    }

    /// @notice Allows setting tokenSupplyLimit associated with tokens
    /// @param _tokenSupplyLimit limit to be set for the token supply

    function setTokenSupplyLimit(uint256 _tokenSupplyLimit)
        external
        onlyRWAManager
    {
        tokenSupplyLimit = _tokenSupplyLimit;
        emit TokenSupplyLimitSet(tokenSupplyLimit);
    }

    /// @notice Allows setting NAV deviation allowance by Owner
    /// @param _value Allowed deviation limit (Eg: 10 for 10% deviation)

    function setNavDeviationAllowance(uint16 _value) external onlyOwner {
        require(_value < 100, "IN");
        tokenData.navDeviationAllowance = _value;
    }

    /// @notice Raise request for platform fee transfer to governor
    /// @param amount fee transfer amount in fiat currency

    function sweepFeeToGov(uint256 amount) external onlyAdmin {
        accruedPlatformFee -= amount;
        require(transferFeeToGovernor(amount), "TF");
        emit FeeTransferred(amount);
    }

    /// @notice Calculates the incremental platform fee the given timestamp and
    /// and updates the total accrued fee.
    /// @param _timestamp timestamp for fee accrual
    /// @param _totalAssetValue Total asset value of the token

    function accrueFee(uint32 _timestamp, uint256 _totalAssetValue) internal {
        uint256 calculatedFee = ((_timestamp - tokenData.navUpdateTimestamp) *
            tokenData.platformFee *
            _totalAssetValue) /
            10**MO_DECIMALS /
            tokenData.daysInAYear /
            1 days;
        accruedPlatformFee += calculatedFee;
    }

    /// @notice Returns the token id for the associated token.

    function getId() public view returns (uint16) {
        return tokenData.id;
    }

    /// @notice Sets days in a year to be used in fee calculation.

    function setDaysInAYear(uint16 _days) external onlyRWAManager {
        require(_days == 365 || _days == 366, "INV");
        tokenData.daysInAYear = _days;
    }

    /// @notice This function is called by the purchaser of MoH tokens. The protocol transfers _depositCurrency
    /// from the purchaser and mints and transfers MoH token to the purchaser
    /// @dev tokenData.nav has the NAV (in USD) of the MoH token. The number of MoH tokens to mint = _depositAmount (in USD) / NAV
    /// @param _stableCoinAmount is the amount in stable coin (decimal shifted) that the purchaser wants to pay to buy MoH tokens
    /// @param _depositCurrency is the token that purchaser wants to pay with (eg: USDC, USDT etc)

    function purchase(uint256 _stableCoinAmount, bytes32 _depositCurrency)
        external
    {
        uint256 tokensToMint = stableCoinToTokens(
            _stableCoinAmount,
            _depositCurrency
        );

        MoToken moToken = MoToken(token);
        require(
            tokenSupplyLimit + moToken.balanceOf(token) >=
                moToken.totalSupply() + tokensToMint,
            "LE"
        );

        StableCoin sCoin = StableCoin(stableCoinAddress);
        require(
            sCoin.initiateTransferFrom({
                _token: token,
                _from: msg.sender,
                _stableCoinAmount: _stableCoinAmount,
                _symbol: _depositCurrency
            }),
            "PF"
        );

        moToken.mint(msg.sender, tokensToMint);

        emit Purchase(msg.sender, tokensToMint);
    }

    /// @notice Converts stable coin amount to token amount
    /// @param _stableCoinAmount Stable coin amount
    /// @param _stableCoin Stable coin symbol
    /// @return tokens Calculated token amount

    function stableCoinToTokens(uint256 _stableCoinAmount, bytes32 _stableCoin)
        public
        view
        returns (uint256 tokens)
    {
        CurrencyOracle currencyOracle = CurrencyOracle(currencyOracleAddress);
        (uint64 stableToFiatConvRate, uint8 decimalsVal) = currencyOracle
            .getFeedLatestPriceAndDecimals(_stableCoin, fiatCurrency);

        StableCoin sCoin = StableCoin(stableCoinAddress);

        int8 decimalCorrection = int8(MO_DECIMALS) +
            int8(MO_DECIMALS) -
            int8(sCoin.decimals(_stableCoin)) -
            int8(decimalsVal);

        tokens = _stableCoinAmount * stableToFiatConvRate;
        if (decimalCorrection > -1) {
            tokens = tokens * 10**uint8(decimalCorrection);
        } else {
            decimalCorrection = -decimalCorrection;
            tokens = tokens / 10**uint8(decimalCorrection);
        }
        tokens = tokens / tokenData.nav;
    }

    /// @notice The function allows RWA manger to provide the increase in pipe fiat balances against the MoH token
    /// @param _fiatAmount the amount by which RWA manager is increasing the pipeFiatStash of the MoH token
    /// @param _date RWA manager is crediting pipe fiat for this date

    function creditPipeFiat(uint64 _fiatAmount, uint32 _date)
        external
        onlyCronManager
    {
        tokenData.pipeFiatStash += _fiatAmount;
        emit FiatCredited(tokenData.pipeFiatStash, _date);
    }

    /// @notice The function allows RWA manger to decrease pipe fiat balances against the MoH token
    /// @param _fiatAmount the amount by which RWA manager is decreasing the pipeFiatStash of the MoH token
    /// @param _date RWA manager is debiting pipe fiat for this date

    function debitPipeFiat(uint64 _fiatAmount, uint32 _date)
        external
        onlyCronManager
    {
        tokenData.pipeFiatStash -= _fiatAmount;
        emit FiatDebited(tokenData.pipeFiatStash, _date);
    }

    /// @notice Provides the NAV of the MoH token
    /// @return tokenData.nav NAV of the MoH token

    function getNAV() public view returns (uint64) {
        return tokenData.nav;
    }

    /// @notice The function allows the RWA manager to update the NAV. NAV = (Asset value of AFI _ pipe fiat stash in Fiat +
    /// stablecoin balance) / Total supply of the MoH token.
    /// @dev getTotalAssetValue gets value of all RWA units held by this MoH token plus stablecoin balances
    /// held by this MoH token. tokenData.pipeFiatStash gets the Fiat balances against this MoH token
    /// @param _timestamp Timestamp for which NAV is calculated

    function updateNav(uint32 _timestamp) external onlyCronManager {
        require(
            _timestamp >= tokenData.navUpdateTimestamp &&
                (uint32(block.timestamp) > _timestamp),
            "IT"
        );
        uint256 totalSupply = MoToken(token).totalSupply();
        require(totalSupply > 0, "ECT1");
        uint256 totalValue = uint128(getTotalAssetValue()); // 4 decimals shifted

        uint32 navCalculated = uint32(
            (totalValue * tokenDecimals) / totalSupply
        ); //nav should be 4 decimals shifted

        if (
            navCalculated >
            ((tokenData.nav * (100 + tokenData.navDeviationAllowance)) / 100) ||
            navCalculated <
            ((tokenData.nav * (100 - tokenData.navDeviationAllowance)) / 100)
        ) {
            tokenData.navUnapproved = navCalculated;
            tokenData.navApprovalRequestTimestamp = _timestamp;
            tokenSupplyUnapproved = totalSupply;
            emit NAVApprovalRequest(tokenData.navUnapproved, _timestamp);
        } else {
            tokenData.nav = navCalculated;
            tokenData.navUnapproved = 0;
            accrueFee(_timestamp, totalValue);
            tokenData.navUpdateTimestamp = _timestamp;
            emit NAVUpdated(tokenData.nav, _timestamp);
        }
    }

    /// @notice If the change in NAV is more than navDeviationAllowance, it has to be approved by Admin

    function approveNav() external onlyRWAManager {
        require(tokenData.navUnapproved > 0, "NA");

        tokenData.nav = tokenData.navUnapproved;
        tokenData.navUnapproved = 0;
        accrueFee(
            tokenData.navApprovalRequestTimestamp,
            (tokenData.nav * tokenSupplyUnapproved) / tokenDecimals
        );
        tokenData.navUpdateTimestamp = tokenData.navApprovalRequestTimestamp;
        emit NAVUpdated(tokenData.nav, tokenData.navUpdateTimestamp);
    }

    /// @notice Gets the summation of all the assets owned by the RWA fund that is associated with the MoToken in fiatCurrency
    /// @return totalRWAssetValue Value of all the assets associated with the MoToken

    function getTotalAssetValue()
        internal
        view
        returns (uint256 totalRWAssetValue)
    {
        RWADetails rWADetailsInstance = RWADetails(rWADetails);
        StableCoin sCoin = StableCoin(stableCoinAddress);

        totalRWAssetValue =
            rWADetailsInstance.getRWAValueByTokenId(
                tokenData.id,
                fiatCurrency
            ) +
            sCoin.totalBalanceInFiat(token, fiatCurrency) +
            tokenData.pipeFiatStash +
            tokenData.fiatInTransit -
            accruedPlatformFee; // 4 decimals shifted
    }

    /// @notice Transfers accrued fees to governor
    /// @param _fiatAmount amount in FiatCurrency
    /// @return bool Boolean indicating transfer success/failure

    function transferFeeToGovernor(uint256 _fiatAmount)
        internal
        returns (bool)
    {
        CurrencyOracle currencyOracle = CurrencyOracle(currencyOracleAddress);
        (uint64 stableToFiatConvRate, uint8 decimalsVal) = currencyOracle
            .getFeedLatestPriceAndDecimals(platformFeeCurrency, fiatCurrency);

        StableCoin sCoin = StableCoin(stableCoinAddress);
        uint8 finalDecVal = decimalsVal +
            sCoin.decimals(platformFeeCurrency) -
            MO_DECIMALS;
        uint256 amount = ((_fiatAmount * (10**finalDecVal)) /
            stableToFiatConvRate);

        MoToken moToken = MoToken(token);
        return (
            moToken.transferStableCoins(
                sCoin.contractAddressOf(platformFeeCurrency),
                owner(),
                amount
            )
        );
    }

    /// @notice Sets the RWA unit ID corresponding to the junior RWA Unit ID
    /// @param _unitId Senior RWA Unit ID

    function setLinkedSrRwaUnitId(uint256 _unitId) external onlyRWAManager {
        linkedSrRwaUnitId = _unitId;
    }

    /// @notice Sets fiat in transit amount
    /// @param _fiatAmount fiat amount (4 decimal shifted)

    function updateFiatInTransit(uint64 _fiatAmount) external onlyCronManager {
        tokenData.fiatInTransit = _fiatAmount;
    }

    /// @notice pays dividend to all the Mo Token holders, amount is total dividend amount for the current total token supply
    /// @param _stableCoinAmount stable coin amount (stable coin decimal shifted)

    function payoutDividend(uint256 _stableCoinAmount) external onlyRWAManager {
        StableCoin sCoin = StableCoin(stableCoinAddress);
        require(
            (sCoin.balanceOf(platformFeeCurrency, token)) >= _stableCoinAmount
        );

        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );

        MoToken moToken = MoToken(token);

        uint256 dividendAmount = (_stableCoinAmount * (10**8)) /
            moToken.totalSupply();

        for (
            uint256 i = 0;
            i < acm.getRoleMemberCount(acm.WHITELIST_ROLE());
            ++i
        ) {
            address account = acm.getRoleMember(acm.WHITELIST_ROLE(), i);
            uint256 moBalance = moToken.balanceOf(account);
            if (moBalance > 0) {
                uint256 dividendToPay = (moBalance * dividendAmount) / (10**8);
                if (dividendToPay > 0) {
                    require(
                        moToken.transferStableCoins(
                            sCoin.contractAddressOf(platformFeeCurrency),
                            account,
                            dividendToPay
                        )
                    );
                    emit dividend(account, dividendToPay, moBalance);
                }
            }
        }
    }
}
