// SPDX-License-Identifier: MIT

//                        OTHERHOMES                                                                     
//          ...,,,..                                                     
//       pGCCG######Q__^^":.                                             
//      #pCCCC@QQQQQ###pp,___^"*,.                                       
//     .#bCC_^Gb'^^78%##Qb8##Np,__^*:.                                   
//     ;@#pG___?l,    @##bCfTW@###p,__^?*,                               
//     ?C8#po___'GG:  ]#N#CC_   '%@###Np,_^*Gl;,.                        
//     lCC9@Np;,___^*G78@#pC,        "@########ppC__^^^~.._              
//     CCCC$$#NpG;,____`__^+;, ________ |"7799bT8WWNSp;,,.__^.           
//     CCCC@#ba@###Qo;,_______^**!*;:,,________________|^@#p;_"_         
//    !CCOZ#S##bC_|@@#NpGo;;,,::,_______^^*:,_________,;G@Q#p__          
//    GC@##Q#####Sppvp@@####QpCCCCGo;,_______",__,;oGQ##bb2@b~_          
//    C9##b9922$988$@QQ##Q$@#######QQpCG,______9pQ#WbCCC?^jCGp_          
//   :C##bCCC^__^^**?GGGC9288W####@@@###QG:____'9CCC*^_.:GG##bG          
//   CG##pCCCo;,,,___________`^^**992@88@#CG#@#bOCv_.;G#@####bC          
//  !C@#S##"WN#QpOCCCCGGGo;;:,,,________`8DG#@##CQQ##W^ @####bC          
//  CG##@#b      ^78W@###QQQpGCCCCCGGoo;:,C8#@N#C@b`    8####bC          
// lC##Q##                 ^^2""%W@#####QpC@Q@b#C         "8"^^          
// *G##@#b                            '^^CC@Q#bQC_                       
//                                       CG#@#b#p                        
//                                      'C@#@###b                        
//                                      !C##@#b#b                        
//                                      ^G####b#C                        

                                                                                


pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract OtherHomes is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.04 ether;
  uint256 public maxSupply = 1111;
  uint256 public maxMintAmount = 25; 
  bool public paused = false;

  constructor(string memory _initBaseURI) ERC721("otherhomes", "HOME") {
    setBaseURI(_initBaseURI);
    //mints # to team/ contract owner for drops etc.
    mint(msg.sender, 25);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "sale not active");
    require(_mintAmount > 0, "mint more than 0");
    require(_mintAmount <= maxMintAmount, "exceeds max tokens per tx");
    require(supply + _mintAmount <= maxSupply, "exceeds tokens left");


    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount, "not enough ether to claim");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    //make sure i is less than token acocunts
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
  
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : "";
  }

  //only owner

  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }
  
  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }
    
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
    
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}