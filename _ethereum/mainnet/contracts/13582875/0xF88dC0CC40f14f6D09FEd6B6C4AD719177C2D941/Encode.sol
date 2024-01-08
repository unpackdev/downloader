/*
                                                                        
                   ,--.               ,----..                           
    ,---,.       ,--.'|  ,----..     /   /   \      ,---,        ,---,. 
  ,'  .' |   ,--,:  : | /   /   \   /   .     :   .'  .' `\    ,'  .' | 
,---.'   |,`--.'`|  ' :|   :     : .   /   ;.  \,---.'     \ ,---.'   | 
|   |   .'|   :  :  | |.   |  ;. /.   ;   /  ` ;|   |  .`\  ||   |   .' 
:   :  |-,:   |   \ | :.   ; /--` ;   |  ; \ ; |:   : |  '  |:   :  |-, 
:   |  ;/||   : '  '; |;   | ;    |   :  | ; | '|   ' '  ;  ::   |  ;/| 
|   :   .''   ' ;.    ;|   : |    .   |  ' ' ' :'   | ;  .  ||   :   .' 
|   |  |-,|   | | \   |.   | '___ '   ;  \; /  ||   | :  |  '|   |  |-, 
'   :  ;/|'   : |  ; .''   ; : .'| \   \  ',  / '   : | /  ; '   :  ;/| 
|   |    \|   | '`--'  '   | '/  :  ;   :    /  |   | '` ,/  |   |    \ 
|   :   .''   : |      |   :    /    \   \ .'   ;   :  .'    |   :   .' 
|   | ,'  ;   |.'       \   \ .'      `---`     |   ,.'      |   | ,'   
`----'    '---'          `---`                  '---'        `----'     


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

    contract Encode is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {

    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("ENCODE", "ENET") {
      }

        function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
            require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
            _tokenURIs[tokenId] = _tokenURI;
        }

        function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

            string memory _tokenURI = _tokenURIs[tokenId];

            return _tokenURI;
        }

        function safeMint( uint256 quantity, string memory tokenURI_ ) public payable {

        for (uint i = 0; i < quantity; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _setTokenURI(newItemId, tokenURI_);
        }
     }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
