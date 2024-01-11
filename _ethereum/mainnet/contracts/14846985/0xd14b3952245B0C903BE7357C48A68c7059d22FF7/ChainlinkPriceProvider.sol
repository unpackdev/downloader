// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./PriceProvider.sol";
import "./AggregatorV3Interface.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";

/**
 * Chainlink price provider
 */
contract ChainlinkPriceProvider is PriceProvider, Initializable, AccessControlUpgradeable {

    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    string public constant DESCRIPTION = "Price provider that uses chainlink";

    uint8 public usdDecimals;

    mapping(address => ChainlinkMetadata) public chainlinkMetadata; // address of token => metadata of chainlink

    struct ChainlinkMetadata{
        bool isActive;
        address[] aggregatorPath;
    }

    event GrandModeratorRole(address indexed who, address indexed newModerator);
    event RevokeModeratorRole(address indexed who, address indexed moderator);
    event SetTokenAndAggregator(address indexed who, address indexed token, address[] aggeregatorPath);
    event ChangeActive(address indexed who, address indexed token, bool active);


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
        require(hasRole(MODERATOR_ROLE, msg.sender), "Caller is not the moderator");
        _;
    }

    /****************** Admin functions ****************** */

    function grandModerator(address newModerator) public onlyAdmin {
        grantRole(MODERATOR_ROLE, newModerator);
        emit GrandModeratorRole(msg.sender, newModerator);
    }

    function revokeModerator(address moderator) public onlyAdmin {
        revokeRole(MODERATOR_ROLE,moderator);
        emit RevokeModeratorRole(msg.sender, moderator);
    }

    /****************** Moderator functions ****************** */

    function setTokenAndAggregator(address token, address[] memory aggregatorPath) public onlyModerator {
        ChainlinkMetadata storage metadata = chainlinkMetadata[token];
        metadata.isActive = true;
        require(aggregatorPath.length <= 5, "ChainlinkPriceProvider: too long path");
        metadata.aggregatorPath = aggregatorPath;
        emit SetTokenAndAggregator(msg.sender, token, aggregatorPath);
    }

    function changeActive(address token, bool active) public override onlyModerator {
        require(chainlinkMetadata[token].aggregatorPath[0] != address(0),"ChainlinkPriceProvider: token is not listed!");
        chainlinkMetadata[token].isActive = active;
        emit ChangeActive(msg.sender, token, active);
    }

    /****************** View functions ****************** */

    function isListed(address token) public override view returns(bool){
        if(chainlinkMetadata[token].aggregatorPath[0] != address(0)){
            return true;
        }else{
            return false;
        }
    }

    function isActive(address token) public override view returns(bool){
        return chainlinkMetadata[token].isActive;
    }

    /**
     * @notice Returns the latest asset price mantissa and price decimals
     * @notice [price] = USD/token
     * @param token the token address
     * @dev First step is get priceMantissa with priceDecimals by this formula:
     *      price = 1 * 10 ** tokenDecimals * (chainlinkPrice_1 / 10 ** priceDecimals_1) * ... * (chainlinkPrice_n / 10 ** priceDecimals_n) = 
     *            = 10 ** tokenDecimals (chainlinkPrice_1 * ... * chainlinkPrice_n) / 10 ** (priceDecimals_1 + ... + priceDecimals_n)
     *      Second step is scale priceMantissa to usdDecimals
     */
    function getPrice(address token) public override view returns (uint256 priceMantissa, uint8 priceDecimals) {
        ChainlinkMetadata memory metadata = chainlinkMetadata[token];
        require(metadata.isActive,"ChainlinkPriceProvider: token is not available!");
        address[] memory aggregatorPath = metadata.aggregatorPath;
        priceMantissa = 1;
        priceDecimals = 0;
        for(uint8 i = 0; i < aggregatorPath.length; i++) {
            priceMantissa *= AggregatorV3Interface(aggregatorPath[i]).latestAnswer();   // earn price
            priceDecimals += AggregatorV3Interface(aggregatorPath[i]).decimals();       // earn price decimals
        }
        if (priceDecimals >= usdDecimals) {
            priceMantissa /= 10 ** (priceDecimals - usdDecimals);
        } else {
            priceMantissa *= 10 ** (usdDecimals - priceDecimals);
        }
        priceDecimals = usdDecimals;
    }

    /**
     * @notice returns the equivalent amount in USD
     * @param token the address of token
     * @param tokenAmount the amount of token 
     */
    function getEvaluation(address token, uint256 tokenAmount) public override view returns(uint256 evaluation) {
        (uint256 priceMantissa, uint8 priceDecimals) = getPrice(token);
        evaluation = tokenAmount * priceMantissa / 10 ** (priceDecimals); // get the evaluation scaled by 10**tokenDecimals
        uint8 tokenDecimals = ERC20Upgradeable(token).decimals();
        if(tokenDecimals >= usdDecimals){
            evaluation = evaluation / (10 ** (tokenDecimals - usdDecimals)); //get the evaluation in USD.
        }else{
            evaluation = evaluation * (10 ** (usdDecimals - tokenDecimals)); 
        }
    }

    function getPriceDecimals() public view override returns (uint8) {
        return usdDecimals;
    }
}