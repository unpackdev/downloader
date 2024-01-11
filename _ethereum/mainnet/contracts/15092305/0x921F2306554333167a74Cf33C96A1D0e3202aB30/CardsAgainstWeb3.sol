// SPDX-License-Identifier: MIT

/*
  .oooooo.         .o.       ooooooooo.   oooooooooo.    .oooooo..o                          
 d8P'  `Y8b       .888.      `888   `Y88. `888'   `Y8b  d8P'    `Y8                          
888              .8"888.      888   .d88'  888      888 Y88bo.                               
888             .8' `888.     888ooo88P'   888      888  `"Y8888o.                           
888            .88ooo8888.    888`88b.     888      888      `"Y88b                          
`88b    ooo   .8'     `888.   888  `88b.   888     d88' oo     .d8P                          
 `Y8bood8P'  o88o     o8888o o888o  o888o o888bood8P'   8""88888P'                           
                                                                                             
                                                                                             
                                                                                             
      .o.         .oooooo.          .o.       ooooo ooooo      ooo  .oooooo..o ooooooooooooo 
     .888.       d8P'  `Y8b        .888.      `888' `888b.     `8' d8P'    `Y8 8'   888   `8 
    .8"888.     888               .8"888.      888   8 `88b.    8  Y88bo.           888      
   .8' `888.    888              .8' `888.     888   8   `88b.  8   `"Y8888o.       888      
  .88ooo8888.   888     ooooo   .88ooo8888.    888   8     `88b.8       `"Y88b      888      
 .8'     `888.  `88.    .88'   .8'     `888.   888   8       `888  oo     .d8P      888      
o88o     o8888o  `Y8bood8P'   o88o     o8888o o888o o8o        `8  8""88888P'      o888o     
                                                                                             
                                                                                             
                                                                                             
oooooo   oooooo     oooo oooooooooooo oooooooooo.    .oooo.                                  
 `888.    `888.     .8'  `888'     `8 `888'   `Y8b .dP""Y88b                                 
  `888.   .8888.   .8'    888          888     888       ]8P'                                
   `888  .8'`888. .8'     888oooo8     888oooo888'     <88b.                                 
    `888.8'  `888.8'      888    "     888    `88b      `88b.                                
     `888'    `888'       888       o  888    .88P o.   .88P                                 
      `8'      `8'       o888ooooood8 o888bood8P'  `8bd88P'                     
*/

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract CardsAgainstWeb3 is ERC721A, Ownable {
    bool public isSaleActive = false; 

    uint256 private constant maxSupply = 10000;
    uint256 private constant maxMintPerTx = 10;
    uint256 private constant mintPerWallet = 20;
    uint256 private constant teamAllocationAmount = 1000;
    mapping(address => uint256) private teamAllocation;
    mapping(address => uint256) private mintCnt;
    string private baseURI;

    modifier onlyTeam() {
        require(teamAllocation[msg.sender] > 0, "Caller have no team allocation");
        _;
    }

    constructor() ERC721A("CardsAgainstWeb3", "CAW3") {
        teamAllocation[0x5A72fA34208dF9CEfF7E61e358c4a017596D8Ec4] = 334;
        teamAllocation[0xaC6ec02dbc96B0b91E7c91D8925a92151aAc56B2] = 333;
        teamAllocation[0xCb69A1716dcBaaf3d9bCdDD1389543315320AF6B] = 333;
    }

    function mint(uint256 amount) external {
        require(isSaleActive, "Sales not active yet");
        require(_totalMinted() + amount <= maxSupply, "Would exceed max supply");
        require(mintCnt[msg.sender] + amount <= mintPerWallet, "Max minting exceeded");
        require(amount <= maxMintPerTx, "This amount cannot be minted");

        mintCnt[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintReserve() external onlyTeam {
        _safeMint(msg.sender, teamAllocation[msg.sender]);
        teamAllocation[msg.sender] = 0;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setIsSaleActive(bool value) external onlyOwner {
        if(value == true)
            require(_totalMinted() >= teamAllocationAmount, "Team allocation not fulfilled yet");
        
        isSaleActive = value;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token not minted");

        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}