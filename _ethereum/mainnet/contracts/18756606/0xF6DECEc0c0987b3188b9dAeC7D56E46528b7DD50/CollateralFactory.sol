// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity 0.6.7;

abstract contract FactoryLike {
    function deploy(
        address,
        bytes32,
        address,
        address
    ) external virtual returns (address);

    function deploy(address, address) external virtual returns (address);

    function deploy(
        address,
        address,
        bytes32,
        address
    ) external virtual returns (address);

    function deploy(
        address,
        address,
        address,
        bytes32[3] calldata,
        uint256,
        uint256,
        address,
        address,
        uint256,
        address
    ) external virtual returns (address);
}

abstract contract Setter {
    function collateralType() external view virtual returns (bytes32);

    function addAuthorization(address) external virtual;

    function modifyParameters(bytes32, address) external virtual;

    function modifyParameters(bytes32, uint256) external virtual;

    function modifyParameters(bytes32, bytes32, address) external virtual;

    function modifyParameters(bytes32, bytes32, uint256) external virtual;

    function initializeCollateralType(bytes32) external virtual;

    function updateCollateralPrice(bytes32) external virtual;

    function setPerBlockAllowance(address, uint) external virtual;

    function setTotalAllowance(address, uint) external virtual;
}

// @dev This is just a proxy action, meant to be used by a GEB system and called through DS-Pause (it assumes the caller, DS-Proxy, owns all contracts it touches)
// @dev Direct calls to this contract will revert.
contract CollateralFactory {
    address public immutable pauseProxy;
    Setter public immutable safeEngine;
    Setter public immutable taxCollector;
    Setter public immutable liquidationEngine;
    Setter public immutable oracleRelayer;
    Setter public immutable globalSettlement;
    Setter public immutable stabilityFeeTreasury;
    FactoryLike public immutable osmFactory;
    FactoryLike public immutable joinFactory;
    FactoryLike public immutable auctionHouseFactory;
    FactoryLike public immutable keeperIncentivesFactory;

    event contractDeployed(string, address);

    constructor(
        address pauseProxy_,
        address safeEngine_,
        address liquidationEngine_,
        address oracleRelayer_,
        address globalSettlement_,
        address taxCollector_,
        address stabilityFeeTreasury_,
        address osmFactory_,
        address joinFactory_,
        address auctionHouseFactory_,
        address keeperIncentivesFactory_
    ) public {
        pauseProxy = pauseProxy_;
        safeEngine = Setter(safeEngine_);
        liquidationEngine = Setter(liquidationEngine_);
        oracleRelayer = Setter(oracleRelayer_);
        globalSettlement = Setter(globalSettlement_);
        taxCollector = Setter(taxCollector_);
        stabilityFeeTreasury = Setter(stabilityFeeTreasury_);
        osmFactory = FactoryLike(osmFactory_);
        joinFactory = FactoryLike(joinFactory_);
        auctionHouseFactory = FactoryLike(auctionHouseFactory_);
        keeperIncentivesFactory = FactoryLike(keeperIncentivesFactory_);
    }

    function deployJoin(
        bytes32 collateralType,
        address token
    ) internal returns (address) {
        return
            joinFactory.deploy(
                address(safeEngine),
                collateralType,
                token,
                pauseProxy
            );
    }

    function deployAuctionHouse(
        bytes32 collateralType
    ) internal returns (address) {
        return
            auctionHouseFactory.deploy(
                address(safeEngine),
                address(liquidationEngine),
                collateralType,
                pauseProxy
            );
    }

    function deployOSM(address priceFeed) internal returns (address) {
        return osmFactory.deploy(priceFeed, pauseProxy);
    }

    function deployKeeperIncentives(
        address osm,
        bytes32 collateralType,
        address coinOracle,
        address ethOracle,
        uint256 acceptedDeviation
    ) internal returns (address) {
        return
            keeperIncentivesFactory.deploy(
                address(stabilityFeeTreasury),
                osm,
                address(oracleRelayer),
                [collateralType, bytes32(0), bytes32(0)],
                5 * 10 ** 18,
                0,
                coinOracle,
                ethOracle,
                acceptedDeviation,
                pauseProxy
            );
    }

    // notice: this function can be called by anyone, it will deploy a set of contracts needed for a new collateral (no impact on the system until they are attached)
    function deployCollateralSpecificContracts(
        bytes32 collateralType,
        address token,
        address priceFeed,
        address coinOracle,
        address ethOracle,
        uint256 acceptedDeviation
    )
        external
        returns (
            address join,
            address auctionHouse,
            address osm,
            address keeperIncentives
        )
    {
        join = deployJoin(collateralType, token);
        emit contractDeployed("JOIN", join);

        auctionHouse = deployAuctionHouse(collateralType);
        emit contractDeployed("AUCTION_HOUSE", auctionHouse);

        osm = deployOSM(priceFeed);
        emit contractDeployed("OSM", osm);

        keeperIncentives = deployKeeperIncentives(
            osm,
            collateralType,
            coinOracle,
            ethOracle,
            acceptedDeviation
        );
        emit contractDeployed("KEEPER_INCENTIVES", keeperIncentives);
    }

    // notice: this function should be called by ds-pause, passing the addresses of the collateral specific contracts previously deployed
    // calling it direclty will fail, it should be delegatecalled into by ds-pause
    function deployCollateralType(
        address joinAddress,
        address osmAddress,
        address auctionHouseAddress,
        address keeperIncentivesAddress,
        uint256 cRatio,
        uint256 debtCeiling,
        uint256 debtFloor,
        uint256 stabilityFee,
        uint256 liquidationPenalty
    ) external {
        Setter join = Setter(joinAddress);
        Setter auctionHouse = Setter(auctionHouseAddress);

        bytes32 collateralType = auctionHouse.collateralType();

        safeEngine.addAuthorization(address(join));

        liquidationEngine.modifyParameters(
            collateralType,
            "collateralAuctionHouse",
            address(auctionHouse)
        );
        liquidationEngine.modifyParameters(
            collateralType,
            "liquidationPenalty",
            liquidationPenalty
        );
        liquidationEngine.modifyParameters(
            collateralType,
            "liquidationQuantity",
            uint256(-1)
        );

        liquidationEngine.addAuthorization(address(auctionHouse));
        auctionHouse.addAuthorization(address(liquidationEngine));
        auctionHouse.addAuthorization(address(globalSettlement));

        oracleRelayer.modifyParameters(collateralType, "orcl", osmAddress);
        oracleRelayer.modifyParameters(collateralType, "safetyCRatio", cRatio);
        oracleRelayer.modifyParameters(
            collateralType,
            "liquidationCRatio",
            cRatio
        );

        safeEngine.initializeCollateralType(collateralType);
        safeEngine.modifyParameters(collateralType, "debtCeiling", debtCeiling);
        safeEngine.modifyParameters(collateralType, "debtFloor", debtFloor);

        taxCollector.initializeCollateralType(collateralType);
        taxCollector.modifyParameters(
            collateralType,
            "stabilityFee",
            stabilityFee
        );

        auctionHouse.modifyParameters("oracleRelayer", address(oracleRelayer));
        auctionHouse.modifyParameters("collateralFSM", osmAddress);
        auctionHouse.modifyParameters("minimumBid", 0);
        auctionHouse.modifyParameters(
            "perSecondDiscountUpdateRate",
            999999410259856537771597932
        );
        auctionHouse.modifyParameters("minDiscount", 0.99E18);
        auctionHouse.modifyParameters("maxDiscount", 0.70E18);
        auctionHouse.modifyParameters("maxDiscountUpdateRateTimeline", 7 days);
        auctionHouse.modifyParameters(
            "lowerCollateralMedianDeviation",
            0.70E18
        );
        auctionHouse.modifyParameters(
            "upperCollateralMedianDeviation",
            0.90E18
        );

        oracleRelayer.updateCollateralPrice(collateralType);

        stabilityFeeTreasury.setPerBlockAllowance(
            keeperIncentivesAddress,
            100 * 10 ** 18
        );
        stabilityFeeTreasury.setTotalAllowance(
            keeperIncentivesAddress,
            uint(-1)
        );
    }
}
