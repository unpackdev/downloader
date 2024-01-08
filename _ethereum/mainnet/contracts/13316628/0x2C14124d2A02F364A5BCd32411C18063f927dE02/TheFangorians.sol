// SPDX-License-Identifier: MIT
/*
                                                                                                                        
                                                                                                                        
                                                                                                                        
                                                  .;;,'...                                                              
                                                  .,oOXXK0x,                                                            
                                                     .dNMWWOc'                ,l,                                       
                                                      ,0WWWWWx.               .dKk:.                                    
                                .'.                   .OWWMMWNk'               ;XWNO:.                                  
                           .':okKNKd;.                ,0WWMWWWW0:             .dNWWWx.                                  
                         .'cdxkKWMMWN0d:'.     ..';:clOWWWMMWWMMNkl:;'.      'xNWMWNc                                   
                               .l0WWWMMNX0xoodk0XNWWMMWWMMMWMMMMMMMMWNKOdo:,lKWWMMM0,                                   
                                 .xNMWWWWWWMWWMMMWWWNNXKK00000KXXNWMMMMMMMMWWMWMMWWk.                                   
                                  'kWWWMMWMMWNKOxoc;,'...........';:cdk0XWWWMWWMWWMk.                                   
                                .ckXWWWMWNOdc,.      .....'''....      ..;lkKWMMWWWNx,            .;'                   
                              .l0WMWMWXkc'.   .,:ldkO0KXNNNNNNXXKOkxoc,.    .;d0NWWWWXk;.         ,Oo                   
                            .o0WWWWN0l'   .;lkKNMMMMMMMMMMWWWMMMMMMMMMWXOd:.   .;xKWWWMNk;.      .xNK;                  
                          .c0WWWWNk;.  .:dKWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl'   .oKWMMMXx'  .;l0WMWx.                 
               'oxxddddxxk0NWWWWO;.  'o0WWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWXx;.  .oXWWWWKkkKNWWWMXo.                 
              ;0WMMWMMMMMMMMWWKl.  ,dKWMWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMWNO:.  'kNWWWWMMWWWKd'                   
            .l00kOOKNWWMWMMWWO,  .oXWWWMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMNk;  .lXMMMWMMNk,                     
           .:l,.   .'c0MWWWWk.  ,ONWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWKl.  cXMMWWNd.                      
                     ,KMMMWk.  ;KMWWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNd.  cXMWWWo.                      
                    .kWMWWK,  ;KMMMWWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMWWo   oNMWWN:                      
                    cNMMMNl  'OWWMMWWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0OO0XNMMWWMMMWNc  .OMWWWk.                     
                   .xMMMWO'  oWMMMW0xKNWWWWWWWWMMMMMMMMMMMMMMMMMMWWMNOl;..  ..;xXMMMMMMMO.  lWMMMX:                     
                   '0MMMWo  'OWWWMWo..,lOXWMMMWWMMMMMMMMMMMMMMMMWWNk,.          :KMMMMMMNc  ,0MMWWd        ..           
                   ;XMWMWc  ;XMMMWWk.    'cxKWWWMMMMMMMMMMMMMMMMWKc.            .dWMMMMMMd  .kMWWWx.     .ox'           
                  .oNWWMNc  :NMWMMWX:       .;lkXWMMMMMMMMMMMMMMXc               dMWWMMMMx. .kMMMMKdlcloxKXc            
               .;o0NWWWMNc  ;XMWMMMWO,          .:dONMMMMWWMMMWWx.              '0MWWMMWMd  .OMMMMWMMWWWMWx.            
            .cxKNWWWWMMMWo  'OWWMMMWW0;            .,ckKNMMMMMWWd              'OWMWWMWMWc  ,KWWMWMMWNXK0x,             
            ;XWWWWWNWMMMMO.  oWMWMMMWWXd;.            .lKWMWMMMWO,           .c0MMMMMMWW0'  lWMMWNOoc;'..               
            ;XNOoc,,oXMWWNl  'OWWMMWWWMMN0xl:,,'',:cokKNWMMMMMWWWO;.      .'cONWMMMMWMWNl  .OMWMMk.                     
            :Ko.    .xWWMM0,  ;KWWMMMMMMMMMMMWWWWWMMMMMMMWWMMMMMMMN0xollox0NWWMMWWWWWMNd. .oWWWMX:                      
            ,c.      '0MWWWk.  :KWWWMMMMMMMMMMMMMMMMMMMWWMMWWMMWMMMMMMMWWMMMMMMMMWWMMNx.  lNMWWWd.                      
                      :KWWWWk.  ;OWMMMMMMMMMMMMMMMMMMMMWNWMMWWNWMMWWMMMMMMMMMMMMMMWWNo.  cXWMWNx.                       
                       :KWWMWO,  .dNMMMMMMMMWMMMMMMMMW0:oNWWWO:dNMWWMWWMMMMMWMMMWWNO;  .oNMWWNx.                        
                        ;0WWMMXl.  ,xXWMMWWMMMMMMMMMWx. cNMMMx..cXWMMWMMWWWMWWMMNOc.  ;OWWWMNd.                         
                         'xWMWWWO:. .,xXWMWWMWWMWWWWXl,:kWWWW0l;:OWMMMMMMMMWWMNOc.  .dNMMWMWx.                          
                         .dWMMMWWNO:.  .l0MMMWWMMMMMWWWWMMWMMMMWNWMMMMWMMMMMNx,.  'oKWWWMWWWXOo:,,;c:.                  
                        .oNWMWMWWWWW0c.  dWWWWWMMMMWMWWMMMMMMMMWMMMMMWMMMMMWO'  ,xXWMMWWWWMWWWWWNKkc.                   
                       .oNMWWXkd0WWWWX;  oMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0' .xMWWWNk:,:ldk0XKd,                      
                       .xWWWK:  .:xXWX;  oMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .xMNOl'       ...                        
                        .oXNc      .co,  oMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO' .cd,.                                    
                          cOc            oMMMWWMMXXMWWMMMMMMMMMMMMWXKNWMMMMWO'                                          
                           ',            oWMMMMWX::XWWWWMMMMMMMMMWMx'xWMMMMMO.                                          
                                         cNMMMMWd..dkdoolllllloodxk; ;XMMMMMk.                                          
                                         ;XMMMMK;                    .xWMMMMd                                           
                                         '0MMMMk.                     cNMMWWl                                           
                                         .xWMWWd                      ;XMMMX;                                           
                                          cNMMWl                      '0MWWk.                                           
                                          .OMMN:                      .OMMNc                                            
                                           cNMX;                      .kMWx.                                            
                                           .xWX;                      .xMK,                                             
                                            'OX;                      .xXc                                              
                                             ,k:                      .xo                                               
                                              ..                      .'.                                               
                                                                                                                        
                                                                                                                        
                                                                                                                        
                                                                                                                        
*/
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract TheFangorians is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;

    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant PRICE_PER_TOKEN = 0.045 ether;

    mapping(address => uint8) private _allowList;

    constructor() ERC721("The Fangorians", "FANG") {
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
