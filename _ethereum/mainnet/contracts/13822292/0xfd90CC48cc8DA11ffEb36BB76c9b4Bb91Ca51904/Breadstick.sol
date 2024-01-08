/*

███╗   ██╗ ██████╗ ███╗   ██╗      ███████╗██╗   ██╗███╗   ██╗ ██████╗ ██╗██████╗ ██╗     ███████╗
████╗  ██║██╔═══██╗████╗  ██║      ██╔════╝██║   ██║████╗  ██║██╔════╝ ██║██╔══██╗██║     ██╔════╝
██╔██╗ ██║██║   ██║██╔██╗ ██║█████╗█████╗  ██║   ██║██╔██╗ ██║██║  ███╗██║██████╔╝██║     █████╗  
██║╚██╗██║██║   ██║██║╚██╗██║╚════╝██╔══╝  ██║   ██║██║╚██╗██║██║   ██║██║██╔══██╗██║     ██╔══╝  
██║ ╚████║╚██████╔╝██║ ╚████║      ██║     ╚██████╔╝██║ ╚████║╚██████╔╝██║██████╔╝███████╗███████╗
╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═══╝      ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═════╝ ╚══════╝╚══════╝
                                                                                                  
██████╗ ██████╗ ███████╗ █████╗ ██████╗ ███████╗████████╗██╗ ██████╗██╗  ██╗███████╗              
██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝██╔════╝              
██████╔╝██████╔╝█████╗  ███████║██║  ██║███████╗   ██║   ██║██║     █████╔╝ ███████╗              
██╔══██╗██╔══██╗██╔══╝  ██╔══██║██║  ██║╚════██║   ██║   ██║██║     ██╔═██╗ ╚════██║              
██████╔╝██║  ██║███████╗██║  ██║██████╔╝███████║   ██║   ██║╚██████╗██║  ██╗███████║              
╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝              

From the regional managers of Non-Fungible Olive Gardens

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./base64.sol";

contract Breadstick is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public breadsticksToReserve = 30;
    string public imageURI = 'ipfs://QmVBnkLci5Ty3ds5LakYbvVXYWd36oZFTqZAdYyqJHJgjZ';
    string public imageURI2 = 'ipfs://QmVBnkLci5Ty3ds5LakYbvVXYWd36oZFTqZAdYyqJHJgjZ';

    constructor() ERC721("Non-Fungible Breadsticks", "NFB") {
        // Order some breadsticks for the regional managers
        for(uint i=1; i <= breadsticksToReserve; i++){
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
   
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintBreadstick() whenNotPaused public {
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function totalSupply() public view returns(uint256){
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory uri;
        string memory color;
        // Our ovens occasionally experience technical difficulties
        if(tokenId % 1000 == 0 && tokenId > 0){
            uri = imageURI2;
            color = 'Burned';
        }else{
            uri = imageURI;
            color = 'Golden Brown';
        }

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Breadstick #', uint2str(tokenId) ,'", "description": "A hot and delicious breadstick from your local Non-Fungible Olive Garden.", "image": "', uri ,'", "attributes": [{"trait_type": "Color","value": "', color , '"}]}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function setImageURI(string memory uri) public onlyOwner{
        imageURI = uri;
    }

    function setImageURI2(string memory uri) public onlyOwner{
        imageURI2 = uri;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}