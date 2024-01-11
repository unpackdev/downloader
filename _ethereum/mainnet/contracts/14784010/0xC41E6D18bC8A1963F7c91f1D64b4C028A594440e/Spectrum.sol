// SPDX-License-Identifier: MIT

                                                                                                                                    
//                                                                     .....                                                           
//                                                                  .........                                                          
//                                                                ......    ...                                                        
//                                                              ...........  ....                                                      
//                                                            .................''..                                                    
//                                                ...        ..,,..............'''..                                                   
//                                              ..''.....   ..,;,......... ........'..                                                 
//                                             .'''....'''...',,.....   ................                                               
//                                           ..''............'''....    .......      ..............                                    
//                                          ..'''............'','..    .......       ....''..........                                  
//                                       ..',,''.......';;;,'',,'.. .........      ...........    .....                                
//                                     ..',,,''.....'',,,,'.'''''''..'''....      .....  ......... .....                               
//                                .............';;'....'..'','.....................'''................''..                             
//                             ....',,'.......';cc,.....',;:,'......................,;;,'..............''''....                        
//                    ...',.........''.......';cc:'....,;::;,'''......... .   .......''''...............',,,'.......                   
//               .......',,'.........',,'...,;:;,.....',::;,'.... ........................'............'',,,'............              
//            ..';;;,.....'''......',,,'....,,,'.........''....    .....   ...............',,'...........'',,,,'',,,'.'''..            
//    ...'','',,;::;,'.'',;;,'..',,,,;;;;,,'',,,,,,;,'....''''...'''...................  ..'''........ ......',',,;;,''''''''......    
//   ...',,,'...........',,''.........',,,'......''..........'..'''.............                              ...............'.......  


//                         ...      .      ..........      .......                  .........              .        ........           
//              .,;.      .:xdc.   ':;.   .';loddoc;..   .;clc:clo:.              ..;coddoc;'.   .';.     .:;.    .;llc::;;'.          
//              .cl,.     .cOKOc.  ;dl'.    .,lddc..    .:dd;. .,coo,.              .':odl,.     .:l,.    ;ol,.   .coc,....            
//              .cl,.      ,lodoc'.,lc'      .:lc,.    .:ol,.    .;l:'.              .,cl;.      .:ol;''',lxl.    .col:,'...           
//              .:c,.      ;c,.;l:,:c;..     .;lc,.    .co:.      'c:,.              .,cc;.      .:ddlc::cdkl.    .cddlc::;..          
//              .cl,.     .:l,..'cdxd:.      .:ll;.    .;oo:.    .:o:'.              .,cl;.      .:l;.   .;dl'    .co:'....            
//              .cl,.     .:o;.  'lOOl.      .:ol;.     .;odc,.':odc'.               .,cl;.      .:l,     ,ol'.   .col:'.....          
//               ''.       .'.    .;c,        .,'.        .;cccccc,.                  .''.        .'.     .,'.     ';:::;;;,.          
//                                                           ....                                                      . .             

//               .'..                  ..'..             .':loool:'.               .''.          .''.       .,:ccc::;;::cc::'.         
//              .okd;.                 ,dko,           .cxkkxdodxkOxc,.            ,xkc.        'lxx;       .ldxxxk0KK0kxxxo:.         
//              'x0x:.                 ;k0x;.        .:x0Ol'.....,lk00k:.          ;OKo.        ,oOO:        ....'cOK0d;.....          
//              'dOx:.                 ;kOd;        .;O0o'        .'lxdc.          ;O0l.        'lkk:             'x0kc.               
//              'dOx:.                 ;xOd;       .;d0x,           ....           ;OKo'.      .,oOk:             'x0kc.               
//              'dOd:.                 ;kOd;       .lOOo.     .,:ccc::;'.          ,OX0xolloooookO0k;             'x0kc.               
//              'dOx:.                 ;xOd;.      .lOOo.     'cdxdxO00x:.         ;OXOoc::::::cdO0k;             'x0kc.               
//              'dOd:.                 ;xOd;       .;x0x,      ....,d0K0o'         ;O0l'.      .,okk:             'x0kc.               
//              'dOd;.                 ;kOd;        .:O0o'        .;kKXOc.         ;O0l.        'lkk:             'xKkc.               
//              'x0Oo;........         ;k0x;.        .cxOkl'.  ..;ok0KKkc.         ;OKo'        ,oOO:             ,kX0l.               
//              .lk0Okddddxxoc'.       ,dko,           'cxkkdlloxxocccll:'         ,xkc.        'lxx;             'dOxc.               
//               .';::::::::;,.        .''..             .,:cccc:;.   ....         .',.          .''.              .,'.                


pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract Spectrum is ERC721, Ownable {
    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    bool public isPublicMintEnabled;
    string internal baseTokenUri;
    string public hiddenMetadataUri;

    mapping(address => uint256) public WalletMints;

    bool public isRevealed;
    string public SPCTRM_PROVENANCE;

    constructor() payable ERC721('Spectrum', 'SPCTRM') {
        mintPrice = 0.25 ether; 
        totalSupply = 0;
        maxSupply = 35;
        maxPerWallet = 4;
        setHiddenMetadataUri("https://orion.mypinata.cloud/ipfs/QmaGS9TUuWT1sXADpjPXsL7Rs8fC67hZC4r1LCkwjpspC2"); 
        isRevealed = false;
        SPCTRM_PROVENANCE = "7a6c2121c04f3411a3268413a75e4e305d0ec5e65e304538da38f0ae6d5c52c5";
    }

    function setProvenance(string memory newProvenance) external onlyOwner{
        SPCTRM_PROVENANCE = newProvenance;
    }

    function setIsPublicMintEnabled(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function reveal() external onlyOwner {
        isRevealed = true;
    }

    function setHiddenMetadataUri(string memory hiddenMetadataUri_) public onlyOwner {
        hiddenMetadataUri = hiddenMetadataUri_;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {

        if (isRevealed == false) {
            return hiddenMetadataUri;
            }

        require(_exists(tokenId_), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }

    string private customContractURI = "https://orion.mypinata.cloud/ipfs/QmPzxrmCfn3iEAZXqzABRgiF98aZuD7xLDVfbp3F4uCEmZ";

    function setContractURI(string memory customContractURI_) external onlyOwner {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }

    function withdraw() external onlyOwner {
        address withdrawalWallet = msg.sender;
        (bool success, ) = withdrawalWallet.call{ value: address(this).balance }('');
        require(success, 'withdraw failed');
    }

    function mint(uint256 quantity_) public payable {
        require(isPublicMintEnabled, 'minting not enabled');
        require(msg.value >= quantity_ * mintPrice, 'wrong mint value');
        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        require(WalletMints[msg.sender] + quantity_ <= maxPerWallet, 'exceed max wallet');

        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            WalletMints[msg.sender]++;
            totalSupply++;
            _safeMint(msg.sender,newTokenId);
        }
    }
}
