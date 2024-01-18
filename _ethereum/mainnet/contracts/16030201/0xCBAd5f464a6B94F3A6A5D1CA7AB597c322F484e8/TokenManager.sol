// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./Initializable.sol";
import "./IERC20Metadata.sol";
import "./SafeCast.sol";
import "./AggregatorV3Interface.sol";

import "./ITokenManager.sol";
import "./CommonState.sol";
import "./Constants.sol";

/**
 * @title Base contract for handling the token whitelist
 * @author Shane van Coller, Jonas Sota
 */
abstract contract TokenManager is
    ITokenManager,
    Ownable,
    Initializable,
    CommonState,
    Constants
{
    using SafeCast for int256;
    using SafeCast for uint256;

    /**
     * @dev List of addresses of the tokens that are accepted as payment for the subscription.
     * Only tokens in this list will be accepted as payment when subscribing, all other tokens
     * will be rejected
     */
    address[] public acceptedTokensList;

    /**
     * @dev Details for each of the accepted tokens including how much has accumulated to it. Each
     * token has the following attributes:
     *
     * uint8 accepted - non zero value indicates that the token is accepted as payment. The actual
     * value represent the idx of the token in the array
     * AggregatorV3Interface chainlinkAggregator - address of the aggregator to get price info
     */
    mapping(address => TokenDetails) public tokenInfo;

    struct TokenDetails {
        uint8 accepted;
        AggregatorV3Interface chainlinkAggregator;
    }

    event TokenAdded(
        address indexed caller,
        address newToken,
        address chainlinkAggregator,
        uint256 createdAt
    );

    event TokenRemoved(
        address indexed caller,
        address removedToken,
        uint256 createdAt
    );

    // solhint-disable-next-line func-name-mixedcase
    function __TokenManager_init(
        address[] calldata acceptedTokens_,
        address[] calldata chainlinkAggregators_
    ) internal onlyInitializing {
        require(
            acceptedTokens_.length != 0 && chainlinkAggregators_.length != 0,
            "LC:MISSING_TOKEN_INFO"
        );
        _addTokens(acceptedTokens_, chainlinkAggregators_);
    }

    /*************************************************/
    /*************   EXTERNAL  GETTERS   *************/
    /*************************************************/
    /**
     * @notice Gets the number of accepted payment tokens
     *
     * @return number of payment tokens
     */
    function getAcceptedTokensCount() external view returns (uint256) {
        return acceptedTokensList.length;
    }

    /**********************************************/
    /**********   OWNER ONLY FUNCTIONS   **********/
    /**********************************************/
    /**
     * @notice Add a new payment token option
     *
     * @param tokens_ address of tokens to accept
     * @param chainlinkAggregators_ address of the chainlink aggregators
     */
    function addTokens(
        address[] calldata tokens_,
        address[] calldata chainlinkAggregators_
    ) external onlyOwner {
        _addTokens(tokens_, chainlinkAggregators_);
    }

    /**
     * @notice Remove a payment token option
     *
     * @param tokens_ address of token to remove
     */
    function removeTokens(address[] calldata tokens_) external onlyOwner {
        for (uint8 i = 0; i < tokens_.length; i++) {
            require(
                tokenInfo[tokens_[i]].accepted > 0,
                "LC:TOKEN_NOT_ACCEPTED"
            );

            uint256 removedIdx = tokenInfo[tokens_[i]].accepted - 1;
            address lastTokenAddress = acceptedTokensList[
                acceptedTokensList.length - 1
            ];
            tokenInfo[lastTokenAddress].accepted = (removedIdx + 1).toUint8();
            tokenInfo[tokens_[i]].accepted = 0;
            acceptedTokensList[removedIdx] = lastTokenAddress;
            acceptedTokensList.pop();

            emit TokenRemoved(msg.sender, tokens_[i], block.timestamp); // solhint-disable-line not-rely-on-time
        }
    }

    /**********************************************/
    /**********   INTERNAL/PRIVATE FUNCTIONS   **********/
    /**********************************************/
    /**
     * @notice Add a new payment token option
     *
     * @param tokens_ address of tokens to accept
     * @param chainlinkAggregators_ address of the chainlink aggregators
     */
    function _addTokens(
        address[] calldata tokens_,
        address[] calldata chainlinkAggregators_
    ) private {
        require(
            tokens_.length == chainlinkAggregators_.length,
            "LC:PRICE_FEED_PARITY_MISMATCH"
        );

        for (uint8 i = 0; i < tokens_.length; i++) {
            require(
                tokenInfo[tokens_[i]].accepted == 0,
                "LC:TOKEN_ALREADY_ACCEPTED"
            );
            require(
                chainlinkAggregators_[i] != address(0),
                "LC:INVALID_AGGREGATOR"
            );

            acceptedTokensList.push(tokens_[i]);

            TokenDetails storage tokenDetails = tokenInfo[tokens_[i]];
            tokenDetails.accepted = (acceptedTokensList.length).toUint8();
            tokenDetails.chainlinkAggregator = AggregatorV3Interface(
                chainlinkAggregators_[i]
            );

            emit TokenAdded(
                msg.sender,
                tokens_[i],
                chainlinkAggregators_[i],
                block.timestamp // solhint-disable-line not-rely-on-time
            );
        }
    }

    /**
     * @notice Gets the exchange rate to USD for a given token
     *
     * @param token_ address of token to get the exchange rate for
     *
     * @return exchangeRate Number of dollars per token
     * @return decimals Decimals of the exchangeRate figure, typically 8
     */
    function _getTokenToUsdRate(address token_)
        internal
        view
        returns (uint256 exchangeRate, uint8 decimals)
    {
        if (token_ == address(0)) {
            token_ = WETH;
        }
        AggregatorV3Interface chainlinkAggregator = tokenInfo[token_]
            .chainlinkAggregator;
        (, int256 usdToTokenRate, , , ) = chainlinkAggregator.latestRoundData();

        exchangeRate = (usdToTokenRate).toUint256();
        decimals = chainlinkAggregator.decimals();
    }

    /**
     * @notice Converts the USD value to the equivalent token value
     *
     * @dev - USD amount must be 8 decimal precision
     *
     * @param token_ Address of the token to convert to
     * @param usdAmount_ USD amount to convert from
     *
     * @return tokenAmount Token equivalent value
     * @return exchangeRate Number of dollars per token
     */
    function _convertUsdToTokenAmount(address token_, uint256 usdAmount_)
        internal
        view
        returns (uint256 tokenAmount, uint256 exchangeRate)
    {
        (
            uint256 _usdExchangeRate,
            uint8 _exchangeDecimals
        ) = _getTokenToUsdRate(token_);

        uint256 _tokenDecimals = IERC20Metadata(token_).decimals();

        // Normalize exchange rate to USD_DECIMALS
        _usdExchangeRate = _exchangeDecimals >= USD_DECIMALS
            ? _usdExchangeRate / (10**(_exchangeDecimals - USD_DECIMALS))
            : _usdExchangeRate * (10**(USD_DECIMALS - _exchangeDecimals));

        tokenAmount = (usdAmount_ * 10**USD_DECIMALS) / _usdExchangeRate;

        // Convert token amount to payment token decimals
        tokenAmount = USD_DECIMALS > _tokenDecimals
            ? tokenAmount / 10**(USD_DECIMALS - _tokenDecimals)
            : tokenAmount * 10**(_tokenDecimals - USD_DECIMALS);
        exchangeRate = _usdExchangeRate;
    }

    uint256[18] private __gap;
}
