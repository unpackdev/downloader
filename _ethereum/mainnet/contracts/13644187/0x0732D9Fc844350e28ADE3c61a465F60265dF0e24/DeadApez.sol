// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*(                                           )  
 )\ )            (        (               ( /(  
(()/(    (    )  )\ )     )\            ( )\()) 
 /(_))  ))\( /( (()/(  ((((_)(  `  )   ))((_)\  
(_))_  /((_)(_)) ((_))  )\ _ )\ /(/(  /((_)((_) 
 |   \(_))((_)_  _| |   (_)_\(_|(_)_\(_))|_  /  
 | |) / -_) _` / _` |    / _ \ | '_ \) -_)/ /   
 |___/\___\__,_\__,_|   /_/ \_\| .__/\___/___|  
                               |_|              
DeadApez 2021. 
*/


import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";



contract DeadApez is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant dapezMax = 5000;
    uint256 public constant purchaseLimit = 12;


    uint256 private dapezPrice = 0.06 ether;

    uint256 public amountMinted;
    bool public saleLive;

    
    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';
    

    constructor() ERC721("Dead Apez", "DAPEZ") { 
        
    }
    

    
 function mint(uint256 numberOfTokens) external payable {
    require(!saleLive, 'Contract is not active');
    require(totalSupply() < dapezMax, 'No Tokens Left');
    require(numberOfTokens <= purchaseLimit, 'You are over the minting max');
    require(amountMinted + numberOfTokens <= dapezMax, 'No Tokens Left');
    require(dapezPrice * numberOfTokens <= msg.value, 'ETH amount is not enough');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (amountMinted < dapezMax) {
        uint256 tokenId = amountMinted + 1;
        amountMinted += 1;
        _safeMint(msg.sender, tokenId);
      }
    }
  }
  


  function gift(address[] calldata to) external onlyOwner {
    require(totalSupply() < dapezMax, 'No Tokens Left');
    require(amountMinted + to.length <= dapezMax, 'No tokens left');

    for(uint256 i = 0; i < to.length; i++) {
      uint256 tokenId = amountMinted + 1;

      amountMinted += 1;
      _safeMint(to[i], tokenId);
    }
  }
   

    
  function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    

  function setContractURI(string calldata URI) external onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external onlyOwner {
    _tokenBaseURI = URI;
  }

  function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
    _tokenRevealedBaseURI = revealedBaseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }   
    function setPrice(uint256 _newPrice) public onlyOwner() {
        dapezPrice = _newPrice;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint share1 = balance * 35 / 100;
        payable(0xD15994093E9E4Ae37B0f71597e8511DF3923BBAe).transfer(share1);
        payable(0x8394F023cA9FD93a42D1C5F156e428D88f25b299).transfer(balance - share1);
    }
}
