//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721.sol";

abstract contract AlbumNftManager {
    event AddNfts(address[] nfts, uint256[] ids);
    event SendNfts(address to, uint256[] idxs);

    // NFTs owned by this album.
    address[] private nfts;
    uint256[] private ids;
    bool[] private sent;

    function getNfts() public view returns (address[] memory) {
        return nfts;
    }

    function getIds() public view returns (uint256[] memory) {
        return ids;
    }

    function getSent() public view returns (bool[] memory) {
        return sent;
    }

    function _addNfts(address[] memory _nfts, uint256[] memory _ids) internal {
        require(
            _nfts.length == _ids.length,
            "Input array lenghts don't match."
        );
        for (uint256 i = 0; i < _nfts.length; i++) {
            address nftAddr = _nfts[i];
            IERC721 nft = IERC721(nftAddr);
            uint256 id = _ids[i];
            address owner = nft.ownerOf(id);
            if (owner != address(this)) {
                nft.safeTransferFrom(owner, address(this), id);
            }
            nfts.push(nftAddr);
            ids.push(id);
            sent.push(false);
        }
        emit AddNfts(_nfts, _ids);
    }

    function _sendNfts(address to, uint256[] memory idxs) internal {
        uint256 idx;
        for (uint256 i = 0; i < idxs.length; i++) {
            idx = idxs[i];
            IERC721(nfts[idx]).safeTransferFrom(address(this), to, ids[idx]);
            sent[idx] = true;
        }
        emit SendNfts(to, idxs);
    }
}
