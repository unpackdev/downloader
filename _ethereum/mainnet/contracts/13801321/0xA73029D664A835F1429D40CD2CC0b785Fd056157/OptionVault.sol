// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./IERC1155Receiver.sol";
import "./OptionLib.sol";
import "./PriceOracle.sol";
import "./IOptionVault.sol";
import "./IAMM.sol";

/**
 * @notice OptionVault contract is vaults for basic on-chain option contracts.
 * It manages option tokens.
 */
contract OptionVault is IOptionVault, ERC1155, IERC1155Receiver {
    using OptionLib for OptionLib.OptionInfo;

    /// @dev operator address
    address operator;

    /// @dev AMM address
    address ammAddress;

    /// @dev option info
    OptionLib.OptionInfo public optionInfo;

    /// @dev price oracle contract
    PriceOracle priceOracle;

    // events
    event ExpiryCreated(uint256 indexed expiryId, uint64 expiry);
    event SeriesCreated(uint256 indexed expiryId, uint256 seriesId, uint128 strike, bool isPut);

    event AccountCreated(uint256 accountId, address indexed account);
    event VaultDeposited(uint256 indexed accountId, uint256 expiryId, uint128 amount);
    event VaultWithdrawn(uint256 indexed accountId, uint256 expiryId, uint128 amount);
    event Written(uint256 indexed accountId, uint256 seriesId, uint128 amount, address recipient);
    event Unlocked(uint256 indexed accountId, uint256 seriesId, uint128 amount, address holder);
    event Claimed(uint256 indexed seriesId, uint128 amount, uint128 profit);
    event Settled(uint256 accountId, uint256 indexed seriesId, uint128 profit);
    event Hedged(uint32 tickId, int256 tickDelta, int256 hedgePosition);
    event Liquidated(uint256 accountId, uint256 seriesId);
    event ConfigUpdated(uint8 key, uint128 value);

    // modifiers
    modifier onlyVaultOwner(uint256 _accountId) {
        // if accountId is id of trader's vaults, check owner
        // if AMM vaults, check caller is AMM contract
        require(
            (msg.sender == optionInfo.getVaultOwner(_accountId) &&
                _accountId >= OptionLib.MIN_VAULT_ID &&
                _accountId < optionInfo.vaultCount) ||
                (msg.sender == ammAddress && _accountId < OptionLib.MIN_VAULT_ID),
            "V1"
        );
        _;
    }

    modifier onlyAMMVault(uint256 _accountId) {
        require(_accountId < OptionLib.MIN_VAULT_ID, "V2");
        _;
    }

    modifier notAMMVault(uint256 _accountId) {
        require(_accountId >= OptionLib.MIN_VAULT_ID, "V3");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "V4");
        _;
    }

    modifier onlyAMM() {
        require(msg.sender == ammAddress, "V5");
        _;
    }

    constructor(
        string memory _uri,
        address _aggregator,
        address _collateral,
        address _underlying,
        address _priceOracle,
        address _operator,
        address _lendingPool
    ) ERC1155(_uri) {
        optionInfo.aggregator = _aggregator;
        priceOracle = PriceOracle(_priceOracle);

        operator = _operator;

        optionInfo.init(_collateral, _underlying, _lendingPool);
    }

    function onERC1155Received(
        address _operator,
        address from,
        uint256 id,
        uint256 value,
        bytes memory data
    ) external override(IERC1155Receiver) returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address _operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) external override(IERC1155Receiver) returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function isApprovedForAll(address account, address _operator) public view virtual override returns (bool) {
        return super.isApprovedForAll(account, _operator) || _operator == address(this) || _operator == ammAddress;
    }

    /**
     * @notice set AMM address
     * @param _ammAddress amm address
     */
    function setAMMAddress(address _ammAddress) external {
        require(ammAddress == address(0));
        ammAddress = _ammAddress;
        setApprovalForAll(ammAddress, true);
    }

    /**
     * @notice set IV by AMM contract
     * @param _seriesId series id
     * @param _iv new implied volatility
     */
    function setIV(uint256 _seriesId, uint128 _iv) external override(IOptionVault) onlyAMM {
        optionInfo.setIV(_seriesId, _iv);
    }

    /**
     * @notice create new vault
     */
    function createAccount() public override(IOptionVault) returns (uint256) {
        uint256 accountId = optionInfo.createAccount(msg.sender);

        emit AccountCreated(accountId, msg.sender);

        return accountId;
    }

    /**
     * @notice deposit collateral to the vault
     * @param _accountId vault id
     * @param _collateral amount to deposit scaled by 1e6
     */
    function deposit(
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _collateral
    ) external override(IOptionVault) onlyVaultOwner(_accountId) {
        require(_collateral > 0, "V9");

        optionInfo.deposit(_accountId, _expiryId, _collateral);

        IERC20(optionInfo.tokens.collateral).transferFrom(msg.sender, address(this), _collateral);

        emit VaultDeposited(_accountId, _expiryId, _collateral);
    }

    /**
     * @notice withdraw collateral from the vault
     * @param _accountId vault id
     * @param _expiryId expiry id
     * @param _collateral amount to withdraw scaled by 1e6
     */
    function withdraw(
        uint256 _accountId,
        uint256 _expiryId,
        uint128 _collateral
    ) external override(IOptionVault) onlyVaultOwner(_accountId) {
        require(_collateral > 0, "V9");

        uint128 spot = getPrice();

        optionInfo.withdraw(_accountId, _expiryId, _collateral, spot);

        IERC20(optionInfo.tokens.collateral).transfer(msg.sender, _collateral);

        emit VaultWithdrawn(_accountId, _expiryId, _collateral);
    }

    /**
     * @notice close short position and withdraw unrequired collateral from the vault
     * @param _accountId account id
     * @param _seriesId series id to close
     * @param _amount the amount to close
     * @param _cRatio the final IM ratio(IM / collateral)
     */
    function closeShortPosition(
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _amount,
        uint128 _cRatio
    ) external override(IOptionVault) onlyVaultOwner(_accountId) returns (uint128) {
        require(0 < _cRatio && _cRatio <= 1e6, "V6");

        if (_amount > 0) {
            require(balanceOf(msg.sender, _seriesId) >= _amount, "V7");

            // unlock options
            optionInfo.unlock(_accountId, _seriesId, _amount);

            _burn(msg.sender, _seriesId, _amount);

            emit Unlocked(_accountId, _seriesId, _amount, msg.sender);
        }

        bool isPool = _accountId < OptionLib.MIN_VAULT_ID;

        uint256 expiryId = optionInfo.serieses[_seriesId].expiryId;
        uint128 unrequiredCollateral = optionInfo.withdrawUnrequiredCollateral(
            _accountId,
            expiryId,
            getPrice(),
            _cRatio,
            isPool
        );

        if (unrequiredCollateral > 0) {
            IERC20(optionInfo.tokens.collateral).transfer(msg.sender, unrequiredCollateral);

            emit VaultWithdrawn(_accountId, expiryId, unrequiredCollateral);
        }

        return unrequiredCollateral;
    }

    /**
     * @notice lock collateral and mint option tokens
     * @param _accountId vault id
     * @param _seriesId option series id
     * @param _amount amount to write scaled by 1e8
     * @param _recipient recipient of option tokens
     */
    function write(
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _amount,
        address _recipient
    ) external override(IOptionVault) onlyVaultOwner(_accountId) {
        require(_amount > 0, "V9");

        uint128 spot = getPrice();

        // write options
        optionInfo.write(_accountId, _seriesId, _amount, spot);

        _mint(_recipient, _seriesId, _amount, "");

        emit Written(_accountId, _seriesId, _amount, _recipient);
    }

    /**
     * @notice deposit collateral and write options in one transaction
     * @param _accountId vault id
     * @param _seriesId option series id
     * @param _cRatio _collateral ratio of Initial Margin
     * @param _amount amount to write scaled by 1e8
     * @param _recipient recipient of option tokens
     */
    function depositAndWrite(
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _cRatio,
        uint128 _amount,
        address _recipient
    ) public override(IOptionVault) onlyVaultOwner(_accountId) returns (uint128) {
        require(_amount > 0, "V9");
        require(0 < _cRatio && _cRatio <= 1e6, "V6");

        bool isPool = _accountId < OptionLib.MIN_VAULT_ID;

        // deposit collateral and write options
        (uint256 expiryId, uint128 collateral) = optionInfo.depositAndWrite(
            _accountId,
            _seriesId,
            _amount,
            _cRatio,
            getPrice(),
            isPool
        );

        IERC20(optionInfo.tokens.collateral).transferFrom(msg.sender, address(this), collateral);

        _mint(_recipient, _seriesId, _amount, "");

        emit VaultDeposited(_accountId, expiryId, collateral);
        emit Written(_accountId, _seriesId, _amount, _recipient);

        return collateral;
    }

    /**
     * @notice add long position to calculate net delta
     */
    function addLong(
        uint256 _accountId,
        uint256 _expiryId,
        uint256 _seriesId,
        uint128 _amount
    ) external override(IOptionVault) onlyVaultOwner(_accountId) {
        require(_amount > 0, "V9");

        uint128 longSize = optionInfo.addLong(_accountId, _expiryId, _seriesId, _amount);

        require(balanceOf(msg.sender, _seriesId) >= longSize, "V10");
    }

    /**
     * @notice remove long position to calculate net delta
     */
    function removeLong(
        uint256 _accountId,
        uint256 _expiryId,
        uint256 _seriesId,
        uint128 _amount
    ) external override(IOptionVault) onlyVaultOwner(_accountId) {
        require(_amount > 0, "V9");

        optionInfo.removeLong(_accountId, _expiryId, _seriesId, _amount);
    }

    /**
     * @notice swap collateral asset for underling asset to hedge vault's delta
     * @param _accountId the id of target vault
     * @param _underlyingAmount amount of underlying asset scaled by 1e8
     * @param _collateralAmount amount of collateral asset scaled by 1e6
     */
    function addUnderlyingLong(
        uint32 _accountId,
        uint256 _expiryId,
        uint256 _underlyingAmount,
        uint256 _collateralAmount
    ) external onlyAMMVault(_accountId) {
        uint128 spot = getPrice();

        // calculate vault's net delta
        int256 vaultDelta = optionInfo.calculateVaultDelta(_accountId, _expiryId, spot);

        // swap collateral asset for underling asset
        int256 hedgePosition = optionInfo.addUnderlyingLong(
            _accountId,
            _expiryId,
            spot,
            vaultDelta,
            _underlyingAmount,
            _collateralAmount
        );

        emit Hedged(_accountId, vaultDelta, hedgePosition);
    }

    /**
     * @notice swap underling asset for collateral asset to hedge vaults' delta
     * @param _accountId the id of target vault
     * @param _underlyingAmount amount of underlying asset scaled by 1e8
     * @param _collateralAmount amount of collateral asset scaled by 1e6
     */
    function addUnderlyingShort(
        uint32 _accountId,
        uint256 _expiryId,
        uint256 _underlyingAmount,
        uint256 _collateralAmount
    ) external onlyAMMVault(_accountId) {
        uint128 spot = getPrice();

        // calculate vault's net delta
        int256 vaultDelta = optionInfo.calculateVaultDelta(_accountId, _expiryId, spot);

        // swap underling asset for collateral asset
        int256 hedgePosition = optionInfo.addUnderlyingShort(
            _accountId,
            _expiryId,
            spot,
            vaultDelta,
            _underlyingAmount,
            _collateralAmount
        );

        emit Hedged(_accountId, vaultDelta, hedgePosition);
    }

    /**
     * @notice repay all underlying asset and withdraw collateral from AAVE
     * @param _repayAmount amount to repay
     */
    function redeemCollateralFromLendingPool(uint128 _repayAmount) external onlyOperator {
        optionInfo.redeemCollateralFromLendingPool(
            _repayAmount,
            getPrice(),
            msg.sender,
            address(IAMM(ammAddress).feePool())
        );
    }

    /**
     * @notice burn options and get collateral from a vault that requires liquidation
     * to save the profit of option holders.
     * @param _accountId vault id
     * @param _seriesId option series id
     * @param _amount amount to liquidate scaled by 1e8
     */
    function liquidate(
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _amount
    ) external notAMMVault(_accountId) {
        require(_amount > 0, "V9");

        require(balanceOf(msg.sender, _seriesId) >= _amount, "V7");

        uint128 price = getPrice();

        uint128 reward = optionInfo.liquidate(_accountId, _seriesId, _amount, price);

        IERC20(optionInfo.tokens.collateral).transfer(msg.sender, reward);

        _burn(msg.sender, _seriesId, _amount);

        emit Liquidated(_accountId, _seriesId);
    }

    /**
     * @notice claim profit of some amount of expired option contracts.
     * @param _seriesId option series id
     * @param _size option size to claim profit scaled by 1e8
     */
    function claim(uint256 _seriesId, uint128 _size) external override(IOptionVault) returns (uint128) {
        IOptionVault.OptionSeries storage series = optionInfo.serieses[_seriesId];

        require(balanceOf(msg.sender, _seriesId) >= _size, "V7");

        uint256 price = getExpiryPrice(series.expiryId);

        uint128 payout = optionInfo.claimProfit(_seriesId, _size, uint128(price));

        // burn options
        _burn(msg.sender, _seriesId, _size);

        // send payout to option holder
        IERC20(optionInfo.tokens.collateral).transfer(msg.sender, payout);

        emit Claimed(_seriesId, _size, payout);

        return payout;
    }

    /**
     * @notice settle a vault
     * fix the payout of an expired vault and send collateral in the vault to vault's owner
     * @param _accountId vault id
     * @param _expiryId option series id
     */
    function settleVault(uint256 _accountId, uint256 _expiryId) external override(IOptionVault) returns (uint128) {
        // anyone can settle trader's vault, but only AMM contract can settle AMM's vault
        require(
            (_accountId >= OptionLib.MIN_VAULT_ID && _accountId < optionInfo.vaultCount) ||
                (msg.sender == ammAddress && _accountId < OptionLib.MIN_VAULT_ID),
            "V8"
        );

        uint256 price = getExpiryPrice(_expiryId);

        uint128 settledAmount = optionInfo.settle(_accountId, _expiryId, uint128(price));

        if (settledAmount > 0) {
            // send all vault's collateral to owner
            if (_accountId < OptionLib.MIN_VAULT_ID) {
                IERC20(optionInfo.tokens.collateral).transfer(ammAddress, settledAmount);
            } else {
                IERC20(optionInfo.tokens.collateral).transfer(optionInfo.getVaultOwner(_accountId), settledAmount);
            }
        }

        emit Settled(_accountId, _expiryId, settledAmount);

        return settledAmount;
    }

    ////////////////////////
    // Wrapper Functions //
    ////////////////////////

    function makeShortPosition(
        uint256 _accountId,
        uint256 _seriesId,
        uint128 _cRatio,
        uint128 _amount,
        uint128 _minFee
    ) external {
        uint256 accountId = _accountId;

        if (accountId == 0) {
            accountId = createAccount();
        }

        depositAndWrite(accountId, _seriesId, _cRatio, _amount, address(this));

        uint128 premium = IAMM(ammAddress).sell(_seriesId, _amount, _minFee);

        IERC20(optionInfo.tokens.collateral).transfer(msg.sender, premium);
    }

    ////////////////////////
    // Operator Functions //
    ////////////////////////

    /**
     * @notice create new expiration
     * @param _expiry expiration
     * @param _strikes strike prices
     * @param _callIVs initial call ivs
     * @param _putIVs initial put ivs
     */
    function createExpiry(
        uint64 _expiry,
        uint64[] memory _strikes,
        uint64[] memory _callIVs,
        uint64[] memory _putIVs
    ) external onlyOperator {
        uint128 expiryId = optionInfo.createExpiry(_expiry);

        for (uint256 i = 0; i < _strikes.length; i++) {
            createSeries(expiryId, _strikes[i], false, _callIVs[i]);
            createSeries(expiryId, _strikes[i], true, _putIVs[i]);
        }

        emit ExpiryCreated(expiryId, _expiry);
    }

    /**
     * @notice update a config value
     */
    function setConfig(uint8 _key, uint128 _value) external onlyOperator {
        require(_value > 0);
        optionInfo.setConfig(_key, _value);

        // emit event
        emit ConfigUpdated(_key, _value);
    }

    /**
     * @notice set new operator
     * @param _operator operator address
     */
    function setNewOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    /**
     * @notice get an expiration
     */
    function getExpiration(uint256 _expiryId)
        external
        view
        override(IOptionVault)
        returns (IOptionVault.Expiration memory)
    {
        return optionInfo.expiries[_expiryId];
    }

    /**
     * @notice get an option series
     */
    function getOptionSeries(uint256 _seriesId)
        external
        view
        override(IOptionVault)
        returns (IOptionVault.OptionSeriesView memory)
    {
        return optionInfo.getOptionSeriesView(_seriesId);
    }

    /**
     * @notice get list of live option serieses
     */
    function getLiveOptionSerieses() external view override(IOptionVault) returns (IOptionVault.Expiration[] memory) {
        return optionInfo.getLiveOptionSerieses();
    }

    /**
     * @notice get timestamp of the last expiry
     */
    function getLastExpiry() external view override(IOptionVault) returns (uint64) {
        return optionInfo.expiries[optionInfo.expiryCount - 1].expiry;
    }

    /**
     * @notice get total collateral value of a vault
     * @param _accountId vault id
     */
    function getCollateralValueQuote(uint256 _accountId) external view override(IOptionVault) returns (uint128) {
        return optionInfo.getCollateralValueQuote(_accountId, getPrice());
    }

    /**
     * @notice get required margin of a vault
     * there are 3 margin levels
     * 1. Maintenance Margin: vaults can be liquidated if the collateral is lower than MM
     * 2. Initial Margin: collateral must be greater than IM to write options
     * 3. Safe Margin: enough margin for delta hedging
     * @param _accountId vault id
     * @param _expiryId expiry id
     * @param _marginLevel margin level
     */
    function getRequiredMargin(
        uint256 _accountId,
        uint256 _expiryId,
        IOptionVault.MarginLevel _marginLevel
    ) external view override(IOptionVault) returns (uint128) {
        uint128 price = getPrice();

        return optionInfo.getRequiredMargin(_accountId, _expiryId, price, _marginLevel);
    }

    /**
     * @notice calculate required margin for a series
     * @param _seriesId series id
     * @param _amount amount of options. plus for short and minus for long
     * @param _marginLevel margin level
     */
    function calRequiredMarginForASeries(
        uint256 _seriesId,
        int128 _amount,
        IOptionVault.MarginLevel _marginLevel
    ) external view override(IOptionVault) returns (uint128) {
        IOptionVault.OptionSeries memory series = optionInfo.serieses[_seriesId];

        return optionInfo.getRequiredMarginForASeries(series.expiryId, _seriesId, getPrice(), _amount, _marginLevel);
    }

    /**
     * @notice get total payout of a vault
     * @param _accountId vault id
     * @param _expiryId expiry id
     */
    function getTotalPayout(uint256 _accountId, uint256 _expiryId)
        external
        view
        override(IOptionVault)
        returns (uint128)
    {
        return optionInfo.getTotalPayout(_accountId, _expiryId, getPrice(), false);
    }

    /**
     * @notice get liquidatable amount of a vault
     * @param _accountId vault id
     * @param _seriesId series id
     */
    function getLiquidatableAmount(uint256 _accountId, uint256 _seriesId) external view returns (uint128 limit) {
        return optionInfo.getLiquidatableAmount(_accountId, _seriesId, getPrice());
    }

    function getAccount(uint256 _accountId) external view override(IOptionVault) returns (AccountView memory) {
        Account storage account = optionInfo.accounts[_accountId];
        return AccountView(account.owner, account.settledCount);
    }

    function getVault(uint256 _accountId, uint256 _expiryId)
        external
        view
        override(IOptionVault)
        returns (VaultView memory)
    {
        Vault storage vault = optionInfo.accounts[_accountId].vaults[_expiryId];
        return
            VaultView(
                optionInfo.accounts[_accountId].owner,
                vault.isSettled,
                vault.collateral,
                vault.hedgePosition,
                vault.shortLiquidity
            );
    }

    /**
     * @notice get position size
     * @param _accountId vault id
     * @param _seriesId option series id
     * @return (short size, long size)
     */
    function getPositionSize(uint256 _accountId, uint256 _seriesId)
        external
        view
        override(IOptionVault)
        returns (uint128, uint128)
    {
        return optionInfo.getPositionSize(_accountId, _seriesId);
    }

    /**
     * @notice get vault's net delta
     * @param _accountId vault id
     */
    function calculateVaultDelta(uint256 _accountId, uint256 _expiryId)
        external
        view
        override(IOptionVault)
        returns (int256)
    {
        return optionInfo.calculateVaultDelta(_accountId, _expiryId, getPrice());
    }

    /**
     * @notice get a config value
     */
    function getConfig(uint8 _key) external view returns (uint128) {
        return optionInfo.configs[_key];
    }

    ///////////////////////
    // Private Functions //
    ///////////////////////

    function createSeries(
        uint128 _expiryId,
        uint64 _strike,
        bool _isPut,
        uint64 _iv
    ) internal {
        uint256 seriesId = optionInfo.createSeries(_expiryId, _strike, _isPut, _iv);
        emit SeriesCreated(_expiryId, seriesId, _strike, _isPut);
    }

    function getExpiryPrice(uint256 _expiryId) internal view returns (uint256) {
        IOptionVault.Expiration storage expiration = optionInfo.expiries[_expiryId];

        (uint256 price, bool isFinalized) = priceOracle.getExpiryPrice(optionInfo.aggregator, expiration.expiry);

        require(isFinalized, "V11");

        return price;
    }

    function getPrice() internal view returns (uint128) {
        (uint256 spot, ) = priceOracle.getPrice(optionInfo.aggregator);
        return uint128(spot);
    }
}
