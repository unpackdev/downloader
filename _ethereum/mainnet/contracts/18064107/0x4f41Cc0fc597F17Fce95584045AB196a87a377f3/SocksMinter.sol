// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "./IStanceRKLCollection.sol";
import "./ISocksMinter.sol";
import "./StanceRKLBoxesCollection.sol";
import "./IERC721.sol";

import "./Bitmaps.sol";
import "./MintGuard.sol";

contract SocksMinter is ISocksMinter, MintGuard {
    using BitMaps for BitMaps.BitMap;

    IERC721 public immutable STANCE_RKL_BOXES_COLLECTION;
    IStanceRKLCollection public immutable STANCE_RKL_COLLECTION;
    uint256[] SOX_TRIPLET = new uint256[](3);
    BitMaps.BitMap boxesThatMinted;

    constructor(address stanceRklCollection, address stanceRklBoxesCollection) {
        admin = msg.sender;
        
        // socks minted with this contract
        STANCE_RKL_COLLECTION = IStanceRKLCollection(stanceRklCollection);
        // these boxes act as keys to mint the above socks
        STANCE_RKL_BOXES_COLLECTION = IERC721(stanceRklBoxesCollection);
        
        // each box mints 3 pairs of socks
        SOX_TRIPLET[0] = 1;
        SOX_TRIPLET[1] = 2;
        SOX_TRIPLET[2] = 3;

        // UTC: Thursday, 7 September 2023 17:00:00, which is 1PM ET
        mintOpenOnTimestamp = 1694106000;
    }

    function checkBoxCanClaim(uint256[] calldata boxIds) public view returns (bool[] memory) {
        bool[] memory boxCanClaim = new bool[](boxIds.length);
        for (uint256 i = 0; i < boxIds.length;) {
            if (boxesThatMinted.get(boxIds[i]) == true) {
                boxCanClaim[i] = false;
            } else {
                boxCanClaim[i] = true;
            }
            unchecked {
                ++i;
            }
        }
        return boxCanClaim;
    }

    function getBoxesThatMinted(uint256 boxId) external view returns (bool) {
        return boxesThatMinted.get(boxId);
    }

    // same logic as checkBoxCanClaim but will revert if a box has already claimed
    function checkBoxCanClaimReverts(uint256[] calldata boxIds) private view {
        for (uint256 i = 0; i < boxIds.length;) {
            if (boxesThatMinted.get(boxIds[i]) == true) {
                revert BoxAlreadyClaimed(boxIds[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function checkCallerOwnerOfBoxes(uint256[] calldata boxIds) private view {
        for (uint256 i = 0; i < boxIds.length;) {
            if (msg.sender != STANCE_RKL_BOXES_COLLECTION.ownerOf(boxIds[i])) {
                revert CallerNotOwner(boxIds[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function mint(uint256[] calldata boxIds) external {
        // if the current timestamp is not after 7th september 2023 17:00:00 UTC
        // the mint will revert
        checkIfMintOpen();
        // if any one of the boxes has already claimed, the mint will revert
        checkBoxCanClaimReverts(boxIds);
        // if the caller is not owner of any one of the boxes, the mint will revert
        checkCallerOwnerOfBoxes(boxIds);
        // once all the checks pass, we can mark these boxes as having minted socks
        boxesThatMinted.batchSet(boxIds);

        uint256[] memory amounts = new uint256[](3);
        uint256 boxIdsLength = boxIds.length;
        // each one box is entitled to every pair of the socks
        // so if boxIds.length = n, then we mint 3 * n pairs of socks
        amounts[0] = boxIdsLength;
        amounts[1] = boxIdsLength;
        amounts[2] = boxIdsLength;

        STANCE_RKL_COLLECTION.mint(msg.sender, SOX_TRIPLET, amounts);
    }
}
