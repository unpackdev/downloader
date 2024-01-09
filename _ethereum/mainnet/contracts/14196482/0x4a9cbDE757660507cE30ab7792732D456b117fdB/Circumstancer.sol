// SPDX-License-Identifier: MIT
// Website: https://circumstancer.com

//       ..----.`                 `.----.`             .----.`            
//   ./ossssssssso/.           ./osssssssso/.       -+sssooosso/-         
//  /so/-.`   `.:oss:        .+ss/-`    `-/os-    `+ss/.`   `./ss+`       
//   .           .sss       .sso.           `     +ss-         .sso`      
//               `sss`     `oso`                 .ss+           +ss/      
//               /ss:      :ss:    `...`         .sso           +sss`     
//       ....--/os+.       +ss. -/ossssss+-`      +ss/         :soss.     
//      -ssssssss+-`       oss-+o/.````-/sso-     `/sso:.```.:oo-+ss.     
//           ``.:+ss/      osso+`        .oss.      ./ossssso+:` oss`     
//                /ss/     /sss.          -ss/          ````    `sso      
//                .sso     .sss.          -ss/                  /ss-      
//  ``            /ss/      :ss+         `oss.    ``          `/ss/       
// `sso/-.`   `.-+ss+`       :oso:.   `.:oso-     oso:.`   `./oso-        
//  `-/ossssssssso/.          `:+ssssssss+:`      `-+ossssssso+-          
//       `.---..`                 ..--..              `.---.`             

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract Circumstancer is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    string  private baseURIextended;
    uint256 public  RESERVED        = 100;
    uint256 private MAX_MINT        = 6;
    uint256 private MAX_MINT_WL     = 3;
    uint256 public  PRICE           = 0.48 ether;
    uint256 public  PRICE_WL        = 0.21 ether;
    uint256 public  MAX_SUPPLY      = 6000;
    uint256 public  MAX_SUPPLY_WL   = 1800;
    uint256 public  WL_SPOTS        = 1500;
    bool    public  STATUS_PUBLIC   = false;
    bool    public  STATUS_WL       = false;
    bool    public  ENABLED_ADD_WL  = false;
    address private mainAddress;
    mapping(address => uint256) public whitelisted;

    constructor(string memory _baseURI) ERC721 ("Circumstancer", "C369") {
        mainAddress = msg.sender;
        baseURIextended = _baseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURIextended = newBaseURI;
    }

    function baseURI() public view returns (string memory) {
        return baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = baseURI();
        string memory _tokenURI = tokenId.toString();

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function setStatusWLSale(bool newState) public onlyOwner {
        STATUS_WL = newState;
    }

    function setStatusSale(bool newState) public onlyOwner {
        STATUS_PUBLIC = newState;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    function changeStatusAddWL(bool status) public onlyOwner {
        ENABLED_ADD_WL = status;
    }

    function setAddress(address _mAddress) public onlyOwner {
        mainAddress = _mAddress;
    }

    function addMeToWhitelist() public callerIsUser {
        require(ENABLED_ADD_WL, "Aggregation to the Whitelist has not been enabled");
        require(WL_SPOTS > 0, "The Whitelist is full");
        require(whitelisted[msg.sender] == 0, "You are already part of the Whitelist");
        WL_SPOTS--;
        whitelisted[msg.sender] = MAX_MINT_WL;
    }

    function mintWL(uint numberOfTokens) public payable callerIsUser {
        uint256 supply = totalSupply();
        uint256 quantityAvailable = whitelisted[msg.sender];
        
        require(STATUS_WL, "WL must be active to mint tokens");
        require(numberOfTokens <= MAX_MINT_WL, "Exceeded max token purchase in the WL");
        require(quantityAvailable > 0, "You are not allowed to shop at the WL");
        require(numberOfTokens <= quantityAvailable, "You exceed the maximum amount per wallet");
        require(numberOfTokens <= MAX_SUPPLY_WL, "Purchase would exceed max tokens in the WL");
        require(PRICE_WL * numberOfTokens <= msg.value, "Ether value sent is not correct");

        MAX_SUPPLY_WL -= numberOfTokens;
        whitelisted[msg.sender] -= numberOfTokens;
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
        if ( MAX_SUPPLY_WL == 0 ) {
            STATUS_WL = false;
        }
    }
    
    function mint(uint numberOfTokens) public payable callerIsUser {
        uint256 supply = totalSupply();
        uint256 ownerSupply = balanceOf(msg.sender);

        require(STATUS_PUBLIC, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_MINT, "Exceeded max token purchase");
        require(ownerSupply + numberOfTokens <= MAX_MINT, "You exceed the maximum amount per wallet");
        require(supply + numberOfTokens <= MAX_SUPPLY - RESERVED, "Purchase would exceed max tokens");
        require(PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require( _amount <= RESERVED, "Exceeds Reserved Circumstancer Supply" );
        RESERVED -= _amount;
        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= _amount; i++){
            _safeMint( _to, supply + i );
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(mainAddress).transfer(balance);
    }
}