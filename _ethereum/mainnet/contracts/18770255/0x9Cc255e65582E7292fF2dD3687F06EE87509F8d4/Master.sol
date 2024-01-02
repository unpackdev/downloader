// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./LogExpMath.sol";
import "./DSMath.sol";
import "./SignedSafeMath.sol";
import "./IAsset.sol";
import "./IMaster.sol";
import "./IWhitelist.sol";

/**
 * @title Master MERCH
 * @notice He is the merchant boss and manages buys, sells and redeems. Holds a mapping of assets and parameters.
 * @dev The main entry-point of MERCH project
 * Note: All variables and calculations are made in 18 decimals, except from that of WETH tokens and MERCH
 */
contract Master is Initializable, IMaster, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using DSMath for uint256;
    using SignedSafeMath for int256;
    using SafeERC20 for IERC20;

    /// @notice Asset Map struct holds assets
    struct AssetMap {
        address[] keys;
        mapping(address => IAsset) values;
        mapping(address => uint256) indexOf;
    }

    /* Storage */

    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant magicNum1 = 1733869670889880000;
    uint256 internal constant magicNum2 = 12400000000000000;
    uint256 internal constant magicNum3 = 47366163495485700;

    uint256 public haircutRate;
    address public feeTo;
    address public merchantFeeTo;
    uint256 public whitelistEndTime;

    /// @notice Dividend collected by each asset (unit: WAD)
    mapping(IAsset => uint256) internal _feeCollected;

    /// @notice A record of assets inside Master
    AssetMap internal _assets;

    /// @notice whitelist wallet checker
    /// @dev only whitelisted addresses can mint, until block.timestamp > whitelistEndTime
    IWhitelist public whitelist;

    /* Events */

    /// @notice An event thats emitted when an token is added to Master
    event AssetAdded(address indexed token);

    /// @notice An event thats emitted when token is removed from Master
    event AssetRemoved(address indexed token);

    /// @notice An event thats emitted when a buy is made from Master
    event Buy(address indexed sender, address token, uint256 tokenAmount, uint256 amount, address indexed to);

    /// @notice An event thats emitted when a sell is made from Master
    event Sell(address indexed sender, address token, uint256 tokenAmount, uint256 amount, address indexed to);

    /// @notice An event thats emitted when a redeem is made from Master
    event Redeem(address indexed sender, address token, uint256 tokenAmount, uint256 baseAmount, address indexed to);

    event SetFeeTo(address addr);
    event SetMerchantFeeTo(address addr);
    event SetHaircutRate(uint256 value);
    event SetWhiteList(address addr);
    event SetWhiteListEndTime(uint256 value);

    /* Errors */
    error MERCH_EXPIRED();
    error MERCH_ASSET_NOT_EXISTS();
    error MERCH_ASSET_ALREADY_EXIST();
    error MERCH_WHITELIST_NOT_ENDED();

    error MERCH_ZERO_ADDRESS();
    error MERCH_INVALID_VALUE();
    error MERCH_SAME_ADDRESS();
    error MERCH_AMOUNT_TOO_LOW();

    /* Pesudo modifiers to safe gas */

    function _checkAddress(address to) internal pure {
        if (to == address(0)) revert MERCH_ZERO_ADDRESS();
    }

    function _checkSameAddress(address from, address to) internal pure {
        if (from == to) revert MERCH_SAME_ADDRESS();
    }

    function _checkAmount(uint256 minAmt, uint256 amt) internal pure {
        if (minAmt > amt) revert MERCH_AMOUNT_TOO_LOW();
    }

    function _ensure(uint256 deadline) internal view {
        if (deadline < block.timestamp) revert MERCH_EXPIRED();
    }

    /* Construtor and setters */

    /**
     * @notice Initializes Master. Dev is set to be the account calling this function.
     */
    function initialize(uint256 haircutRate_, uint256 whitelistEndTime_) public virtual initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        haircutRate = haircutRate_;
        whitelistEndTime = whitelistEndTime_;
    }

    // Setters //

    /**
     * @notice Changes the Masters haircutRate. Can only be set by the contract owner.
     * @param haircutRate_ new Master's haircutRate_
     */
    function setHaircutRate(uint256 haircutRate_) external onlyOwner {
        if (haircutRate_ > WAD) revert MERCH_INVALID_VALUE(); // haircutRate_ should not be set bigger than 1
        haircutRate = haircutRate_;
        emit SetHaircutRate(haircutRate_);
    }

    /**
     * @notice Changes the fee beneficiary. Can only be set by the contract owner.
     * This value cannot be set to 0 to avoid unsettled fee.
     * @param feeTo_ new fee beneficiary
     */
    function setFeeTo(address feeTo_) external onlyOwner {
        _checkAddress(feeTo_);
        feeTo = feeTo_;
        emit SetFeeTo(feeTo_);
    }

    /**
     * @notice Changes the merchant fee beneficiary. Can only be set by the contract owner.
     * This value cannot be set to 0 to avoid unsettled fee.
     * @param merchantFeeTo_ new merchant fee beneficiary
     */
    function setMerchantFeeTo(address merchantFeeTo_) external onlyOwner {
        _checkAddress(merchantFeeTo_);
        merchantFeeTo = merchantFeeTo_;
        emit SetMerchantFeeTo(merchantFeeTo_);
    }

    /// @notice sets whitelist address
    /// @param _whitelist the new whitelist address
    function setWhitelist(IWhitelist _whitelist) external onlyOwner {
        require(address(_whitelist) != address(0), 'zero address');
        whitelist = _whitelist;
        emit SetWhiteList(address(_whitelist));
    }

    /// @notice sets whitelist end time
    /// @param _whitelistEndTime the new whitelist end time
    function setWhitelistEndTime(uint256 _whitelistEndTime) external onlyOwner {
        require(_whitelistEndTime > block.timestamp, 'invalid end time');
        whitelistEndTime = _whitelistEndTime;
        emit SetWhiteListEndTime(_whitelistEndTime);
    }

    /* Tokens */

    /**
     * @notice Adds MERCH token to Master, reverts if token already exists in Master
     * @param token The address of MERCH token
     */
    function addAsset(address token) external onlyOwner nonReentrant {
        _checkAddress(token);

        if (_containsAsset(token)) revert MERCH_ASSET_ALREADY_EXIST();
        _assets.values[token] = IAsset(token);
        _assets.indexOf[token] = _assets.keys.length;
        _assets.keys.push(token);

        emit AssetAdded(token);
    }

    /**
     * @notice Removes asset from asset struct
     * @dev Can only be called by owner
     * @param token The address of token to remove
     */
    function removeAsset(address token) external onlyOwner {
        if (!_containsAsset(token)) revert MERCH_ASSET_NOT_EXISTS();

        delete _assets.values[token];

        uint256 index = _assets.indexOf[token];
        uint256 lastIndex = _assets.keys.length - 1;
        address lastKey = _assets.keys[lastIndex];

        _assets.indexOf[lastKey] = index;
        delete _assets.indexOf[token];

        _assets.keys[index] = lastKey;
        _assets.keys.pop();

        emit AssetRemoved(token);
    }

    /**
     * @notice Return list of tokens in the Master
     */
    function getTokens() external view override returns (address[] memory) {
        return _assets.keys;
    }

    /**
     * @notice Return fees collected for a token
     */
    function feesCollected(address token) external view returns (uint256) {
        IAsset asset = _assetOf(token);
        return _feeCollected[asset];
    }

    /**
     * @notice get length of asset list
     * @return the size of the asset list
     */
    function _sizeOfAssetList() internal view returns (uint256) {
        return _assets.keys.length;
    }

    /**
     * @notice Gets asset with token address key
     * @param key The address of token
     * @return the corresponding asset in state
     */
    function _getAsset(address key) internal view returns (IAsset) {
        return _assets.values[key];
    }

    /**
     * @notice Gets key (address) at index
     * @param index the index
     * @return the key of index
     */
    function _getKeyAtIndex(uint256 index) internal view returns (address) {
        return _assets.keys[index];
    }

    /**
     * @notice Looks if the asset is contained by the list
     * @param token The address of token to look for
     * @return bool true if the asset is in asset list, false otherwise
     */
    function _containsAsset(address token) internal view returns (bool) {
        return _assets.values[token] != IAsset(address(0));
    }

    /**
     * @notice Gets Asset corresponding to ERC20 token. Reverts if asset does not exists in Master.
     * @param token The address of ERC20 token
     */
    function _assetOf(address token) internal view returns (IAsset) {
        if (!_containsAsset(token)) revert MERCH_ASSET_NOT_EXISTS();
        return _assets.values[token];
    }

    /**
     * @notice Gets Asset corresponding to ERC20 token. Reverts if asset does not exists in Master.
     * @dev to be used externally
     * @param token The address of ERC20 token
     */
    function addressOfAsset(address token) external view override returns (address) {
        return address(_assetOf(token));
    }

    /**
     * @notice Buy 1 amount of MERCH token and pay WETH amount to `asset` address requiring 1 MERCH token amount
     * @param token The address of MERCH token
     * @param amount The MERCH amount to be bought
     * @param maxAmount The max WETH amount that will be accepted by user
     * @param to The user receiving the MERCH amount
     * @param deadline The deadline to be respected
     * @return finalAmount The total WETH amount to be paid
     */
    function buy(
        address token,
        uint256 amount,
        uint256 maxAmount,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256 finalAmount) {
        if (block.timestamp < whitelistEndTime) {
            require(whitelist.check(to) && IERC20(token).balanceOf(to) == 0, 'not eligible to buy');
            amount = 1 * WAD;
        }
        _checkAddress(to);
        _ensure(deadline);

        IAsset asset = _assetOf(token);

        (uint256 quote, uint256 haircut) = quotePotentialSwap(asset.baseToken(), token, amount);
        finalAmount = quote + haircut;
        _checkAmount(finalAmount, maxAmount);

        // request WETH token from user
        IERC20(asset.baseToken()).safeTransferFrom(address(msg.sender), address(asset), finalAmount);

        // mint MERCH token to user
        asset.mint(to, amount);
        asset.addVirtualSupply(amount);

        // update fee collected
        _feeCollected[asset] += haircut;

        emit Buy(msg.sender, token, amount, finalAmount, to);
    }

    /**
     * @notice Sell 1 amount of MERCH token and receive WETH amount to `to` address ensuring minimum amount required
     * @param token The MERCH token to be sold
     * @param amount The MERCH amount to be sold
     * @param minAmount The minimum WETH amount that will be accepted by user
     * @param to The user receiving the WETH amount
     * @param deadline The deadline to be respected
     * @return finalAmount The total WETH amount received
     */
    function sell(
        address token,
        uint256 amount,
        uint256 minAmount,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256 finalAmount) {
        if (block.timestamp < whitelistEndTime) {
            revert MERCH_WHITELIST_NOT_ENDED();
        }
        _checkAddress(to);
        _ensure(deadline);

        IAsset asset = _assetOf(token);

        (uint256 quote, uint256 haircut) = quotePotentialSwap(token, asset.baseToken(), amount);
        finalAmount = quote - haircut;
        _checkAmount(minAmount, finalAmount);

        // update and collect fee
        _feeCollected[asset] += haircut;
        _mintFee(asset);

        // request $MERCH token from user
        IERC20(asset).safeTransferFrom(address(msg.sender), address(asset), amount);
        asset.burn(address(asset), amount);
        asset.removeVirtualSupply(amount);
        // release WETH token to user
        asset.transferBaseToken(to, finalAmount);

        emit Sell(msg.sender, token, amount, finalAmount, to);
    }

    /**
     * @notice Redeems and burns token amount of asset
     * @param token The token to be redeemed
     * @param deadline The deadline to be respected
     */
    function redeem(address token, uint256 deadline) external nonReentrant returns (uint256 tokenAmount) {
        if (block.timestamp < whitelistEndTime) {
            revert MERCH_WHITELIST_NOT_ENDED();
        }
        _ensure(deadline);

        IAsset asset = _assetOf(token);
        uint256 virtualSupply = asset.virtualSupply();
        uint256 tokenSupply = asset.totalSupply();
        tokenAmount = 1 * WAD;

        // request $MERCH token from user
        IERC20(asset).safeTransferFrom(address(msg.sender), address(asset), tokenAmount);

        // burn 1 $MERCH token from total supply
        asset.burn(address(asset), tokenAmount);

        // transfer burned fee to merchant fee to address
        uint256 amount = _buyQuoteFunc(virtualSupply - tokenSupply, tokenAmount);
        uint256 baseAmount = amount.fromWad(asset.baseTokenDecimals());
        
        asset.transferBaseToken(merchantFeeTo, baseAmount);
        emit Redeem(msg.sender, token, tokenAmount, baseAmount, merchantFeeTo);
    }

    /* Queries */

    /**
     * @notice Given the WETH and MERCH token input, calculates the
     * WETH token amount and haircut fees required.
     * @dev To be used by frontend, fromToken and toToken must be different
     * @param fromToken The initial ERC20 token
     * @param toToken The token wanted by user
     * @param amount The MERCH amount swapped
     * @return quote The quote of the swap
     * @return haircut The haircut that would be applied
     */
    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 amount
    ) public view returns (uint256 quote, uint256 haircut) {
        _checkSameAddress(fromToken, toToken);

        // check if MERCH asset is in Master
        bool isFromTokenAsset = _containsAsset(fromToken);
        bool isToTokenAsset = _containsAsset(toToken);

        // latest buy quote
        if (!isFromTokenAsset && isToTokenAsset) {
            IAsset toAsset = _assetOf(toToken);
            uint256 virtualSupply = toAsset.virtualSupply();
            uint256 rawQuote = _buyQuoteFunc(virtualSupply, amount);
            haircut = rawQuote.wmul(haircutRate).fromWad(toAsset.baseTokenDecimals());
            quote = rawQuote.fromWad(toAsset.baseTokenDecimals());

            // latest sell quote
        } else if (isFromTokenAsset && !isToTokenAsset) {
            IAsset fromAsset = _assetOf(fromToken);
            uint256 virtualSupply = fromAsset.virtualSupply();
            uint256 rawQuote = _sellQuoteFunc(virtualSupply, amount);
            haircut = rawQuote.wmul(haircutRate).fromWad(fromAsset.baseTokenDecimals());
            quote = rawQuote.fromWad(fromAsset.baseTokenDecimals());
        }
    }

    /* Utils */

    /**
     * @notice Merch buy swap equation
     * @dev This function always returns > 0
     * @param virtualSupply The virtual supply of the asset
     * @param amount The amount swapped
     * @return quote The buy quote
     */
    function _buyQuoteFunc(uint256 virtualSupply, uint256 amount) internal pure returns (uint256 quote) {
        int256 lhs_1 = DSMath.toInt256(magicNum1).wmul(LogExpMath.exp(DSMath.toInt256(magicNum2.wmul(virtualSupply + amount))));
        int256 lhs_2 = DSMath.toInt256(magicNum3.wmul(virtualSupply + amount));
        int256 lhs = lhs_1 + lhs_2;
        int256 rhs_1 = DSMath.toInt256(magicNum1).wmul(LogExpMath.exp(DSMath.toInt256(magicNum2.wmul(virtualSupply))));
        int256 rhs_2 = DSMath.toInt256(magicNum3.wmul(virtualSupply));
        int256 rhs = rhs_1 + rhs_2;
        quote = SignedSafeMath.toUint256(lhs - rhs);
    }

    /**
    /**
     * @notice Merch sell swap equation
     * @dev This function always returns > 0
     * @param virtualSupply The virtual supply of the asset
     * @param amount The amount swapped
     * @return quote The sell quote
     */
    function _sellQuoteFunc(uint256 virtualSupply, uint256 amount) internal pure returns (uint256 quote) {
        int256 lhs_1 = DSMath.toInt256(magicNum1).wmul(LogExpMath.exp(DSMath.toInt256(magicNum2.wmul(virtualSupply))));
        int256 lhs_2 = DSMath.toInt256(magicNum3.wmul(virtualSupply));
        int256 lhs = lhs_1 + lhs_2;
        int256 rhs_1 = DSMath.toInt256(magicNum1).wmul(LogExpMath.exp(DSMath.toInt256(magicNum2.wmul(virtualSupply - amount))));
        int256 rhs_2 = DSMath.toInt256(magicNum3.wmul(virtualSupply - amount));
        int256 rhs = rhs_1 + rhs_2;
        quote = SignedSafeMath.toUint256(lhs - rhs);
    }

    /**
     * @notice Private function to send fee collected to the fee beneficiary
     * @param asset The address of the asset to collect fee
     */
    function _mintFee(IAsset asset) internal {
        uint256 feeCollected = _feeCollected[asset];
        _feeCollected[asset] = 0;
        if (feeCollected > 0) {
            asset.transferBaseToken(feeTo, feeCollected);
        }
    }

    function mintAllFee() internal {
        for (uint256 i = 0; i < _sizeOfAssetList(); i++) {
            IAsset asset = _getAsset(_getKeyAtIndex(i));
            _mintFee(asset);
        }
    }

    /**
     * @notice Send fee collected to the fee beneficiary
     * @param token The address of the token to collect fee
     */
    function mintFee(address token) external {
        _mintFee(_assetOf(token));
    }
}
