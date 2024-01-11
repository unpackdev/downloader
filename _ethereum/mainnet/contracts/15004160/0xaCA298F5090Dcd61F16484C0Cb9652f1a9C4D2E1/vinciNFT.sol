// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "Ownable.sol";
import "ERC721Royalty.sol";


//                          &&&&&%%%%%%%%%%#########*
//                      &&&&&&&&%%%%%%%%%%##########(((((
//                   @&&&&&&&&&%%%%%%%%%##########((((((((((
//                @@&&&&&&&&&&%%%%%%%%%#########(((((((((((((((
//              @@@&&&&&&&&%%%%%%%%%%##########((((((((((((((///(
//            %@@&&&&&&               ######(                /////.
//           @@&&&&&&&&&           #######(((((((       ,///////////
//          @@&&&&&&&&%%%           ####((((((((((*   .//////////////
//         @@&&&&&&&%%%%%%          ##((((((((((((/  ////////////////*
//         &&&&&&&%%%%%%%%%          *(((((((((//// //////////////////
//         &&&&%%%%%%%%%####          .((((((/////,////////////////***
//        %%%%%%%%%%%########.          ((/////////////////***********
//         %%%%%##########((((/          /////////////****************
//         ##########((((((((((/          ///////*********************
//         #####((((((((((((/////          /*************************,
//          #(((((((((////////////          *************************
//           (((((//////////////***          ***********************
//            ,//////////***********        *************,*,,*,,**
//              ///******************      *,,,,,,,,,,,,,,,,,,,,,
//                ******************,,    ,,,,,,,,,,,,,,,,,,,,,
//                   ****,,*,,,,,,,,,,,  ,,,,,,,,,,,,,,,,,,,
//                      ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                          .,,,,,,,,,,,,,,,,,,,,,,,


contract VinciNFT is ERC721Royalty, Ownable {

    using Strings for uint256;

    string public baseURI;
    string internal collectionContractURI;

    constructor(address receiver) ERC721("Vinci NFT", "VNFT") {
        // Default royalty denominator is 10_000 (basispoints). Set fees to 10%.
        _setDefaultRoyalty(receiver, 1000);  // rarible royalties. Opensea is handled by contractURI()
        baseURI = "set me";
        collectionContractURI = "set me";
    }

    /// minting functions

    function mintTo(uint tokenId, address _to) public onlyOwner {
        _safeMint(_to, tokenId);
    }

    function mintBatchTo(uint[] calldata _tokenIds, address _to) public onlyOwner {
        require(_tokenIds.length < 301, "max 300 tokenIds per patch");
        for (uint i = 0; i < _tokenIds.length; i++) {
            _safeMint(_to, _tokenIds[i]);
        }
    }

    /// configuration functions

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        collectionContractURI = _newContractURI;
    }

    function setDefaultRoyalty(address receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    /// read functions

    function tokenURI(uint256 tokenId) override view public returns (string memory) {
        require(ownerOf(tokenId) != address(0), "non existing tokenId");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function contractURI() public view returns (string memory) {
        return collectionContractURI;
    }
}