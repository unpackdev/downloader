// SPDX-License-Identifier: MIT

//        ██████╗░░█████╗░██╗░░░██╗░█████╗        //░
//        ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗       //
//        ██████╔╝███████║░╚████╔╝░██║░░╚═╝       //
//        ██╔═══╝░██╔══██║░░╚██╔╝░░██║░░██╗       //
//        ██║░░░░░██║░░██║░░░██║░░░╚█████╔╝       //
//        ╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░░╚════╝        //

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract PirateApe is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public totalPirate;
    uint256 public totalCount = 5000;
    
    uint256 public price = 0.05 ether;

    string public baseURI;
    string public unRevealedURI;

    uint8 public maxBatch = 8;
    bool public started = false;
    bool public revealed = false;
    bool public isAllowListActive = false;
    
    mapping(address => uint8) public allowList;

    constructor() ERC721("Pirate Ape Yarr Club", "PAYC") {
        baseURI = "https://pirateapeyarrclub.com/api/payc/";
        unRevealedURI = "https://pirateapeyarrclub.com/api/payc/0";
    }

    function _baseURI() 
        internal
        view
        virtual 
        override 
        returns (string memory) 
    {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setUnRevealedURI(string memory _newURI) external onlyOwner {
        unRevealedURI = _newURI;
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
       
        if(!revealed){
          return unRevealedURI;
        }
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function start() public onlyOwner {
        started = true;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }
    
    function setIsAllowListActive() external onlyOwner {
        isAllowListActive = true;
    }

    function setAllowList(address[] calldata addresses, uint8[] memory numAllowedToMint) 
        external 
        onlyOwner 
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = numAllowedToMint[i];
        }
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function mint(uint256 numberOfTokens) external payable {
        require(started, "Not started!");
        require(numberOfTokens > 0, "Error input!");
        require(numberOfTokens <= maxBatch, "Must mint fewer in each batch!");
        require(
          totalPirate + numberOfTokens <= totalCount, 
          "Max supply reached!"
        );
        require(msg.value >= numberOfTokens * price, "Value error, please check price!");

        for(uint256 i = 0; i < numberOfTokens; i++){
            _safeMint(_msgSender(), 1 + totalPirate++);
        }
    }
    
    function mintAllowList(uint8 numberOfTokens) external {
        require(isAllowListActive, "Allow list is not active!");
        require(numberOfTokens > 0, "Error input!");
        require(numberOfTokens <= allowList[msg.sender], "Exceeded max available to purchase!");
        require(
          totalPirate + numberOfTokens <= totalCount, 
          "max supply reached!"
        );
        
        allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, 1 + totalPirate++);
        }
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
