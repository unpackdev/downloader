//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC721A.sol";
import "./Ownable.sol";

/*
    ⠀⠀⠀⠀⠀⢰⡿⠋⠁⠀⠀⠈⠉⠙⠻⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

⠀⠀⠀⠀⢀⣿⠇⠀⢀⣴⣶⡾⠿⠿⠿⢿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

⠀⠀⣀⣀⣸⡿⠀⠀⢸⣿⣇⠀⠀⠀⠀⠀⠀⠙⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ yo

⠀⣾⡟⠛⣿⡇⠀⠀⢸⣿⣿⣷⣤⣤⣤⣤⣶⣶⣿⠇⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀

⢀⣿⠀⢀⣿⡇⠀⠀⠀⠻⢿⣿⣿⣿⣿⣿⠿⣿⡏⠀⠀⠀⠀⢴⣶⣶⣿⣿⣿⣆

⢸⣿⠀⢸⣿⡇⠀⠀⠀⠀⠀⠈⠉⠁⠀⠀⠀⣿⡇⣀⣠⣴⣾⣮⣝⠿⠿⠿⣻⡟

⢸⣿⠀⠘⣿⡇⠀⠀⠀⠀⠀⠀⠀⣠⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠉⠀

⠸⣿⠀⠀⣿⡇⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠉⠀⠀⠀⠀

⠀⠻⣷⣶⣿⣇⠀⠀⠀⢠⣼⣿⣿⣿⣿⣿⣿⣿⣛⣛⣻⠉⠁⠀⠀⠀⠀⠀⠀⠀

⠀⠀⠀⠀⢸⣿⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀

⠀⠀⠀⠀⢸⣿⣀⣀⣀⣼⡿⢿⣿⣿⣿⣿⣿⡿⣿⣿⡿
*/

contract Phost is ERC721A, Ownable {

    using Strings for uint256;

    // Public constants
    uint public constant MAX_SUPPLY = 1999;
    uint public constant MAX_PER_TX = 20;
    string private baseURI = "ipfs://bafybeianmbgwwy2v77tis6zdsyq22cc3ux5ujavukz5zi75kw4gqvc5zvm/";

    constructor() ERC721A("projectPNX", "PHOST") {}

    /*
        @dev Function to mint a batch of tokens
    */
    function mint(uint256 quantity) external {
        require(quantity <= MAX_PER_TX);
        require(quantity + _totalMinted() <= MAX_SUPPLY, "Too many Phosts");
    
        _safeMint(msg.sender, quantity);
    }


    /*
        @dev Function to mint tokens to a specific address.
    */
    function mintFor(address[] memory to, uint256 quantity) external {
        require((to.length * quantity) + _totalMinted() <= MAX_SUPPLY, "Too many Phosts");
        for(uint i = 0; i < to.length; i++) {
            _safeMint(to[i], quantity);
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /*
        @dev ipfs file name range is 8000-10000 versus on chain being 0-2000
    */
    function tokenURI (uint256 tokenId) public view virtual override returns (string memory) {
        uint256 _tokenId = tokenId + 8000;
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

}