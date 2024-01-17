// SPDX-License-Identifier: CONSTANTLY WANTS TO MAKE THE WORLD BEAUTIFUL

//  ██████  ██████  ██████  ██    ██ ███    ███ ██ ███    ██ ████████ 
// ██      ██    ██ ██   ██  ██  ██  ████  ████ ██ ████   ██    ██    
// ██      ██    ██ ██████    ████   ██ ████ ██ ██ ██ ██  ██    ██    
// ██      ██    ██ ██         ██    ██  ██  ██ ██ ██  ██ ██    ██    
//  ██████  ██████  ██         ██    ██      ██ ██ ██   ████    ██    
                                                                   
                                                                   
//  █████  ██      ██      ███████ ███████ ██                         
// ██   ██ ██      ██      ██      ██      ██                         
// ███████ ██      ██      █████   ███████ ██                         
// ██   ██ ██      ██      ██           ██                            
// ██   ██ ███████ ███████ ███████ ███████ ██                         
                                                                   
// by yours truly
// berk aka princess camel aka guerrilla pimp minion bastard                                                                  

// https://berkozdemir.com

// WITH THIS CONTRACT YOU CAN COPYMINT ANY ERC721 IN EXISTENCE ON THE CHAIN
// YOU CAN EVEN COPYMINT A NFT IN THIS CONTRACT, EVEN THE ONES ISN'T IN EXISTENCE YET HEHE. EXOERIMENT WITH DA MEDIUM
// PS. BY COPYMINTING, YOU ARE ONLY MIRRORING THE METADATA, NOTHING MORE. YOU ARE NOT STEALING ANYTHING, NOT BENEFITING WITH UTILITIES OF THE ORIGINAL TOKEN
// BUT YOU ARE PUBLICIZING IT. WHICH IS COOL ENOUGH.
// THIS COLLECTION IS YOUR CURATION. YOU WILL DETERMINE HOW WELL OR SHIT THIS COLLECTION WILL BE. MINT WITH YOUR INSTINCT. EXPRESS YOUR LOVE
// XOXO

pragma solidity ^0.8.0;
import "./ERC721AQueryable.sol";

contract COPYMINTALLES is ERC721AQueryable {

    struct CopyMintInfo {
        address fromContract;
        uint256 id;
    }

    mapping (uint256 => CopyMintInfo) public Database;

    event copyMinted(uint256 _tokenId, uint256 _idFrom, address _addressFrom, address _claimer);
    
    constructor() ERC721A("COPYMINT ALLES!", "COPYMINT") {

    }

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }
    
    function copyMint(CopyMintInfo[] calldata _data) public {
        uint supply = totalSupply();
        for (uint i = 0; i < _data.length; i++){
            Database[supply + i] = _data[i];
            emit copyMinted(supply + i, _data[i].id, _data[i].fromContract,  msg.sender);
        }
        _safeMint(msg.sender, _data.length);
    }
    /**
    * Overridden function, to mirror the metadata uri from copyminted NFT
    */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(_exists(_tokenId), "Invalid id");
        return ERC721A(Database[_tokenId].fromContract).tokenURI(Database[_tokenId].id);
    }   
}