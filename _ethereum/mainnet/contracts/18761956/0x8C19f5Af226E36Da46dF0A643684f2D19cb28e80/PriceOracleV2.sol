// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Ownable.sol";
import "./IPriceOracleV2.sol";
import "./AggregatorV3Interface.sol";

interface CTokenOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

interface CTokenLike {
    function underlying() external view returns (address);
}

interface IERC20Like {
    function decimals() external view returns (uint8);
}

contract PriceOracleV2 is IPriceOracleV2, Ownable {
    bool public constant isPriceOracle = true;
    CTokenOracle public cTokenOracle =
        CTokenOracle(0x50ce56A3239671Ab62f185704Caedf626352741e);

    mapping(address => OracleType) public rTokenToOracleType;
    mapping(address => address) public rTokenToCToken;

    struct ChainlinkOracleInfo {
        AggregatorV3Interface oracle;
        uint256 scaleFactor;
        uint256 maxTimeDelay;
    }

    mapping(address => ChainlinkOracleInfo) public rTokenToChainlinkOracle;

    struct ManualOracleInfo {
        AggregatorV3Interface oracle;
        uint256 scaleFactor;
    }

    mapping(address => ManualOracleInfo) public rTokenToManualOracle;
    mapping(address => uint256) public rTokenToUnderlyingPriceCap;

    uint internal constant lowerTimeDelay = 43200; // 12 hours
    uint internal constant upperTimeDelay = 172800; // 48 hours

    function getUnderlyingPrice(
        address rToken
    ) external view override returns (uint256) {
        uint256 price;

        OracleType oracleType = rTokenToOracleType[rToken];
        if (oracleType == OracleType.MANUAL) {
            price = getManualOraclePrice(rToken);
        } else if (oracleType == OracleType.COMPOUND) {
            address cTokenAddress = rTokenToCToken[rToken];
            price = cTokenOracle.getUnderlyingPrice(cTokenAddress);
        } else if (oracleType == OracleType.CHAINLINK) {
            price = getChainlinkOraclePrice(rToken);
        } else {
            revert("Oracle type not supported");
        }

        if (rTokenToUnderlyingPriceCap[rToken] > 0) {
            price = _min(price, rTokenToUnderlyingPriceCap[rToken]);
        }

        return price;
    }

    function setPriceCeiling(
        address rToken,
        uint256 value
    ) external override onlyOwner {
        uint256 oldPriceCap = rTokenToUnderlyingPriceCap[rToken];
        rTokenToUnderlyingPriceCap[rToken] = value;
        emit SetPriceCeiling(rToken, oldPriceCap, value);
    }

    function setRTokenToOracleType(
        address rToken,
        OracleType oracleType
    ) external override onlyOwner {
        rTokenToOracleType[rToken] = oracleType;
        emit SetRTokenToOracleType(rToken, oracleType);
    }

    function setRTokenToManualOracle(
        address rToken,
        address newManualOracle
    ) external override onlyOwner {
        address oldManualOracle = address(rTokenToManualOracle[rToken].oracle);

        _setRTokenToManualOracle(rToken, newManualOracle);
        emit SetManualOracle(rToken, oldManualOracle, newManualOracle);
    }

    function _setRTokenToManualOracle(
        address rToken,
        address manualOracle
    ) internal {
        require(
            rTokenToOracleType[rToken] == OracleType.MANUAL,
            "OracleType must be Manual"
        );
        address underlying = CTokenLike(rToken).underlying();
        rTokenToManualOracle[rToken].scaleFactor = (10 **
            (36 -
                uint256(IERC20Like(underlying).decimals()) -
                uint256(AggregatorV3Interface(manualOracle).decimals())));
        rTokenToManualOracle[rToken].oracle = AggregatorV3Interface(
            manualOracle
        );
    }

    function setOracle(address newOracle) external override onlyOwner {
        address oldOracle = address(cTokenOracle);
        cTokenOracle = CTokenOracle(newOracle);
        emit SetCTokenOracle(oldOracle, newOracle);
    }

    function setRTokenToCToken(
        address rToken,
        address cToken
    ) external override onlyOwner {
        address oldCToken = rTokenToCToken[rToken];
        _setRTokenToCToken(rToken, cToken);
        emit SetRTokenToCToken(rToken, oldCToken, cToken);
    }

    function _setRTokenToCToken(address rToken, address cToken) internal {
        require(
            rTokenToOracleType[rToken] == OracleType.COMPOUND,
            "OracleType must be Compound"
        );
        require(
            CTokenLike(rToken).underlying() == CTokenLike(cToken).underlying(),
            "cToken and rToken must have the same underlying asset"
        );
        rTokenToCToken[rToken] = cToken;
    }

    function getManualOraclePrice(
        address rToken
    ) public view returns (uint256) {
        require(
            rTokenToOracleType[rToken] == OracleType.MANUAL,
            "rToken is not configured for Manual oracle"
        );
        ManualOracleInfo storage manualInfo = rTokenToManualOracle[rToken];
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = manualInfo.oracle.latestRoundData();
        require(answeredInRound >= roundId);
        require(answer >= 0, "Price cannot be negative");
        return uint256(answer) * manualInfo.scaleFactor;
    }

    function setRTokenToChainlinkOracle(
        address rToken,
        address newChainlinkOracle,
        uint256 maxTimeDelay
    ) external override onlyOwner {
		require(
		    maxTimeDelay >= lowerTimeDelay && maxTimeDelay <= upperTimeDelay,
		    "maxTimeDelay must be within bounds"
		);
        address oldChainlinkOracle = address(
            rTokenToChainlinkOracle[rToken].oracle
        );
        _setRTokenToChainlinkOracle(rToken, newChainlinkOracle, maxTimeDelay);
        emit SetChainlinkOracle(
            rToken,
            oldChainlinkOracle,
            newChainlinkOracle,
            maxTimeDelay
        );
    }

    function _setRTokenToChainlinkOracle(
        address rToken,
        address chainlinkOracle,
        uint256 maxTimeDelay
    ) internal {
        require(
            rTokenToOracleType[rToken] == OracleType.CHAINLINK,
            "OracleType must be Chainlink"
        );
        address underlying = CTokenLike(rToken).underlying();
        rTokenToChainlinkOracle[rToken].scaleFactor = (10 **
            (36 -
                uint256(IERC20Like(underlying).decimals()) -
                uint256(AggregatorV3Interface(chainlinkOracle).decimals())));
        rTokenToChainlinkOracle[rToken].oracle = AggregatorV3Interface(
            chainlinkOracle
        );
        rTokenToChainlinkOracle[rToken].maxTimeDelay = maxTimeDelay;
    }

    function getChainlinkOraclePrice(
        address rToken
    ) public view returns (uint256) {
        require(
            rTokenToOracleType[rToken] == OracleType.CHAINLINK,
            "rToken is not configured for Chainlink oracle"
        );
        ChainlinkOracleInfo storage chainlinkInfo = rTokenToChainlinkOracle[
            rToken
        ];
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = chainlinkInfo.oracle.latestRoundData();
        require(answeredInRound >= roundId);
        require(answer >= 0, "Price cannot be negative");
        require(
            updatedAt >= block.timestamp - chainlinkInfo.maxTimeDelay,
            "Chainlink price data is stale"
        );
        return uint256(answer) * chainlinkInfo.scaleFactor;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
