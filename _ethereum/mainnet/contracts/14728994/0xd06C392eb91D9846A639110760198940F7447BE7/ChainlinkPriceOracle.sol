// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./AggregatorV3Interface.sol";
import "./MToken.sol";
import "./PriceOracle.sol";
import "./MToken.sol";
import "./AccessControl.sol";

contract ChainlinkPriceOracle is PriceOracle, AccessControl {
    event NewTokenConfigSet(
        address token,
        address oracleAddress,
        uint8 underlyingTokenDecimals,
        uint8 reporterMultiplier,
        uint32 timestampThreshold
    );

    /// @notice Structure to store oracle related data for the token
    struct TokenConfig {
        // Chainlink oracle interface for current token
        AggregatorV3Interface chainlinkAggregator;
        // Original token decimals
        uint8 underlyingTokenDecimals;
        // Const for price converting
        uint8 reporterMultiplier;
        /// @dev max threshold for oracle validation
        uint32 timestampThreshold;
    }

    /// @dev Mapping to store oracle related configuration for tokens
    mapping(address => TokenConfig) public feedProxies;

    /**
     * @notice Construct a ChainlinkPriceOracle contract.
     * @param admin The address of the Admin
     */
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function pow10(uint8 power) private pure returns (uint256) {
        if (power == 18) return 1e18;
        else if (power == 6) return 1e6;
        else if (power == 8) return 1e8;
        else if (power == 1) return 1e1;
        else if (power == 2) return 1e2;
        else if (power == 3) return 1e3;
        else if (power == 4) return 1e4;
        else if (power == 5) return 1e5;
        else if (power == 7) return 1e7;
        else if (power == 9) return 1e9;
        else if (power == 10) return 1e10;
        else if (power == 11) return 1e11;
        else if (power == 12) return 1e12;
        else if (power == 13) return 1e13;
        else if (power == 14) return 1e14;
        else if (power == 15) return 1e15;
        else if (power == 16) return 1e16;
        else if (power == 17) return 1e17;
        else if (power == 19) return 1e19;
        else if (power == 20) return 1e20;
        else if (power == 21) return 1e21;
        else if (power == 22) return 1e22;
        else if (power == 23) return 1e23;
        else if (power == 24) return 1e24;
        else if (power == 25) return 1e25;
        else return 1e26;
    }

    /**
     * @notice Convert price received from oracle to be scaled by 1e8
     * @param config token config
     * @param reportedPrice raw oracle price
     * @return price scaled by 1e8
     */
    function convertReportedPrice(TokenConfig memory config, int256 reportedPrice) internal pure returns (uint256) {
        require(reportedPrice > 0, ErrorCodes.REPORTED_PRICE_SHOULD_BE_GREATER_THAN_ZERO);
        uint256 unsignedPrice = uint256(reportedPrice);
        uint256 convertedPrice = (unsignedPrice * pow10(config.reporterMultiplier)) /
            pow10(config.underlyingTokenDecimals);
        return convertedPrice;
    }

    /**
     * @notice Get the underlying price of a mToken asset
     * @param mToken The mToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     *
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getUnderlyingPrice(MToken mToken) external view override returns (uint256) {
        require(address(mToken) != address(0), ErrorCodes.MTOKEN_ADDRESS_CANNOT_BE_ZERO);
        return getAssetPrice(address(mToken.underlying()));
    }

    /**
     * @notice Return price for an asset
     * @param asset address of token
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getAssetPrice(address asset) public view returns (uint256) {
        require(asset != address(0), ErrorCodes.TOKEN_ADDRESS_CANNOT_BE_ZERO);

        TokenConfig memory config = feedProxies[asset];
        require(config.chainlinkAggregator != AggregatorV3Interface(address(0)), ErrorCodes.TOKEN_NOT_FOUND);

        // prettier-ignore
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = config.chainlinkAggregator.latestRoundData();

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp - updatedAt <= config.timestampThreshold, ErrorCodes.ORACLE_PRICE_EXPIRED);
        require(answeredInRound == roundId, ErrorCodes.RECEIVED_PRICE_HAS_INVALID_ROUND);

        uint256 convertedPrice = convertReportedPrice(config, answer);

        return (convertedPrice * 1e28) / pow10(config.underlyingTokenDecimals);
    }

    /**
     * @notice Set the proxy of a underlying asset
     * @param token The underlying to set the price oracle proxy of
     * @param oracleAddress Address of corresponding oracle
     * @param underlyingTokenDecimals Original token decimals
     * @param reporterMultiplier Constant, using for decimal cast from decimals,
                                  returned by oracle to required decimals.
     * @param timestampThreshold  max threshold for oracle validation
     * @dev reporterMultiplier = 8 + underlyingDecimals - feedDecimals
     */
    function setTokenConfig(
        address token,
        address oracleAddress,
        uint8 underlyingTokenDecimals,
        uint8 reporterMultiplier,
        uint32 timestampThreshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != address(0), ErrorCodes.TOKEN_ADDRESS_CANNOT_BE_ZERO);
        require(oracleAddress != address(0), ErrorCodes.OR_ORACLE_ADDRESS_CANNOT_BE_ZERO);
        require(underlyingTokenDecimals > 0, ErrorCodes.OR_UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO);
        require(reporterMultiplier > 0, ErrorCodes.OR_REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO);
        require(underlyingTokenDecimals < 27, ErrorCodes.OR_UNDERLYING_TOKENS_DECIMALS_TOO_BIG);
        require(reporterMultiplier < 27, ErrorCodes.OR_REPORTER_MULTIPLIER_TOO_BIG);
        require(timestampThreshold > 0, ErrorCodes.OR_TIMESTAMP_THRESHOLD_SHOULD_BE_GREATER_THAN_ZERO);

        feedProxies[token] = TokenConfig(
            AggregatorV3Interface(oracleAddress),
            underlyingTokenDecimals,
            reporterMultiplier,
            timestampThreshold
        );
        emit NewTokenConfigSet(token, oracleAddress, underlyingTokenDecimals, reporterMultiplier, timestampThreshold);
    }
}
