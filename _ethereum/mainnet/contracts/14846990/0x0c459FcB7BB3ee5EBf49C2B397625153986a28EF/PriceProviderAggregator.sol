// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./PriceProvider.sol";

contract PriceProviderAggregator is Initializable,
                                    AccessControlUpgradeable
{

    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    
    uint8 public usdDecimals;

    mapping(address => PriceProviderInfo) public tokenPriceProvider; // address of project token => priceProvider address

    struct PriceProviderInfo {
        address priceProvider;
        bool hasSignedFunction;
    }

    event GrandModeratorRole(address indexed who, address indexed newModerator);
    event RevokeModeratorRole(address indexed who, address indexed moderator);
    event SetTokenAndPriceProvider(address indexed who, address indexed token, address indexed priceProvider);
    event ChangeActive(address indexed who, address indexed priceProvider, address indexed token, bool active);

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, msg.sender);
        usdDecimals = 6;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the Admin");
        _;
    }

    modifier onlyModerator() {
        require(hasRole(MODERATOR_ROLE, msg.sender), "Caller is not the Moderator");
        _;
    }

    /****************** Admin functions ****************** */

    function grandModerator(address newModerator) public onlyAdmin {
        grantRole(MODERATOR_ROLE, newModerator);
        emit GrandModeratorRole(msg.sender, newModerator);
    }

    function revokeModerator(address moderator) public onlyAdmin {
        revokeRole(MODERATOR_ROLE, moderator);
        emit RevokeModeratorRole(msg.sender, moderator);
    }    

    /****************** end Admin functions ****************** */

    /****************** Moderator functions ****************** */

    /**
     * @dev sets price provider to `token`
     * @param token the address of token
     * @param priceProvider the address of price provider. Should implememnt the interface of `PriceProvider`
     * @param hasFunctionWithSign true - if price provider has function with signatures
     *                            false - if price provider does not have function with signatures
     */
    function setTokenAndPriceProvider(address token, address priceProvider, bool hasFunctionWithSign) public onlyModerator {
        require(token != address(0), "USBPriceOracle: invalid token");
        require(priceProvider != address(0), "USBPriceOracle: invalid priceProvider");
        PriceProviderInfo storage priceProviderInfo = tokenPriceProvider[token];
        priceProviderInfo.priceProvider = priceProvider;
        priceProviderInfo.hasSignedFunction = hasFunctionWithSign;
        emit SetTokenAndPriceProvider(msg.sender, token, priceProvider);
    }

    function changeActive(address priceProvider, address token, bool active) public onlyModerator {
        require(tokenPriceProvider[token].priceProvider == priceProvider, "USBPriceOracle: mismatch token`s price provider");
        PriceProvider(priceProvider).changeActive(token, active);
        emit ChangeActive(msg.sender, priceProvider, token, active);
    }

    /****************** main functions ****************** */

    /**
     * @dev returns tuple (priceMantissa, priceDecimals)
     * @notice price = priceMantissa / (10 ** priceDecimals)
     * @param token the address of token wich price is to return
     */
    function getPrice(address token) public view returns(uint256 priceMantissa, uint8 priceDecimals){
        PriceProviderInfo memory priceProviderInfo = tokenPriceProvider[token];
        require(priceProviderInfo.hasSignedFunction == false, "USBPriceOracle: call getPriceWithSign()");
        return PriceProvider(priceProviderInfo.priceProvider).getPrice(token);
    }

    /**
     * @dev returns the tupple (priceMantissa, priceDecimals) of token multiplied by 10 ** priceDecimals given by price provider.
     * price can be calculated as  priceMantissa / (10 ** priceDecimals)
     * i.e. price = priceMantissa / (10 ** priceDecimals)
     * @param token the address of token
     * @param priceMantissa - the price of token (used in verifying the signature)
     * @param validTo - the timestamp in seconds (used in verifying the signature)
     * @param signature - the backend signature of secp256k1. length is 65 bytes
     */
    function getPriceSigned(address token, uint256 priceMantissa, uint256 validTo, bytes memory signature) public view returns(uint256 priceMantissa_, uint8 priceDecimals){
        PriceProviderInfo memory priceProviderInfo = tokenPriceProvider[token];
        if (priceProviderInfo.hasSignedFunction) {
            return PriceProvider(priceProviderInfo.priceProvider).getPriceSigned(token, priceMantissa, validTo, signature);
        } else {
            return PriceProvider(priceProviderInfo.priceProvider).getPrice(token);
        }
    }

    /**
     * @dev returns the USD evaluation of token by its `tokenAmount`
     * @param token the address of token to evaluate
     * @param tokenAmount the amount of token to evaluate
     */
    function getEvaluation(address token, uint256 tokenAmount) public view returns(uint256 evaluation){
        PriceProviderInfo memory priceProviderInfo = tokenPriceProvider[token];
        require(priceProviderInfo.hasSignedFunction == false, "USBPriceOracle: call getEvaluationWithSign()");
        return PriceProvider(priceProviderInfo.priceProvider).getEvaluation(token, tokenAmount);
    }
    
    /**
     * @dev returns the USD evaluation of token by its `tokenAmount`
     * @param token the address of token
     * @param tokenAmount the amount of token including decimals
     * @param priceMantissa - the price of token (used in verifying the signature)
     * @param validTo - the timestamp in seconds (used in verifying the signature)
     * @param signature - the backend signature of secp256k1. length is 65 bytes
     */
    function getEvaluationSigned(address token, uint256 tokenAmount, uint256 priceMantissa, uint256 validTo, bytes memory signature) public view returns(uint256 evaluation){
        PriceProviderInfo memory priceProviderInfo = tokenPriceProvider[token];
        if (priceProviderInfo.hasSignedFunction) {
            return PriceProvider(priceProviderInfo.priceProvider).getEvaluationSigned(token, tokenAmount, priceMantissa, validTo, signature);
        } else {
            return PriceProvider(priceProviderInfo.priceProvider).getEvaluation(token, tokenAmount);
        }
    }

}
