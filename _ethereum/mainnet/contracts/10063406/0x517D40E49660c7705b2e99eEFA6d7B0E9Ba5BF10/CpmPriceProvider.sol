pragma solidity ^0.6.6;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./IExtendedAggregator.sol";
import "./ILatestAnswerGetter.sol";
import "./IPriceOracleGetter.sol";
import "./IERC20Metadata.sol";
import "./IPriceGetterCpm.sol";
import "./EthAddressLib.sol";
import "./MathUtils.sol";

/** @title CpmPriceProvider
 * @author Aave
 * @notice Constant Product Market price provider for a token/ETH pair , represented by a CPM token
 * - Using an external price source for the token side of the pair and an extra oracle as fallback
 * - IMPORTANT. It's as assumption that the last calculation on latestAnswer() doesn't overflow because
 *   the token/ETH balances and prices are validated before creating the corresponding CpmPriceProvider
 *   for them.
 */
contract CpmPriceProvider is IExtendedAggregator {
    using SafeMath for uint256;
    
    uint256 public immutable PRICE_DEVIATION; // 10 represents a 1% deviation
    IERC20 internal immutable CPM_TOKEN;
    IERC20 public immutable TOKEN;
    bool public immutable PEGGED_TO_ETH;
    ILatestAnswerGetter public immutable TOKEN_PRICE_PROVIDER;
    IPriceOracleGetter public immutable FALLBACK_ORACLE;
    uint256 public immutable TOKEN_DECIMALS;
    uint256 internal immutable CPM_TOKEN_TYPE;
    uint256 internal immutable PLATFORM_ID;
    address[] internal subTokens;

    event Setup(
        address indexed creator,
        IERC20 indexed cpmToken,
        IERC20 indexed token,
        bool peggedToEth,
        uint256 priceDeviation,
        ILatestAnswerGetter tokenPriceProvider,
        IPriceOracleGetter fallbackOracle,
        uint256 cpmTokenType,
        uint256 platformId
    );
    
    constructor(
        IERC20 _cpmToken,
        IERC20 _token,
        bool _peggedToEth,
        uint256 _priceDeviation,
        ILatestAnswerGetter _tokenPriceProvider,
        IPriceOracleGetter _fallbackOracle,
        uint256 _cpmTokenType,
        uint256 _platformId
    ) public {
        CPM_TOKEN = _cpmToken;
        TOKEN = _token;
        PEGGED_TO_ETH = _peggedToEth;
        PRICE_DEVIATION = _priceDeviation;
        TOKEN_PRICE_PROVIDER = _tokenPriceProvider;
        FALLBACK_ORACLE = _fallbackOracle;
        TOKEN_DECIMALS = (_peggedToEth) ? 18 : uint256(IERC20Metadata(address(_token)).decimals());
        CPM_TOKEN_TYPE = _cpmTokenType;
        PLATFORM_ID = _platformId;
        subTokens.push(EthAddressLib.ethAddress());
        subTokens.push(address(_token));
        emit Setup(
            msg.sender,
            _cpmToken,
            _token,
            _peggedToEth,
            _priceDeviation,
            _tokenPriceProvider,
            _fallbackOracle,
            _cpmTokenType,
            _platformId
        );
    }

    /** 
     * @notice Returns the price in ETH wei of 1 big unit of CPM_TOKEN, taking into account the different ETH prices of the underlyings
     * - If a big deviation between the price token -> ETH within the CPM compared with the price in the TOKEN_PRICE_PROVIDER is detected,
     * it does the calculations using as ETH and token balances, normalized ones with a price within the CPM close to the external
     * @return The price
     */
    function latestAnswer() external view override returns (int256) {
        uint256 _cpmTokenSupply = CPM_TOKEN.totalSupply();
        int256 _signedPrice = (PEGGED_TO_ETH) ? 1 ether : TOKEN_PRICE_PROVIDER.latestAnswer();
        uint256 _externalPriceOfTokenBigUnitsInWei = (_signedPrice > 0) ? uint256(_signedPrice) : FALLBACK_ORACLE.getAssetPrice(address(TOKEN));
        if (_externalPriceOfTokenBigUnitsInWei == 0) {
            return 0;
        }
        uint256 _cpmPriceOfTokenBigUnitsInWei = IPriceGetterCpm(address(CPM_TOKEN)).getTokenToEthInputPrice(10**TOKEN_DECIMALS);

        uint256 _normalizedEthBalanceInWei = address(CPM_TOKEN).balance;
        uint256 _normalizedTokenBalanceInDecimalUnits = TOKEN.balanceOf(address(CPM_TOKEN));
        uint256 _priceDeviation = _cpmPriceOfTokenBigUnitsInWei.mul(1000).div(_externalPriceOfTokenBigUnitsInWei);
        
        // Case of high deviation. 
        // Both sub-cases of token overpriced (> 1010) and ETH overpriced (> 990) can be calculated with common logic, based on the K property of the CPM
        if (_priceDeviation > (1000 + PRICE_DEVIATION) || _priceDeviation < (1000 - PRICE_DEVIATION)) {
            uint256 _K = _normalizedEthBalanceInWei.mul(_normalizedTokenBalanceInDecimalUnits);
            // The 10**TOKEN_DECIMALS is needed to not lose the magnitude of the token decimals
            _normalizedTokenBalanceInDecimalUnits = MathUtils.sqrt(_K.div(_externalPriceOfTokenBigUnitsInWei).mul(10**TOKEN_DECIMALS));
            _normalizedEthBalanceInWei = _K.div(_normalizedTokenBalanceInDecimalUnits);
        }

        return int256(
            (_normalizedEthBalanceInWei  + _normalizedTokenBalanceInDecimalUnits.mul(_externalPriceOfTokenBigUnitsInWei).div(10**TOKEN_DECIMALS))
                .mul(1 ether)
                .div(_cpmTokenSupply)
            );
    }

    /** 
     * @notice Return the address of the CPM token
     * @return address
     */
    function getToken() external view override returns(address) {
        return address(CPM_TOKEN);
    }

    /** 
     * @notice Return the list of tokens' addresses composing the CPM token
     * - Using EthAddressLib.ethAddress() as mock address for ETH.
     * - The reference token is first on the list
     * @return addresses
     */
    function getSubTokens() external view override returns(address[] memory) {
        return subTokens;
    }

    /** 
     * @notice Return the numeric type of the CPM token
     * @return type
     */
    function getTokenType() external view override returns(uint256) {
        return CPM_TOKEN_TYPE;
    }

    /** 
     * @notice Return the numeric platform id
     * @return platform id
     */
    function getPlatformId() external view override returns (uint256) {
        return PLATFORM_ID;
    }
}