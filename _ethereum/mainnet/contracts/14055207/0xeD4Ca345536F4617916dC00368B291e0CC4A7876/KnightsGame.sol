// SPDX-License-Identifier: MIT

//       ██╗░░██╗███╗░░██╗██╗░██████╗░██╗░░██╗████████╗░██████╗  ░██████╗░░█████╗░███╗░░░███╗███████╗       //
//       ██║░██╔╝████╗░██║██║██╔════╝░██║░░██║╚══██╔══╝██╔════╝  ██╔════╝░██╔══██╗████╗░████║██╔════╝       //
//       █████═╝░██╔██╗██║██║██║░░██╗░███████║░░░██║░░░╚█████╗░  ██║░░██╗░███████║██╔████╔██║█████╗░░       //
//       ██╔═██╗░██║╚████║██║██║░░╚██╗██╔══██║░░░██║░░░░╚═══██╗  ██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░       //
//       ██║░╚██╗██║░╚███║██║╚██████╔╝██║░░██║░░░██║░░░██████╔╝  ╚██████╔╝██║░░██║██║░╚═╝░██║███████╗       //
//       ╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═════╝░  ░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝       //

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract KnightsGame is ERC721Enumerable, Ownable {
    using Strings for uint256;

    address CHAINRUNNERS_ADDR = 0x97597002980134beA46250Aa0510C9B90d87A587;

    uint256 public totalKnights;
    uint256 public totalKnightsByHolder;
    uint256 public totalCount = 10000;
    uint256 public availForHolder = 500;

    uint256 public price = 0.05 ether;
    uint256 public specialPrice = 0.04 ether;

    string public baseURI;
    string public unRevealedURI;

    uint8 public maxBatch = 5;
    bool public started = false;
    bool public presale = false;
    bool public revealed = false;
    
    mapping(address => uint8) public listFreeMint;
    mapping(address => uint8) public whitelisted;

    constructor() ERC721("Knights Game", "KNIGHTS") {
        baseURI = "https://knights.game/api/knights/";
        unRevealedURI = "https://knights.game/api/knights/0";
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

    function start() external onlyOwner {
        started = true;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }
    
    function startPresale() external onlyOwner {
        presale = true;
    }

    function setFreeMint(address[] calldata addresses, uint8[] memory numAllowedToMint) 
        external 
        onlyOwner 
    {
        for (uint32 i = 0; i < addresses.length; i++) {
            listFreeMint[addresses[i]] = numAllowedToMint[i];
        }
    }

    function setWhitelist(address[] calldata addresses, uint8[] memory numAllowedToMint) 
        external 
        onlyOwner 
    {
        for (uint32 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = numAllowedToMint[i];
        }
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory){
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function isHolder(address _wallet) 
        public 
        view 
        returns (bool, uint256) 
    {
        ERC721Enumerable RUN = ERC721Enumerable(CHAINRUNNERS_ADDR);
        uint runBalance = RUN.balanceOf(_wallet);

        return (runBalance > 0, runBalance);
    }

    function mint(uint8 numberOfTokens) external payable {
        require(started, "Not started!");
        require(numberOfTokens > 0, "Error input!");
        require(
          numberOfTokens <= maxBatch,
          "Must mint fewer in each batch!"
        );
        require(
          totalKnights + numberOfTokens <= totalCount, 
          "Max supply reached!"
        );
        require(
          msg.value >= numberOfTokens * price, 
          "Value error, please check price!"
        );
        
        for(uint256 i=0; i< numberOfTokens; i++){
            _safeMint(_msgSender(), 1 + totalKnights++);
        }
    }
    
    function whitelistMint(uint8 numberOfTokens) external payable {
        require(presale, "Presale is not started!");
        require(numberOfTokens > 0, "Error input!");
        require(
          numberOfTokens <= whitelisted[msg.sender], 
          "Exceeded max available to purchase!"
        );
        require(
          totalKnights + numberOfTokens <= totalCount, 
          "Max supply reached!"
        );
        require(
          msg.value >= numberOfTokens * price, 
          "Value error, please check price!"
        );
        
        whitelisted[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, 1 + totalKnights++);
        }
    }

    function freeMint(uint8 numberOfTokens) external payable {
        require(presale, "Presale is not active!");
        require(numberOfTokens > 0, "Error input!");
        require(
          numberOfTokens <= listFreeMint[msg.sender], 
          "Exceeded max available to purchase!"
        );
        require(
          totalKnights + numberOfTokens <= totalCount, 
          "max supply reached!"
        );
        
        listFreeMint[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, 1 + totalKnights++);
        }
    }

     function holderMint(uint8 numberOfTokens) external payable {
        require(started, "Not started!");
        (bool _holder, ) = isHolder(msg.sender);
        require(_holder, "RUN NOT FOUND!");
        require(numberOfTokens > 0, "Error input!");
        require(numberOfTokens <= maxBatch, "Must mint fewer in each batch!");
        require(
            numberOfTokens + totalKnightsByHolder <= availForHolder, 
            "Max Mint Holder Reached"
        );
        require(
          totalKnights + numberOfTokens <= totalCount, 
          "Max supply reached!"
        );
        require(msg.value >= numberOfTokens * specialPrice, "Value error, please check price!");
        
        totalKnightsByHolder += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, 1 + totalKnights++);
        }
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
