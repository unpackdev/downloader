// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";

/* ##############################################################################

define contract name ==> BlocksideLogoNFT
define collection name ==> blockside.eth - Logos
define token symbol ==> BLC
modify the `BlocksideLogoNFT` constructor to pass
the `msg.sender` as the `initialOwner` argument to the `Ownable` contract.
(only owner of contract can mint NFT)

############################################################################## */

contract BlocksideLogoNFT is ERC721URIStorage, Ownable {

    constructor() ERC721("blockside.eth - Logos", "BLC") Ownable(msg.sender) {}

/* ##############################################################################

_to ==> who will receive the NFT
_tokenId ==> index number of the NFT
_uri ==> ipfs address of the json containing the ipfs to the resource (image)

############################################################################## */

    function mint(
        address _to,
        uint256 _tokenId,
        string calldata _uri
        )

/* ##############################################################################

onlyOwner specific that only the owner of the contract can mint NFT

############################################################################## */

        external onlyOwner {
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
    }
}
