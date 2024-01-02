//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface PriceOracle {
    function getUnderlyingPrice(address rToken) external view returns (uint256);
}

interface IPriceOracle is PriceOracle {
    function setRTokenToCToken(address rToken, address cToken) external;

    function setOracle(address newOracle) external;

    event SetRTokenToCToken(
        address indexed rToken,
        address oldCToken,
        address newCToken
    );

    event SetUnderlyingPrice(
        address indexed rToken,
        uint256 oldPrice,
        uint256 newPrice
    );

    event SetCTokenOracle(address oldOracle, address newOracle);
}

interface IPriceOracleV2 is IPriceOracle {
    enum OracleType {
        UNKNOW,
        MANUAL,
        COMPOUND,
        CHAINLINK
    }

    function setPriceCeiling(address rToken, uint256 value) external;

    function setRTokenToChainlinkOracle(
        address rToken,
        address newChainlinkOracle,
        uint256 maxTimeDelay
    ) external;

    function setRTokenToManualOracle(
        address rToken,
        address newChainlinkOracle
    ) external;

    function setRTokenToOracleType(
        address rToken,
        OracleType oracleType
    ) external;

    event SetPriceCeiling(
        address indexed rToken,
        uint256 oldPriceCap,
        uint256 newPriceCap
    );

    event SetChainlinkOracle(
        address indexed rToken,
        address oldOracle,
        address newOracle,
        uint256 maxTimeDelay
    );

    event SetManualOracle(
        address indexed rToken,
        address oldOracle,
        address newOracle
    );

    event SetRTokenToOracleType(address indexed rToken, OracleType oracleType);
}
