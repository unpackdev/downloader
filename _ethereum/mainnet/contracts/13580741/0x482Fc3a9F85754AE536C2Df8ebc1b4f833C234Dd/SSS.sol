// SPDX-License-Identifier: MIT




pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

/**
███╗   ██╗███████╗████████╗██╗  ██╗██╗███╗   ██╗ ██████╗ ███╗   ███╗ █████╗ ██╗  ██╗███████╗██████╗     ██████╗ ██████╗ ███╗   ███╗
████╗  ██║██╔════╝╚══██╔══╝██║ ██╔╝██║█S███╗  ██║██╔════╝ ████╗ ████║██╔══██╗██║ ██╔╝██╔════╝██╔══██╗   ██╔════╝██╔═══██╗████╗ ████║
██╔██╗ ██║█████╗     ██║   █████╔╝ ██║██╔██╗ ██║██║  ███╗██╔████╔██║███████║█████╔╝ █████╗  ██████╔╝   ██║     ██║   ██║██╔████╔██║
██║╚██╗██║██╔══╝     ██║   ██╔═██╗ ██║██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗   ██║     ██║   ██║██║╚██╔╝██║
██║ ╚████║██║        ██║   ██║  ██╗██║██║ ╚████║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██╗███████╗██║  ██║██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
╚═╝  ╚═══╝╚═╝        ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝
                                                                                                                                   */


contract SlimSalamanderSquad is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Strings for uint256;
    
    // Set variables
    
    uint256 public SSS_SUPPLY = 10000;
    uint256 public SSS_PRICE = 60000000000000000 wei;
    bool private _saleActive = false;
    bool private _presaleActive = false;
    uint256 public constant presale_supply = 1000;
    uint256 public  maxtxinpresale = 20;
    uint256 public  maxtxinsale = 30;
    bool public iswhitelistrequired= true;
    mapping(address => bool) public whitelist;
    address ownerrr= 0xE01BffaE3d183440DD2224C9c2433c14b9F0C041;
    address nftkingmaker= 0x0ECbE30790B6a690D4088B70dCC27664ca530D55;



    string public _metaBaseUri = "https://slimsalamandersquad.com/unreveal/sss/";
    
    // Public Functions
    
    constructor() ERC721("Slim Salamander Squad", "SSS") {
        
        
    }
    
    function PUBLICSALEMINT(uint16 numberOfTokens) public payable {
        require(_saleActive==true, "SSS sale not active");
        require((totalSupply() + numberOfTokens) <= SSS_SUPPLY, "Sold Out");
        require((SSS_PRICE *numberOfTokens) <= msg.value, "Ether amount sent is incorrect");
        require(numberOfTokens<=maxtxinsale, "Max 30 are allowed" );

        _mintTokens(numberOfTokens);
    }
    
     function PRESALEMINT(uint16 numberOfTokens) public payable {
        require(_presaleActive==true, "Presale Of SSS is not active");
         if(iswhitelistrequired==true){
        require(whitelist[(msg.sender)]== true, "Not whitelisted is not active");
         }
         if(iswhitelistrequired==false){
        
        require((totalSupply()+numberOfTokens) <= presale_supply, "Insufficient supply, Try in public sale");
        require((SSS_PRICE *numberOfTokens) <= msg.value, "Ether amount sent is incorrect");
        require(numberOfTokens<=maxtxinpresale, "Max 20 are allowed" );
        _mintTokens(numberOfTokens);
    
         
         }
         
     }
    
    
    function mintgiveaway(address notforyou , uint16 numberOfTokens) external onlyOwner {
          for (uint16 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(notforyou, tokenId);
        }
    }
    
    function isSaleActive() public view returns (bool) {
        return _saleActive;
    }
    
    function ispreSaleActive() public view returns (bool) {
        return _presaleActive;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "", uint256(tokenId).toString()));
    }
    
    // Owner Functions

    function Changesalestatus() public onlyOwner {
        _saleActive = !_saleActive;
    }
    
    function shouldrequirewhitelist() public onlyOwner {
        iswhitelistrequired = !iswhitelistrequired;
    }
    
    function Changepresalestatus() public onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
    }
    
    function setsupply(uint256 _SSSupply ) external onlyOwner {
        SSS_SUPPLY = _SSSupply;
    }
    
    function withdrawAll() external onlyOwner {
        
                uint256 _70percent = address(this).balance*70/100;
                uint256 _30percent = address(this).balance*30/100;
                require(payable(ownerrr).send(_70percent));
                require(payable(nftkingmaker).send(_30percent));    
        
    }

    // Internal Functions
    
    function _mintTokens(uint16 numberOfTokens) internal {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
    }

    function _baseURI() override internal view returns (string memory) {
        return _metaBaseUri;
    }
    
    function addaddrtowhitelist(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length ; i++){
            whitelist[_address[i]] = true;
    }}
    
    function removeaddrfromwhitelist(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length ; i++){
            whitelist[_address[i]] = false;
    }}
    
    
    function veiwifwhitelisted(address _address) public view returns (bool) {
       return whitelist[_address];
    }
    

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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