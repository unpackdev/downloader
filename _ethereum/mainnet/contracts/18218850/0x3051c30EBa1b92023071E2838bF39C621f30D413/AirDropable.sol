// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./CustomErrors.sol";
import "./BPS.sol";
import "./CustomErrors.sol";
import "./LANFTUtils.sol";
import "./ERC721State.sol";
import "./ERC721LACore.sol";
import "./IAirDropable.sol";
import "./RoyaltiesState.sol";

abstract contract AirDropable is IAirDropable, ERC721LACore {
    uint256 public constant AIRDROP_MAX_BATCH_SIZE = 100;

    function airdrop(
        uint256 editionId,
        address[] calldata recipients,
        uint24 quantityPerAddress
    ) external onlyAdmin {
        if (recipients.length > AIRDROP_MAX_BATCH_SIZE) {
            revert TooManyAddresses();
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(editionId, quantityPerAddress, recipients[i]);
        }
    }
}
