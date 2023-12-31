// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IERC721Upgradeable.sol";
import "./IAccount.sol";
import "./UniqueCheckingUpgradeable.sol";
import "./Types.sol";
import "./Bytes32Address.sol";

//         = 96      + 160
// claimId = tokenId + address
abstract contract ClaimGoodUpgradeable is UniqueCheckingUpgradeable {
    event Claimed(address indexed recipient, address indexed collection, uint256[] tokenIds);

    error ClaimGoodUpgradeable__AlreadyClaimed();
    error ClaimGoodUpgradeable__NotOwner();

    mapping(uint256 => address) private _recipients;

    function claimInfo(address collection, uint256 tokenId) external view returns (bool isClaimed, address recipient) {
        uint256 claimId = _getClaimId(collection, tokenId);
        return (_used(claimId), _recipients[claimId]);
    }

    function _getClaimId(address collection, uint256 tokenId) internal pure returns (uint256 claimId) {
        claimId = (tokenId << 160) | Bytes32Address.fillLast96Bits(collection);
    }

    function _claimGoods(
        bool isBurning_,
        address recipient_,
        address collection_,
        uint256[] memory tokenIds_
    ) internal {
        IERC721Upgradeable collection = IERC721Upgradeable(collection_);
        uint256 length = tokenIds_.length;
        uint256 claimId;
        uint256 tokenId;

        for (uint256 i; i < length; ) {
            tokenId = tokenIds_[i];

            if (isBurning_) {
                IERC721Upgradeable(collection).burn(tokenId);
            } else {
                address owner = collection.ownerOf(tokenId);
                if (_isContract(owner)) owner = IAccount(owner).owner();
                if (recipient_ != owner) revert ClaimGoodUpgradeable__NotOwner();
            }

            claimId = _getClaimId(collection_, tokenId);

            if (_used(claimId)) revert ClaimGoodUpgradeable__AlreadyClaimed();

            _setUsed(claimId);
            _recipients[claimId] = recipient_;

            unchecked {
                ++i;
            }
        }

        emit Claimed(recipient_, collection_, tokenIds_);
    }

    function _isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
