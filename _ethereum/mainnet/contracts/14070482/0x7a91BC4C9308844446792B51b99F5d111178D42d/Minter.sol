// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ReentrancyGuard.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./EnumerableSet.sol";
import "./IAggregatorV3.sol";
import "./ICompound.sol";
import "./ICurveMetapool.sol";
import "./IVUSD.sol";

/// @title Minter contract which will mint VUSD 1:1, less minting fee, with DAI, USDC or USDT.
contract Minter is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "VUSD-Minter";
    string public constant VERSION = "1.3.0";

    IVUSD public immutable vusd;

    uint256 public mintingFee; // Default no fee
    uint256 public constant MAX_BPS = 10_000; // 10_000 = 100%
    uint256 public constant MINT_LIMIT = 50_000_000 * 10**18; // 50M VUSD
    uint256 private constant STABLE_PRICE = 100_000_000;
    uint256 private constant MAX_UINT_VALUE = type(uint256).max;
    uint256 public priceDeviationLimit = 400; // 4% based on BPS
    uint256 internal priceUpperBound;
    uint256 internal priceLowerBound;

    // Token => cToken mapping
    mapping(address => address) public cTokens;
    // Token => oracle mapping
    mapping(address => address) public oracles;

    address public constant CURVE_METAPOOL = 0x4dF9E1A764Fb8Df1113EC02fc9dc75963395b508;
    EnumerableSet.AddressSet private _whitelistedTokens;

    // Default whitelist token addresses
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // cToken addresses for default whitelisted tokens
    //solhint-disable const-name-snakecase
    address private constant cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address private constant cUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;

    // Chainlink price oracle for default whitelisted tokens
    address private constant DAI_USD = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address private constant USDC_USD = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

    event UpdatedMintingFee(uint256 previousMintingFee, uint256 newMintingFee);
    event UpdatedPriceDeviationLimit(uint256 previousDeviationLimit, uint256 newDeviationLimit);

    constructor(address _vusd) {
        require(_vusd != address(0), "vusd-address-is-zero");
        vusd = IVUSD(_vusd);

        // Add token into the list, add oracle and cToken into the mapping and approve cToken to spend token
        _addToken(DAI, cDAI, DAI_USD);
        _addToken(USDC, cUSDC, USDC_USD);
        IERC20(_vusd).safeApprove(CURVE_METAPOOL, MAX_UINT_VALUE);
    }

    modifier onlyGovernor() {
        require(_msgSender() == governor(), "caller-is-not-the-governor");
        _;
    }

    ////////////////////////////// Only Governor //////////////////////////////
    /**
     * @notice Add token as whitelisted token for VUSD system
     * @dev Add token address in whitelistedTokens list and add cToken in mapping
     * @param _token address which we want to add in token list.
     * @param _cToken CToken address correspond to _token
     * @param _oracle Chainlink oracle address for token/USD feed
     */
    function addWhitelistedToken(
        address _token,
        address _cToken,
        address _oracle
    ) external onlyGovernor {
        require(_token != address(0), "token-address-is-zero");
        require(_cToken != address(0), "cToken-address-is-zero");
        require(_oracle != address(0), "oracle-address-is-zero");
        _addToken(_token, _cToken, _oracle);
    }

    /**
     * @notice Remove token from whitelisted tokens
     * @param _token address which we want to remove from token list.
     */
    function removeWhitelistedToken(address _token) external onlyGovernor {
        require(_whitelistedTokens.remove(_token), "remove-from-list-failed");
        IERC20(_token).safeApprove(cTokens[_token], 0);
        delete cTokens[_token];
        delete oracles[_token];
    }

    /**
     * @notice Mint request amount of VUSD and use minted VUSD to add liquidity in metapool
     * @dev Treasury will receive LP tokens of metapool liquidity
     * @param _amount Amount of VUSD to mint
     */
    function mintAndAddLiquidity(uint256 _amount) external onlyGovernor {
        uint256 _availableMintage = availableMintage();
        if (_amount > _availableMintage) {
            _amount = _availableMintage;
        }
        vusd.mint(address(this), _amount);
        ICurveMetapool(CURVE_METAPOOL).add_liquidity([_amount, 0], 1, treasury());
    }

    /// @notice Update minting fee
    function updateMintingFee(uint256 _newMintingFee) external onlyGovernor {
        require(_newMintingFee <= MAX_BPS, "minting-fee-limit-reached");
        require(mintingFee != _newMintingFee, "same-minting-fee");
        emit UpdatedMintingFee(mintingFee, _newMintingFee);
        mintingFee = _newMintingFee;
    }

    /// @notice Update price deviation limit
    function updatePriceDeviationLimit(uint256 _newDeviationLimit) external onlyGovernor {
        require(_newDeviationLimit <= MAX_BPS, "price-deviation-is-invalid");
        require(priceDeviationLimit != _newDeviationLimit, "same-price-deviation-limit");
        emit UpdatedPriceDeviationLimit(priceDeviationLimit, _newDeviationLimit);
        priceDeviationLimit = _newDeviationLimit;
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Mint VUSD
     * @param _token Address of token being deposited
     * @param _amount Amount of _token
     */
    function mint(address _token, uint256 _amount) external nonReentrant {
        _mint(_token, _amount, _msgSender());
    }

    /**
     * @notice Mint VUSD
     * @param _token Address of token being deposited
     * @param _amount Amount of _token
     * @param _receiver Address of VUSD receiver
     */
    function mint(
        address _token,
        uint256 _amount,
        address _receiver
    ) external nonReentrant {
        _mint(_token, _amount, _receiver);
    }

    /**
     * @notice Calculate mintage for supported tokens.
     * @param _token Address of token which will be deposited for this mintage
     * @param _amount Amount of _token
     */
    function calculateMintage(address _token, uint256 _amount) external view returns (uint256 _mintReturn) {
        if (_whitelistedTokens.contains(_token)) {
            (uint256 _mintage, ) = _calculateMintage(_token, _amount);
            return _mintage;
        }
        // Return 0 for unsupported tokens.
        return 0;
    }

    /**
     * @notice Check whether minting is allowed or not.
     * @dev We are using chainlink oracle to check latest price and if price
     * is within allowed range then only minting is allowed.
     * @param _token Address of any of whitelisted token
     */
    function isMintingAllowed(address _token) external view returns (bool) {
        if (_whitelistedTokens.contains(_token)) {
            return _isMintingAllowed(_token);
        }
        return false;
    }

    /// @notice Returns whether given address is whitelisted or not
    function isWhitelistedToken(address _address) external view returns (bool) {
        return _whitelistedTokens.contains(_address);
    }

    /// @notice Return list of whitelisted tokens
    function whitelistedTokens() external view returns (address[] memory) {
        return _whitelistedTokens.values();
    }

    /// @notice Check available mintage based on mint limit
    function availableMintage() public view returns (uint256 _mintage) {
        return MINT_LIMIT - vusd.totalSupply();
    }

    /// @dev Treasury is defined in VUSD token contract only
    function treasury() public view returns (address) {
        return vusd.treasury();
    }

    /// @dev Governor is defined in VUSD token contract only
    function governor() public view returns (address) {
        return vusd.governor();
    }

    /**
     * @dev Add _token into the list, add _cToken in mapping and
     * approve cToken to spend token
     */
    function _addToken(
        address _token,
        address _cToken,
        address _oracle
    ) internal {
        require(_whitelistedTokens.add(_token), "add-in-list-failed");
        oracles[_token] = _oracle;
        cTokens[_token] = _cToken;
        IERC20(_token).safeApprove(_cToken, type(uint256).max);
    }

    /**
     * @notice Mint VUSD
     * @param _token Address of token being deposited
     * @param _amount Amount of _token
     * @param _receiver Address of VUSD receiver
     */
    function _mint(
        address _token,
        uint256 _amount,
        address _receiver
    ) internal {
        require(_whitelistedTokens.contains(_token), "token-is-not-supported");
        require(_isMintingAllowed(_token), "too-much-token-price-deviation");
        (uint256 _mintage, uint256 _actualAmount) = _calculateMintage(_token, _amount);
        require(_mintage != 0, "mint-limit-reached");
        IERC20(_token).safeTransferFrom(_msgSender(), address(this), _actualAmount);
        address _cToken = cTokens[_token];
        require(CToken(_cToken).mint(_actualAmount) == 0, "cToken-mint-failed");
        IERC20(_cToken).safeTransfer(treasury(), IERC20(_cToken).balanceOf(address(this)));
        vusd.mint(_receiver, _mintage);
    }

    /**
     * @notice Calculate mintage based on mintingFee, if any.
     * Also covert _token defined decimal amount to 18 decimal amount
     * @return _mintage VUSD mintage based on given input
     * @return _actualAmount Actual token amount used for _mintage
     */
    function _calculateMintage(address _token, uint256 _amount)
        internal
        view
        returns (uint256 _mintage, uint256 _actualAmount)
    {
        uint256 _decimals = IERC20Metadata(_token).decimals();
        uint256 _availableAmount = availableMintage() / 10**(18 - _decimals);
        _actualAmount = (_amount > _availableAmount) ? _availableAmount : _amount;
        _mintage = (mintingFee != 0) ? _actualAmount - ((_actualAmount * mintingFee) / MAX_BPS) : _actualAmount;
        // Convert final amount to 18 decimals
        _mintage = _mintage * 10**(18 - _decimals);
    }

    function _isMintingAllowed(address _token) internal view returns (bool) {
        address _oracle = oracles[_token];
        uint8 _oracleDecimal = IAggregatorV3(_oracle).decimals();
        uint256 _stablePrice = 10**_oracleDecimal;
        uint256 _deviationInPrice = (_stablePrice * priceDeviationLimit) / MAX_BPS;
        uint256 _priceUpperBound = _stablePrice + _deviationInPrice;
        uint256 _priceLowerBound = _stablePrice - _deviationInPrice;
        (, int256 _price, , , ) = IAggregatorV3(_oracle).latestRoundData();

        uint256 _latestPrice = uint256(_price);
        return _latestPrice <= _priceUpperBound && _latestPrice >= _priceLowerBound;
    }
}
