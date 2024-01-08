// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721WithOverrides.sol";
import "./console.sol";

contract RareMoonCats is ERC721WithOverrides {

    address  public cryptoRaresAddress; // to check for ownership of CryptoRares
    address public acclimatedMoonCatsAddress; // to check for ownership of MoonCats
    
    mapping (uint => bool) public invalidTypes;
    // keeps track of worn items via their section and cryptoRareTokenId (e.g. 0, 222, 0, 12 means body and boots are worn.) 1st slot is head, 2nd body, 3rd legs, 4th boots
    mapping (uint => uint[4]) public rareMoonCatToWValue; 
    // each integer correlatse to the section each CryptoRareType belongs to on the cat (0 non, 1 head, 2 body, 3 legs, 4 boots)
    uint[39] cryptoRareTypesToSection = [0, 1, 1, 2, 1, 2, 4, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 1, 2, 0, 0, 1, 0, 1, 0, 2, 4, 1, 3, 1, 2, 1, 2, 1, 1, 1, 1, 1, 1];

    constructor() ERC721("RareMoonCats", "RAREMOONCAT") {
     }

    function mintRareMoonCat(uint _cryptoRareTokenId, string memory _rareMoonCatTokenURI, uint _acclimatedMoonCatTokenId) public {

        CryptoRares cryptoRares = CryptoRares(cryptoRaresAddress);
        AcclimatedMoonCats acclimatedMoonCats = AcclimatedMoonCats(acclimatedMoonCatsAddress);
        
        require(_exists(_acclimatedMoonCatTokenId) == false, "RareMoonCat was already minted with passed in AcclimatedMoonCat.");
        require(invalidTypes[uint(cryptoRares.tokenIdToType(_cryptoRareTokenId))] == false, "CryptoRare is not a valid wearable");
        require(cryptoRares.ownerOf(_cryptoRareTokenId) == msg.sender, "msg.sender is not owner of rare token");            
        require(acclimatedMoonCats.ownerOf(_acclimatedMoonCatTokenId) == msg.sender, "msg.sender is not owner of mooncat id passed");
        
        cryptoRares.transferFrom(msg.sender, address(this), _cryptoRareTokenId);
        acclimatedMoonCats.transferFrom(msg.sender, address(this), _acclimatedMoonCatTokenId);

        // acclimatedMoonCat id is stored within token id of RareMoonCat
        _safeMint(msg.sender, _acclimatedMoonCatTokenId);
        _setTokenURI(_acclimatedMoonCatTokenId, _rareMoonCatTokenURI);

        // update wValue
        uint sectionForType = cryptoRareTypeToSection(uint(cryptoRares.tokenIdToType(_cryptoRareTokenId)));
        rareMoonCatToWValue[_acclimatedMoonCatTokenId][sectionForType] = _cryptoRareTokenId; 
    }


    function addRareToRareMoonCat(uint _cryptoRareTokenId, string memory _rareMoonCatTokenURI, uint _rareMoonCatTokenId) public {
        CryptoRares cryptoRares = CryptoRares(cryptoRaresAddress);
        
        require(invalidTypes[uint(cryptoRares.tokenIdToType(_cryptoRareTokenId))] == false, "CryptoRare is not a valid wearable");
        require(cryptoRares.ownerOf(_cryptoRareTokenId) == msg.sender, "msg.sender is not owner of rare token");        
        require(ownerOf(_rareMoonCatTokenId) == msg.sender, "msg.sender is not owner of raremooncat");
        
        // make sure section is not being occupied by another wearable
        uint sectionForType = cryptoRareTypeToSection(uint(cryptoRares.tokenIdToType(_cryptoRareTokenId)));
        require(rareMoonCatToWValue[_rareMoonCatTokenId][sectionForType] == 0, "RareMoonCat already has CryptoRare on corresponding section");

        // update URI
        _setTokenURI(_rareMoonCatTokenId, _rareMoonCatTokenURI);
        // transfer rare        
        cryptoRares.transferFrom(msg.sender, address(this), _cryptoRareTokenId);
        // update wValuye
        rareMoonCatToWValue[_rareMoonCatTokenId][sectionForType] = _cryptoRareTokenId;
    }


    function removeCryptoRareFromRareMoonCat(uint _section, string memory _newTokenURI, uint _rareMoonCatTokenId) public {
       
        require(msg.sender == ownerOf(_rareMoonCatTokenId), "Msg.sender is not owner of RareMoonCat");
        require(rareMoonCatIsNaked(_rareMoonCatTokenId) == false, "RareMoonCat is already naked!");

        CryptoRares cryptoRares = CryptoRares(cryptoRaresAddress);

        // check that rare is worn     
        uint cryptoRareTokenId = rareMoonCatToWValue[_rareMoonCatTokenId][_section];
        require(cryptoRareTokenId != 0, "RareMoonCat is not wearing rare on passed in section");

        // transfer back cryptorare                
        cryptoRares.transferFrom(address(this), msg.sender, cryptoRareTokenId);
        // update wValue for RareMoonCat
        rareMoonCatToWValue[_rareMoonCatTokenId][_section] = 0;

        // if no rares are left worn, return mooncat to owner and burn raremooncat
        if (rareMoonCatIsNaked(_rareMoonCatTokenId) == true) {
            transferBackAcclimatedMoonCatAndBurnRareMoonCat(_rareMoonCatTokenId);            
        } else {
            // else if there are still rares worn, set the new tokenURI
            _setTokenURI(_rareMoonCatTokenId, _newTokenURI);
        }
    }

    function removeAllCryptoRares(uint _rareMoonCatTokenId) public {
        
        require(ownerOf(_rareMoonCatTokenId) == msg.sender, "msg.sender is not owner of RareMoonCat");
        require(rareMoonCatIsNaked(_rareMoonCatTokenId) == false, "RareMoonCat doesn't have anything on!");
        
        for (uint index = 0; index < 4; index++) {
            uint cryptoRareTokenIdForSection = rareMoonCatToWValue[_rareMoonCatTokenId][index];
            if (cryptoRareTokenIdForSection != 0) {
                
                // transfer back cryptorares
                CryptoRares cryptoRares = CryptoRares(cryptoRaresAddress);
                cryptoRares.transferFrom(address(this), msg.sender, cryptoRareTokenIdForSection);                                

                // update w value
                rareMoonCatToWValue[_rareMoonCatTokenId][index] = 0;
            }
        }
        transferBackAcclimatedMoonCatAndBurnRareMoonCat(_rareMoonCatTokenId);
    }

    function transferBackAcclimatedMoonCatAndBurnRareMoonCat(uint _rareMoonCatTokenId) private {
        // transfer back mooncat
        AcclimatedMoonCats acclimatedMoonCats = AcclimatedMoonCats(acclimatedMoonCatsAddress);
        acclimatedMoonCats.transferFrom(address(this), msg.sender, _rareMoonCatTokenId); 
        
        // burn RareMoonCat
        _burn(_rareMoonCatTokenId);
    }
    
    function rareMoonCatIsNaked(uint _rareMoonCatTokenId) private view returns(bool) {
        for (uint index = 0; index < 4; index++) {
            if (rareMoonCatToWValue[_rareMoonCatTokenId][index] != 0) {
                return false;
            }
        }
        return true;
    }

    function cryptoRareTypeToSection(uint _cryptoRareType) private view returns(uint) {
        // remove one because the type to section denotes 0, 1, 2, 3 as non, head, body, legs, boots
        // which correlates erroneously to the wValue where [0] is head, [1] body, [2] legs, [3] boots
        return (cryptoRareTypesToSection[_cryptoRareType] - 1); 
    }
    

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    receive() payable external { }

    function setCryptoRaresAddress(address payable _address) external onlyOwner {
        cryptoRaresAddress = _address;
    }

    function setAcclimatedMoonCatsAddress(address payable _address) external onlyOwner {
        acclimatedMoonCatsAddress = _address;
    }

    function addInvalidType(uint _type, bool _invalid) external onlyOwner {
        invalidTypes[_type] = _invalid;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

abstract contract CryptoRares {    
    enum TYPE { 
        BLUE_MARIONETTE,
        BLUE_MASK, 
        BOBBLE_HAT, 
        BOBBLE_SCARF,         
        BUNNY_EARS, 
        CHICKEN_BODY, 
        CHICKEN_BOOTS,
        CHICKEN_HEAD,        
        CHICKEN_LEGS,        
        CRACKER,        
        DISK_OF_RETURNING,        
        EASTER_EGG,        
        EASTER_RING,        
        GREEN_MARIONETTE,        
        GREEN_MASK,        
        HALF_FULL_WINE_JUG,
        JACK_LANTERN_MASK,        
        JESTER_HAT,        
        JESTER_SCARF,        
        PUMPKIN,        
        RED_MARIONETTE,
        RED_MASK,
        RUBBER_CHICKEN,
        SANTA_HAT,
        SCYTHE,
        SKELETON_BODY,
        SELETON_BOOTS,
        SELETON_HEAD,
        SKELETON_LEGS,
        TRI_JESTER_HAT,
        TRI_JESTER_SCARF,
        WOOLLY_HAT,
        WOOLLY_SCARF,
        BLUE_PARTYHAT,
        GREEN_PARTYHAT,
        PURPLE_PARTYHAT,
        RED_PARTYHAT,
        WHITE_PARTYHAT,
        YELLOW_PARTYHAT        
    }
    mapping (uint => TYPE) public tokenIdToType;
    function ownerOf(uint256 tokenId) external view virtual returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external virtual;
}

abstract contract AcclimatedMoonCats {
    function ownerOf(uint256 tokenId) external view virtual returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external virtual;
}
