pragma solidity 0.8.19;

import "./BaseFeeIncentive.sol";

abstract contract OSMLike {
    function updateResult() external virtual; // OSM Call

    function read() external view virtual returns (uint256);

    function priceSource() external view virtual returns (OracleLike);

    function getNextResultWithValidity() external view virtual returns (uint256, bool);
}

abstract contract OracleRelayerLike {
    function updateCollateralPrice(bytes32) external virtual; // Oracle relayer call

    function orcl(bytes32) external view virtual returns (address);
}

// @notice: Unobtrusive incentives for any call on a TAI like system.
// @dev: Assumes an allowance from the stability fee treasury, all oracles return quotes with 18 decimal places.
// @dev: Assumes all collateral types use the same OSM
contract BasefeeOSMDeviationCallBundler is BaseFeeIncentive {
    OSMLike public immutable osm;
    OracleRelayerLike public immutable oracleRelayer;
    bytes32 public immutable collateralA;
    bytes32 public immutable collateralB;
    bytes32 public immutable collateralC;

    uint256 public acceptedDeviation; // 1000 = 100%

    // --- Constructor ---
    constructor(
        address treasury_,
        address osm_,
        address oracleRelayer_,
        bytes32[3] memory collateral_,
        uint256 reward_,
        uint256 delay_,
        address coinOracle_,
        address ethOracle_,
        uint256 acceptedDeviation_
    ) BaseFeeIncentive(treasury_, reward_, delay_, coinOracle_, ethOracle_) {
        require(osm_ != address(0), "invalid-osm");
        require(oracleRelayer_ != address(0), "invalid-oracle-relayer");
        require(acceptedDeviation_ < 1000, "invalid-deviation");

        osm = OSMLike(osm_);
        oracleRelayer = OracleRelayerLike(oracleRelayer_);
        acceptedDeviation = acceptedDeviation_;

        collateralA = collateral_[0];
        collateralB = collateral_[1];
        collateralC = collateral_[2];

        emit ModifyParameters("acceptedDeviation", acceptedDeviation_);
    }

    function modifyParameters(bytes32 parameter, uint256 data) public override isAuthorized {
        if (parameter == "acceptedDeviation") {
            require(data < 1000, "invalid-deviation");
            acceptedDeviation = data;
            emit ModifyParameters(parameter, data);
        } else super.modifyParameters(parameter, data);
    }

    // @dev Calls are made through the fallback function
    fallback() external payRewards {
        uint256 currentPrice = osm.read();
        (uint256 nextPrice, ) = osm.getNextResultWithValidity();
        uint256 marketPrice = osm.priceSource().read();

        uint256 deviation = (currentPrice * acceptedDeviation) / 1000;

        // will pay if either current vs nextPrice or current vs marketPrice deviates by more than deviation
        require(
            nextPrice >= currentPrice + deviation ||
            nextPrice <= currentPrice - deviation ||
            marketPrice >= currentPrice + deviation ||
            marketPrice <= currentPrice - deviation,
            "not-enough-deviation"
        );

        osm.updateResult();

        if (collateralA != bytes32(0)) oracleRelayer.updateCollateralPrice(collateralA);
        if (collateralB != bytes32(0)) oracleRelayer.updateCollateralPrice(collateralB);
        if (collateralC != bytes32(0)) oracleRelayer.updateCollateralPrice(collateralC);
    }
}
