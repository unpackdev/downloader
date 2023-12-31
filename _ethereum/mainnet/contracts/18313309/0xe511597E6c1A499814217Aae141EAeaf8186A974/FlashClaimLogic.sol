// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IFlashClaimReceiver.sol";
import "./INToken.sol";
import "./DataTypes.sol";
import "./Errors.sol";
import "./ValidationLogic.sol";
import "./INTokenApeStaking.sol";
import "./IXTokenType.sol";
import "./GenericLogic.sol";
import "./ReserveConfiguration.sol";

library FlashClaimLogic {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    // See `IPool` for descriptions
    event FlashClaim(
        address indexed target,
        address indexed initiator,
        address indexed nftAsset,
        uint256 tokenId
    );

    /**
     * @notice Implements the executeFlashClaim feature.
     * @param ps The state of pool storage
     * @param params The additional parameters needed to execute the flash claim
     */
    function executeFlashClaim(
        DataTypes.PoolStorage storage ps,
        DataTypes.ExecuteFlashClaimParams memory params
    ) external {
        require(
            params.receiverAddress != address(0),
            Errors.ZERO_ADDRESS_NOT_VALID
        );
        address[] memory nTokenAddresses = new address[](
            params.nftAssets.length
        );

        uint256 index;
        uint256 i;
        // no time lock needed here
        DataTypes.TimeLockParams memory timeLockParams;

        for (index = 0; index < params.nftAssets.length; index++) {
            DataTypes.ReserveData storage reserve = ps._reserves[
                params.nftAssets[index]
            ];
            nTokenAddresses[index] = reserve.xTokenAddress;

            ValidationLogic.validateFlashClaim(
                ps,
                nTokenAddresses[index],
                reserve.configuration.getAssetType(),
                params.nftTokenIds[index]
            );

            // step 1: moving underlying asset forward to receiver contract
            for (i = 0; i < params.nftTokenIds[index].length; i++) {
                INToken(nTokenAddresses[index]).transferUnderlyingTo(
                    params.receiverAddress,
                    params.nftTokenIds[index][i],
                    timeLockParams
                );
            }
        }

        // step 2: execute receiver contract, doing something like airdrop
        require(
            IFlashClaimReceiver(params.receiverAddress).executeOperation(
                params.nftAssets,
                params.nftTokenIds,
                msg.sender,
                params.params
            ),
            Errors.INVALID_FLASH_CLAIM_RECEIVER
        );

        for (index = 0; index < params.nftAssets.length; index++) {
            // step 3: moving underlying asset backward from receiver contract
            for (i = 0; i < params.nftTokenIds[index].length; i++) {
                IERC721(params.nftAssets[index]).safeTransferFrom(
                    params.receiverAddress,
                    nTokenAddresses[index],
                    params.nftTokenIds[index][i]
                );

                emit FlashClaim(
                    params.receiverAddress,
                    msg.sender,
                    params.nftAssets[index],
                    params.nftTokenIds[index][i]
                );
            }
        }

        // step 4: check hf
        DataTypes.CalculateUserAccountDataParams
            memory accountParams = DataTypes.CalculateUserAccountDataParams({
                userConfig: ps._usersConfig[msg.sender],
                reservesCount: ps._reservesCount,
                user: msg.sender,
                oracle: params.oracle
            });

        (, , , , , , , uint256 healthFactor, , ) = GenericLogic
            .calculateUserAccountData(
                ps._reserves,
                ps._reservesList,
                accountParams
            );
        require(
            healthFactor > DataTypes.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );
    }
}
