//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IPToken.sol";
import "./IUnipool.sol";
import "./IGaugeDeposit.sol";
import "./IDepositer.sol";
import "./IMetapool.sol";
import "./IIdleCDO.sol";

contract PbtcV1StrategiesMigrator is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    address public constant PBTCV1 = 0x5228a22e72ccC52d415EcFd199F99D0665E7733b;
    address public constant PBTCV2 = 0x62199B909FB8B8cf870f97BEf2cE6783493c4908;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant PNT = 0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD;
    address public constant RENBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant SBTC = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;
    address public constant OLD_PBTC_SBTC_CRV_GAUGE_DEPOSIT = 0xd7d147c6Bb90A718c3De8C0568F9B560C79fa416;
    address public constant OLD_PBTC_SBTC_CRV_LP_TOKEN = 0xDE5331AC4B3630f94853Ff322B66407e0D6331E8;
    address public constant OLD_DEPOSIT_PBTC = 0x11F419AdAbbFF8d595E7d5b223eee3863Bb3902C;
    address public constant NEW_PBTC_SBTC_CRV_LP_TOKEN = 0xC9467E453620f16b57a34a770C6bceBECe002587;
    address public constant NEW_PBTC_SBTC_CRV_GAUGE_DEPOSIT = 0xB5efA93d5D23642f970aF41a1ea9A26f19CbD2Eb;
    address public constant IDLE_CDO = 0xf324Dca1Dc621FCF118690a9c6baE40fbD8f09b7;
    address public constant IDLE_CDO_AA_TRANCHE_CVX_PBTC_SBTC_CRV = 0x4657B96D587c4d46666C244B40216BEeEA437D0d;
    address public constant IDLE_CDO_BB_TRANCHE_CVX_PBTC_SBTC_CRV = 0x3872418402d1e967889aC609731fc9E11f438De5;
    address public constant IDLE_AA_CVX_PBTC_SBTC_CRV_GAUGE_DEPOSIT = 0x2bEa05307b42707Be6cCE7a16d700a06fF93a29d;
    address public constant CRV_RENBTC_WBTC_SBTC = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    address public constant CRV_RENBTC_WBTC_SBTC_BASE_POOL = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
    address public constant MIGRATOR = 0xc612b19fD761e5Ff780b3C38996ff816AFa26aae;

    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @notice Unstake pBTC/sbtcCRV from gauge and collecting rewards (PNT & CRV) for the msg.sender,
     *         migrate pBTC V1 into pBTC V2, put pBTC V2 into curve metapool and put new pbtc/sbtcCRV-f
     *         into the new pbtc/sbtcCRV gauge.
     *
     * @param _amount amount to migrate
     *
     */
    function migrateIntoNewCurveGaugeFromOldCurveGauge(uint256 _amount) external {
        (uint256 pbtcV1Amount, uint256 crvRenBtcWbtcSbtcAmount) = _migrateFromOldUnipoolAndMigratePbtcV1(_amount, msg.sender);
        uint256 pBTCV2SbtcAmount = _depositPbtcV2AndCrvRenBtcWbtcSbtcIntoNewCurveMetapool(pbtcV1Amount, crvRenBtcWbtcSbtcAmount);
        _depositPbtcV2SbtcCrvIntoNewCurveGauge(pBTCV2SbtcAmount, msg.sender);
    }

    /**
     * @notice Unstake pBTC/sbtcCRV from gauge and collecting rewards (PNT & CRV) for the msg.sender,
     *         migrate pBTC V1 into pBTC V2, put pBTC V2 into curve metapool, deposit pbtc/sbtcCRV-f
     *         on Idle CDO, get AA tranche tokens (IdleCDO AA Tranche - idleCvxpbtc/sbtcCRV-f), deposit them
     *         into Idle Gauge and send AA_idleCvxpbtc/sbtcCRV-f Gauge Deposit to msg.sender
     *
     * @param _amount amount to migrate
     *
     */
    function migrateIntoIdleAATrancheFromOldCurveGauge(uint256 _amount) external {
        (uint256 pbtcV1Amount, uint256 crvRenBtcWbtcSbtcAmount) = _migrateFromOldUnipoolAndMigratePbtcV1(_amount, msg.sender);
        uint256 pBTCV2SbtcAmount = _depositPbtcV2AndCrvRenBtcWbtcSbtcIntoNewCurveMetapool(pbtcV1Amount, crvRenBtcWbtcSbtcAmount);
        _depositPbtcV2SbtcCrvIntoIdleAATranche(pBTCV2SbtcAmount, msg.sender);
    }

    /**
     * @notice Unstake pBTC/sbtcCRV from gauge and collecting rewards (PNT & CRV) for the msg.sender,
     *         migrate pBTC V1 into pBTC V2, put pBTC V2 into curve metapool, deposit pbtc/sbtcCRV-f
     *         on Idle CDO, get BB tranche tokens (IdleCDO AA Tranche - idleCvxpbtc/sbtcCRV-f) and
     *         send them to the msg.sender
     *
     * @param _amount amount to migrate
     *
     */
    function migrateIntoIdleBBTrancheFromOldCurveGauge(uint256 _amount) external {
        (uint256 pbtcV1Amount, uint256 crvRenBtcWbtcSbtcAmount) = _migrateFromOldUnipoolAndMigratePbtcV1(_amount, msg.sender);
        uint256 pBTCV2SbtcAmount = _depositPbtcV2AndCrvRenBtcWbtcSbtcIntoNewCurveMetapool(pbtcV1Amount, crvRenBtcWbtcSbtcAmount);
        _depositPbtcV2SbtcCrvIntoIdleBBTranche(pBTCV2SbtcAmount, msg.sender);
    }

    function _depositPbtcV2AndCrvRenBtcWbtcSbtcIntoNewCurveMetapool(uint256 _pbtcV2Amount, uint256 _crvRenBtcWbtcSbtcAmount)
        internal
        returns (uint256)
    {
        IERC20(PBTCV2).approve(NEW_PBTC_SBTC_CRV_LP_TOKEN, _pbtcV2Amount);
        IERC20(CRV_RENBTC_WBTC_SBTC).approve(NEW_PBTC_SBTC_CRV_LP_TOKEN, _crvRenBtcWbtcSbtcAmount);
        return IMetapool(NEW_PBTC_SBTC_CRV_LP_TOKEN).add_liquidity([_pbtcV2Amount, _crvRenBtcWbtcSbtcAmount], 0);
    }

    function _depositPbtcV2SbtcCrvIntoNewCurveGauge(uint256 _amount, address _owner) internal {
        // deposit pool tokens into the gauge
        IERC20(NEW_PBTC_SBTC_CRV_LP_TOKEN).approve(NEW_PBTC_SBTC_CRV_GAUGE_DEPOSIT, _amount);
        IGaugeDeposit(NEW_PBTC_SBTC_CRV_GAUGE_DEPOSIT).deposit(_amount);

        // send to the msg.sender te gauge tokens
        uint256 pBTCV2sbtcCRVGaugeAmount = IGaugeDeposit(NEW_PBTC_SBTC_CRV_GAUGE_DEPOSIT).balanceOf(address(this));
        IGaugeDeposit(NEW_PBTC_SBTC_CRV_GAUGE_DEPOSIT).transfer(_owner, pBTCV2sbtcCRVGaugeAmount);
    }

    function _depositPbtcV2SbtcCrvIntoIdleAATranche(uint256 _amount, address _owner) internal {
        // deposit  pbtc/sbtcCRV-f into Idle tranche
        IERC20(NEW_PBTC_SBTC_CRV_LP_TOKEN).approve(IDLE_CDO, _amount);
        uint256 trancheTokensAmount = IIdleCDO(IDLE_CDO).depositAA(_amount);

        // deposit IdleCDO AA Tranche - idleCvxpbtc/sbtcCRV-f into Idle Gauge
        IERC20(IDLE_CDO_AA_TRANCHE_CVX_PBTC_SBTC_CRV).approve(IDLE_AA_CVX_PBTC_SBTC_CRV_GAUGE_DEPOSIT, trancheTokensAmount);
        IGaugeDeposit(IDLE_AA_CVX_PBTC_SBTC_CRV_GAUGE_DEPOSIT).deposit(trancheTokensAmount);

        // send AA_idleCvxpbtc/sbtcCRV-f Gauge Deposit to _owner
        IERC20(IDLE_AA_CVX_PBTC_SBTC_CRV_GAUGE_DEPOSIT).transfer(_owner, _amount);
    }

    function _depositPbtcV2SbtcCrvIntoIdleBBTranche(uint256 _amount, address _owner) internal {
        // deposit  pbtc/sbtcCRV-f into Idle tranche
        IERC20(NEW_PBTC_SBTC_CRV_LP_TOKEN).approve(IDLE_CDO, _amount);
        uint256 trancheTokensAmount = IIdleCDO(IDLE_CDO).depositBB(_amount);

        // send IdleCDO BB Tranche - idleCvxpbtc/sbtcCRV-f to the _owner
        IERC20(IDLE_CDO_BB_TRANCHE_CVX_PBTC_SBTC_CRV).transfer(_owner, trancheTokensAmount);
    }

    function _migrateFromOldUnipoolAndMigratePbtcV1(uint256 _amount, address _owner) internal returns (uint256, uint256) {
        _removePbtcV1FromUnipoolAndCollectRewards(_amount, _owner);
        (uint256 pbtcV1Amount, uint256 crvRenBtcWbtcSbtcAmount) = _removePbtcV1SbtcCrvFromOldMetapool();
        IERC20(PBTCV1).transfer(MIGRATOR, pbtcV1Amount);
        return (pbtcV1Amount, crvRenBtcWbtcSbtcAmount);
    }

    function _removePbtcV1FromUnipoolAndCollectRewards(uint256 _amount, address _owner) internal returns (uint256, uint256) {
        IGaugeDeposit(OLD_PBTC_SBTC_CRV_GAUGE_DEPOSIT).transferFrom(_owner, address(this), _amount);

        // collect CRV and PNT and send them to the msg.sender
        IGaugeDeposit(OLD_PBTC_SBTC_CRV_GAUGE_DEPOSIT).withdraw(_amount);
        IERC20(CRV).transfer(_owner, IERC20(CRV).balanceOf(address(this)));
        IERC20(PNT).transfer(_owner, IERC20(PNT).balanceOf(address(this)));
    }

    function _removePbtcV1SbtcCrvFromOldMetapool() internal returns (uint256, uint256) {
        // remove liquidity from pBTC/sBTC Metapool in order to get back pBTC and base coins
        uint256 pBTCV1sbtcCRVAmount = IERC20(OLD_PBTC_SBTC_CRV_LP_TOKEN).balanceOf(address(this));

        IERC20(OLD_PBTC_SBTC_CRV_LP_TOKEN).approve(address(OLD_DEPOSIT_PBTC), pBTCV1sbtcCRVAmount);
        (uint256 pbtcV1Amount, uint256 renBtcAmount, uint256 wBtcAmount, uint256 sBtcAmount) = IDepositer(OLD_DEPOSIT_PBTC).remove_liquidity(
            pBTCV1sbtcCRVAmount,
            [uint256(0), uint256(0), uint256(0), uint256(0)]
        );

        // deposit base coins into the base pool
        IERC20(RENBTC).approve(CRV_RENBTC_WBTC_SBTC_BASE_POOL, renBtcAmount);
        IERC20(WBTC).approve(CRV_RENBTC_WBTC_SBTC_BASE_POOL, wBtcAmount);
        IERC20(SBTC).approve(CRV_RENBTC_WBTC_SBTC_BASE_POOL, sBtcAmount);
        IDepositer(CRV_RENBTC_WBTC_SBTC_BASE_POOL).add_liquidity([renBtcAmount, wBtcAmount, sBtcAmount], 0);
        uint256 crvRenBtcWbtcSbtcAmount = IERC20(CRV_RENBTC_WBTC_SBTC).balanceOf(address(this));
        return (pbtcV1Amount, crvRenBtcWbtcSbtcAmount);
    }

    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}
}
