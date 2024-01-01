/*
https://www.gnomescollective.xyz/

https://t.me/HungerGameserc20

https://twitter.com/HungerGamesERC
*/


// SPDX-License-Identifier: MIT

//░██████╗░███╗░░██╗░█████╗░███╗░░░███╗███████╗░██████╗
//██╔════╝░████╗░██║██╔══██╗████╗░████║██╔════╝██╔════╝
//██║░░██╗░██╔██╗██║██║░░██║██╔████╔██║█████╗░░╚█████╗░
//██║░░╚██╗██║╚████║██║░░██║██║╚██╔╝██║██╔══╝░░░╚═══██╗
//╚██████╔╝██║░╚███║╚█████╔╝██║░╚═╝░██║███████╗██████╔╝
//░╚═════╝░╚═╝░░╚══╝░╚════╝░╚═╝░░░░░╚═╝╚══════╝╚═════╝░

//░█████╗░░█████╗░██╗░░░░░██╗░░░░░███████╗░█████╗░████████╗██╗██╗░░░██╗███████╗
//██╔══██╗██╔══██╗██║░░░░░██║░░░░░██╔════╝██╔══██╗╚══██╔══╝██║██║░░░██║██╔════╝
//██║░░╚═╝██║░░██║██║░░░░░██║░░░░░█████╗░░██║░░╚═╝░░░██║░░░██║╚██╗░██╔╝█████╗░░
//██║░░██╗██║░░██║██║░░░░░██║░░░░░██╔══╝░░██║░░██╗░░░██║░░░██║░╚████╔╝░██╔══╝░░
//╚█████╔╝╚█████╔╝███████╗███████╗███████╗╚█████╔╝░░░██║░░░██║░░╚██╔╝░░███████╗
//░╚════╝░░╚════╝░╚══════╝╚══════╝╚══════╝░╚════╝░░░░╚═╝░░░╚═╝░░░╚═╝░░░╚══════╝

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC721Enumerable.sol";

contract GnomesCollective is Ownable, DefaultOperatorFilterer, ERC721Enumerable {
  using Strings for uint256;
  bytes32 root;
  bytes32 emptyBytes32 = keccak256(abi.encodePacked(''));
  uint256 public cost = 0.0069420007 ether;
  uint256 public maxSupply = 2888;
  uint256 public maxMintAmount = 10;
  uint256 public mintAmount;
  bool public paused = true;
  bool public revealed = false;
  string private notRevealedUri;
  string private notRevealedUri2;
  string private CID;
  mapping(uint256 => address) private requestToSender;
  
  constructor(
    string memory _notRevealedUri,
    string memory _notRevealedUri2,
    string memory _CID,
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) { 
    mintAmount = 0;
    mint(10); 
    notRevealedUri = _notRevealedUri;
    notRevealedUri2 = _notRevealedUri2;
    CID = _CID;
  }

  function mint(uint256 _mintAmount) public payable {
    if(msg.sender != owner()){                                         
      require(!paused, 'Minting is paused');
      require(_mintAmount <= maxMintAmount);
      require(msg.value >= (cost)*_mintAmount);
     }
      require(_mintAmount > 0);
      require(totalSupply() + _mintAmount <= maxSupply, 'SOLD OUT');

        for (uint256 i=0; i<(_mintAmount); i++){
        requestToSender[totalSupply() + 1] = msg.sender;
        _safeMint(msg.sender, totalSupply() + 1);
        mintAmount++;
        }

  }
  
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
      if(tokenId % 2 ==0){
        return notRevealedUri;
      } else{
        return notRevealedUri2;
      }

    }
    return string(abi.encodePacked("ipfs://", CID, "/", (tokenId).toString(), ".json"));
  }

  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function getRoot() public view onlyOwner returns(bytes32){
    return root;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function getMintAmount() public view returns (uint256){
    return mintAmount;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os,'not os');
  }

  function transferFrom(
        address from,
        address to,
        uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
  }
  
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory data
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId, data);
  }
    }