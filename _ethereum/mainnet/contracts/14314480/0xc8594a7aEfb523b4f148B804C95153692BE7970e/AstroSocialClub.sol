// SPDX-License-Identifier: MIT


import "./ERC721.sol";
import "./Ownable.sol";


/**

Developed and Deployed By:

███╗   ██╗███████╗████████╗██╗  ██╗██╗███╗   ██╗ ██████╗ ███╗   ███╗ █████╗ ██╗  ██╗███████╗██████╗     ██████╗ ██████╗ ███╗   ███╗
████╗  ██║██╔════╝╚══██╔══╝██║ ██╔╝██║█S███╗  ██║██╔════╝ ████╗ ████║██╔══██╗██║ ██╔╝██╔════╝██╔══██╗   ██╔════╝██╔═══██╗████╗ ████║
██╔██╗ ██║█████╗     ██║   █████╔╝ ██║██╔██╗ ██║██║  ███╗██╔████╔██║███████║█████╔╝ █████╗  ██████╔╝   ██║     ██║   ██║██╔████╔██║
██║╚██╗██║██╔══╝     ██║   ██╔═██╗ ██║██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗   ██║     ██║   ██║██║╚██╔╝██║
██║ ╚████║██║        ██║   ██║  ██╗██║██║ ╚████║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██╗███████╗██║  ██║██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
╚═╝  ╚═══╝╚═╝        ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝

For more information visit us on : https://www.nftkingmaker.com/


                                                                                                                                   */

pragma solidity ^0.8.6;



contract AstroSocialClub is ERC721, Ownable {
    
    using Strings for uint256;
    
    bool public isSale = false;
    bool public preSale = false;

    uint256 public currentToken = 1;
    uint256 public maxSupply = 10000;
    uint256 public price = 0.10 ether;
    string public metaUri= "";
    bool public re=true;



    constructor() ERC721("Astro Social Club", "Astro Social Club NFT") {
            
        for (uint256 i = 0; i < 1; i++) {
            _safeMint(msg.sender, currentToken);
            currentToken = currentToken + 1;
        }}
    
    


    // Mint Functions

    function mint(uint256 quantity) public payable {
        require(isSale==true, "Public Sale is Not Active");
        require((currentToken + quantity) <= maxSupply, "Quantity Exceeds Tokens Available");
        require((price * quantity) <= msg.value, "Ether Amount Sent Is Incorrect");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, currentToken);
            currentToken = currentToken + 1;
        }
    }


    // Owner Mint Functions


    function ownerMint(address[] memory addresses) external onlyOwner {
        require((currentToken + addresses.length) <= maxSupply, "Quantity Exceeds Tokens Available");
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], currentToken);
            currentToken = currentToken + 1;
        }
    }

  


    function tokenURI(uint256 tokenId) override public view returns (string memory) {

        if(re==true)
        {
        return string(abi.encodePacked(_baseURI()));

        }
        else{
        return string(abi.encodePacked(_baseURI(), "", uint256(tokenId).toString()));

    }
    }

    function totalSupply() external view returns (uint256) {
        return currentToken-1;
    }
    
    function triggerSale() public onlyOwner {
        isSale = !isSale;
    }



    function setMetaURI(string memory newURI) external onlyOwner {
        re=false;
        metaUri = newURI;
    }

    function setre() external onlyOwner{
        re= !re;

    }

    function setsupply(uint256 maxxsupply) external onlyOwner {
        maxSupply = maxxsupply;
    }

    // Withdraw Function - onlyOwner

    function withdraw() external onlyOwner {
        require(payable(0x8d17196B8dea424172E31eFc3DE4267989ADa7b7).send(address(this).balance));
    }

    // Internal Functions

    function _baseURI() override internal view returns (string memory) {
        return metaUri;
    }
    
}