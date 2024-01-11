// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./IERC721.sol";
import "./IFlashClaimReceiver.sol";
import "./INToken.sol";
import "./DataTypes.sol";
import "./Errors.sol";
import "./ValidationLogic.sol";

library FlashClaimLogic {
    // See `IPool` for descriptions
    event FlashClaim(
        address indexed target,
        address indexed initiator,
        address indexed nftAsset,
        uint256 tokenId
    );

    function executeFlashClaim(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.ExecuteFlashClaimParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.nftAsset];
        ValidationLogic.validateFlashClaim(reserve, params);

        uint256 i;
        // step 1: moving underlying asset forward to receiver contract
        for (i = 0; i < params.nftTokenIds.length; i++) {
            INToken(reserve.xTokenAddress).transferUnderlyingTo(
                params.receiverAddress,
                params.nftTokenIds[i]
            );
        }

        // step 2: execute receiver contract, doing something like airdrop
        require(
            IFlashClaimReceiver(params.receiverAddress).executeOperation(
                params.nftAsset,
                params.nftTokenIds,
                params.params
            ),
            Errors.INVALID_FLASH_CLAIM_RECEIVER
        );

        // step 3: moving underlying asset backward from receiver contract
        for (i = 0; i < params.nftTokenIds.length; i++) {
            IERC721(params.nftAsset).safeTransferFrom(
                params.receiverAddress,
                reserve.xTokenAddress,
                params.nftTokenIds[i]
            );

            emit FlashClaim(
                params.receiverAddress,
                msg.sender,
                params.nftAsset,
                params.nftTokenIds[i]
            );
        }
    }
}
