//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MadMouseTroupe.sol";
import "./MadMouseStaking.sol";
import "./Ownable.sol";

contract MadMouseTroupeMetadata is Ownable {
    using Strings for uint256;

    MadMouseTroupe public madmouseTroupe;
    MadMouseTroupeMetadata public metadataGenesis;

    string specialURI;
    string constant unrevealedURI = 'ipfs://QmW9NKUGYesTiYx5iSP1o82tn4Chq9i1yQV6DBnzznrHTH';

    function setMadMouseAddress(MadMouseTroupe madmouseTroupe_, MadMouseTroupeMetadata metadataGenesis_)
        external
        onlyOwner
    {
        metadataGenesis = metadataGenesis_;
        madmouseTroupe = madmouseTroupe_;
    }

    function setSpecialURI(string calldata uri) external onlyOwner {
        specialURI = uri;
    }

    // will act as an ERC721 proxy
    function balanceOf(address user) external view returns (uint256) {
        return madmouseTroupe.numOwned(user);
    }

    // reuse metadata build from genesis collection
    function buildMouseMetadata(uint256 tokenId, uint256 level) external returns (string memory) {
        if (tokenId > 30) {
            (, bytes memory data) = address(metadataGenesis).delegatecall(
                abi.encodeWithSelector(this.buildMouseMetadata.selector, tokenId, level)
            );
            return abi.decode(data, (string));
        }
        return bytes(specialURI).length != 0 ? string.concat(specialURI, tokenId.toString()) : unrevealedURI;
    }
}
