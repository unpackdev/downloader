// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ParaVersionedInitializable.sol";
import "./IERC20.sol";
import "./DataTypes.sol";
import "./IPoolAddressesProvider.sol";
import "./IPoolPositionMover.sol";
import "./PoolStorage.sol";
import "./PositionMoverLogic.sol";
import "./ParaReentrancyGuard.sol";
import "./ILendPoolLoan.sol";
import "./ILendPool.sol";
import "./IPool.sol";
import "./ICApe.sol";
import "./ITimeLock.sol";
import "./INToken.sol";
import "./IPToken.sol";
import "./IP2PPairStaking.sol";
import "./IProtocolDataProvider.sol";
import "./Errors.sol";
import "./ReserveConfiguration.sol";
import "./ReserveLogic.sol";
import "./SafeCast.sol";

/**
 * @title Pool PositionMover contract
 *
 **/
contract PoolPositionMover is
    ParaVersionedInitializable,
    ParaReentrancyGuard,
    PoolStorage,
    IPoolPositionMover
{
    IPoolAddressesProvider internal immutable ADDRESSES_PROVIDER;
    ILendPoolLoan internal immutable BENDDAO_LEND_POOL_LOAN;
    ILendPool internal immutable BENDDAO_LEND_POOL;
    IPool internal immutable POOL_V1;
    IProtocolDataProvider internal immutable PROTOCOL_DATA_PROVIDER_V1;
    ICApe internal immutable CAPE_V1;
    ICApe internal immutable CAPE_V2;
    IERC20 internal immutable APE_COIN;
    ITimeLock internal immutable TIME_LOCK_V1;
    IP2PPairStaking internal immutable P2P_PAIR_STAKING_V1;
    uint256 internal constant POOL_REVISION = 200;

    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using ReserveLogic for DataTypes.ReserveData;
    using SafeCast for uint256;

    constructor(
        IPoolAddressesProvider addressProvider,
        ILendPoolLoan benddaoLendPoolLoan,
        ILendPool benddaoLendPool,
        IPool paraspaceV1,
        IProtocolDataProvider protocolDataProviderV1,
        ICApe capeV1,
        ICApe capeV2,
        IERC20 apeCoin,
        ITimeLock timeLockV1,
        IP2PPairStaking p2pPairStakingV1
    ) {
        ADDRESSES_PROVIDER = addressProvider;
        BENDDAO_LEND_POOL_LOAN = benddaoLendPoolLoan;
        BENDDAO_LEND_POOL = benddaoLendPool;
        POOL_V1 = paraspaceV1;
        PROTOCOL_DATA_PROVIDER_V1 = protocolDataProviderV1;
        CAPE_V1 = capeV1;
        CAPE_V2 = capeV2;
        APE_COIN = apeCoin;
        TIME_LOCK_V1 = timeLockV1;
        P2P_PAIR_STAKING_V1 = p2pPairStakingV1;
    }

    function movePositionFromBendDAO(
        uint256[] calldata loanIds,
        address to
    ) external nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        PositionMoverLogic.executeMovePositionFromBendDAO(
            ps,
            ADDRESSES_PROVIDER,
            BENDDAO_LEND_POOL_LOAN,
            BENDDAO_LEND_POOL,
            loanIds,
            to
        );
    }

    function movePositionFromParaSpace(
        DataTypes.ParaSpacePositionMoveInfo calldata moveInfo
    ) external nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();

        PositionMoverLogic.executeMovePositionFromParaSpaceV1(
            ps,
            POOL_V1,
            PROTOCOL_DATA_PROVIDER_V1,
            CAPE_V1,
            CAPE_V2,
            DataTypes.ParaSpacePositionMoveParams({
                user: msg.sender,
                cTokens: moveInfo.cTokens,
                cTypes: moveInfo.cTypes,
                cAmountsOrTokenIds: moveInfo.cAmountsOrTokenIds,
                dTokens: moveInfo.dTokens,
                dAmounts: moveInfo.dAmounts,
                to: moveInfo.to,
                reservesCount: ps._reservesCount,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
            })
        );
    }

    function claimUnderlying(
        address[] calldata assets,
        uint256[][] calldata agreementIds
    ) external nonReentrant {
        require(
            assets.length == agreementIds.length,
            Errors.INCONSISTENT_PARAMS_LENGTH
        );
        DataTypes.PoolStorage storage ps = poolStorage();

        for (uint256 index = 0; index < assets.length; index++) {
            DataTypes.ReserveData storage reserve = ps._reserves[assets[index]];
            DataTypes.ReserveConfigurationMap
                memory reserveConfigurationMap = reserve.configuration;
            (, , , , DataTypes.AssetType assetType) = reserveConfigurationMap
                .getFlags();

            if (assetType == DataTypes.AssetType.ERC20) {
                reserve.unbacked -= IPToken(reserve.xTokenAddress)
                    .claimUnderlying(
                        address(TIME_LOCK_V1),
                        address(CAPE_V1),
                        address(CAPE_V2),
                        address(APE_COIN),
                        agreementIds[index]
                    )
                    .toUint128();
            } else {
                INToken(reserve.xTokenAddress).claimUnderlying(
                    address(TIME_LOCK_V1),
                    agreementIds[index]
                );
            }
        }
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return POOL_REVISION;
    }
}
