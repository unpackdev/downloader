// SPDX-License-Identifier: MIT

/*
.__                       .__       ________           ____  ___                                         __            .___.__        
|__| _____ _____     ____ |__| ____ \_____  \          \   \/  /         ____   ____             _______/  |_ __ __  __| _/|__| ____  
|  |/     \\__  \   / ___\|  |/    \  _(__  <           \     /         /  _ \ / ___\   ______  /  ___/\   __\  |  \/ __ | |  |/  _ \ 
|  |  Y Y  \/ __ \_/ /_/  >  |   |  \/       \          /     \        (  <_> ) /_/  > /_____/  \___ \  |  | |  |  / /_/ | |  (  <_> )
|__|__|_|  (____  /\___  /|__|___|  /______  / /\      /___/\  \        \____/\___  /          /____  > |__| |____/\____ | |__|\____/ 
         \/     \//_____/         \/       \/  \/            \_/             /_____/                \/                  \/            

 */


pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";


contract Imagin3PFP is ERC721, Ownable {

    mapping(uint256=>string) public uri;

    uint public currentIndex;
    
    constructor() ERC721("Imagin3 PFP","IPFP") {
    }

    function mint(uint256 total, string memory baseURI) public onlyOwner {
        uint max = currentIndex + total;
        for (uint256 i=currentIndex;i<max;i++) {
            uri[i] = string.concat(baseURI, Strings.toString(i), ".json");
            currentIndex++;
            _safeMint(msg.sender, i);
        }
    }

    function updateURI(uint256 id, string memory _inputURI) public onlyOwner {
        uri[id] = _inputURI;    
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        
        return string(uri[tokenId]);
    }
}