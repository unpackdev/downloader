// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;                                                                                                                                          
//    .^7??????????????????????????????????????????????????????????????????7!:       .~7????????????????????????????????: 
//     :#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y   ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5 
//    ^@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@B ~@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBB#7 
//    Y@@@@@#                                                                ~@@@@@@ P@@@@@G                                 
//    .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G~ ~@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~   
//      J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.!B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~   .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B  
//         ...........................B@@@@@5  .7#@@@@@@@#?^....................          ..........................:#@@@@@J 
//    ^5YYYJJJJJJJJJJJJJJJJJJJJJJJJJJY&@@@@@?     .J&@@@@@@&5JJJJJJJJJJJJJJJJJJJYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJY@@@@@@! 
//    5@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?         :5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7  
//    !GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPY~              ^JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ^    


//  __________________________________________________ Tomb Series ___________________________________________________

// _____________________________________________________ RONIN _______________________________________________________

// _______________________________________________ TOMB CLX: SOLUTION ________________________________________________

 // ________________________________________ A collaboration with Ezra Miller ________________________________________

// ______________________________________________ Drawn by David Rudnick _____________________________________________

// _________________________________________ Contract architect: Luke Miles __________________________________________

import "./lib.sol";

contract Ronin is ERC721, Ownable {
    error InvalidTomb();
    error AlreadyMinted();
    error Unauthorized();

    ERC721 IndexContract;
    uint8 internal constant _tombID = 160;
    bool public tombMinted = false;
    address internal _tombArtist = 0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46;

    constructor(address indexContract) ERC721("Tomb Series: RONIN", "TOMB") {
        IndexContract = ERC721(indexContract);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (id != _tombID) revert InvalidTomb();
        return IndexContract.tokenURI(id);
    }

    function mint() public {
        if (tombMinted) revert AlreadyMinted();
        address owner = owner();
        if (tx.origin != owner) revert Unauthorized();

        _mint(owner, _tombID);
        tombMinted = true;
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        if (_tokenId != _tombID) revert InvalidTomb();
        receiver = _tombArtist;
        royaltyAmount = _salePrice / 10;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x2a55205a;   // ERC165 Interface ID for ERC2981
    }
 
}
