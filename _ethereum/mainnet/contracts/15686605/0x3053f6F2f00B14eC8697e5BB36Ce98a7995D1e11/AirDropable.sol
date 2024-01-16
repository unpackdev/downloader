// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./CustomErrors.sol";
import "./BPS.sol";
import "./ERC721Mintable.sol";
import "./CustomErrors.sol";
import "./LANFTUtils.sol";
import "./ERC721State.sol";
import "./IAirDropable.sol";
import "./AccessControl.sol";
import "./RoyaltiesState.sol";

abstract contract AirDropable is IAirDropable, AccessControl, ERC721Mintable {
    uint256 public constant AIRDROP_MAX_BATCH_SIZE = 100;
    
    function airdrop(uint256 editionId, address[] calldata recipients, uint24 quantityPerAddres) external onlyAdmin {
        if (recipients.length > AIRDROP_MAX_BATCH_SIZE) {
            revert TooManyAddresses();
        }

        for (uint i=0; i<recipients.length; i++) {
            _safeMint(editionId, quantityPerAddres, recipients[i]);
        }
    }
}
