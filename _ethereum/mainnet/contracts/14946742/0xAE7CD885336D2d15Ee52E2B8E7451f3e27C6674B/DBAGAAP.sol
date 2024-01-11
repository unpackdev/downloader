// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./WhiteList.sol";

contract DBAGAAP is ERC721Enumerable, Ownable {
  using Strings for uint256;
  
  WhiteList wl1 = new WhiteList(10);
  WhiteList wl2 = new WhiteList(10);
  WhiteList wl3 = new WhiteList(40);
  WhiteList wl4 = new WhiteList(40);
 
  address public DBAGNFTAddress = 0x0000000000000000000000000000000000000000;
  address public DBAGMPAddress = 0x0000000000000000000000000000000000000000;
  string public baseURI;
  uint256 public cost = 0.15 ether;
  uint256 public maxSupply = 20000;
  bool public pM = true;
  bool public pR = true;
  
  constructor(string memory _name, string memory _symbol, string memory _ipfsURI) 
  ERC721(_name, _symbol) {
    setBaseURI(_ipfsURI);
  }

  //=================================INTERNAL FUNCTIONS================================//
  function _baseURI() internal view virtual override returns (string memory) {return baseURI;}

  //=================================PUBLIC FUNCTIONS================================//
  function redeem(uint256 _tokenId) public {
    require(!pR, "Paused");
    require(DBAGNFTAddress != 0x0000000000000000000000000000000000000000, "Redeem contract address missing");
    uint256[] memory tokensFromAddress = walletOfOwner(msg.sender);
    require(tokensFromAddress.length > 0, "No pass to redeem");
    address[] memory addressArray = new address[](1);
    addressArray[0] = msg.sender;
    safeTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _tokenId);
    bytes memory payloadNFT = abi.encodeWithSignature("redeemNFT(address[],uint256)", addressArray, _tokenId);
    (bool successNFT, ) = address(DBAGNFTAddress).call(payloadNFT);
    require(successNFT, "redeemNFT FAIL");
    bytes memory payloadMP = abi.encodeWithSignature("redeemMP(address[],uint256)", addressArray, _tokenId);
    (bool successMP, ) = address(DBAGMPAddress).call(payloadMP);
    require(successMP, "redeemMP FAIL");
  }

  function mint(uint256 _mintAmount) public payable {
    require(!pM, "Paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0 && _mintAmount <= 20, "Need to mint 1 to 20");
    require(supply + _mintAmount <= (maxSupply - wl1.nbWLSCValue() - wl2.nbWLSCValue() - wl3.nbWLSCValue() - wl4.nbWLSCValue()), "NFT limit exceeded");
    require(msg.value >= cost * _mintAmount, "Insufficient funds");
    for (uint256 i = 1; i <= _mintAmount; i++) {_safeMint(msg.sender, supply + i);}
  }

  function whiteListMintForContest1() public {
    require(!pM, "Paused");
    wl1.WLM(msg.sender);
    _safeMint(msg.sender, totalSupply() + 1);
  }
  function whiteListMintForContest2() public {
    require(!pM, "Paused");
    wl2.WLM(msg.sender);
    _safeMint(msg.sender, totalSupply() + 1);
  }
  function whiteListMintForContest3() public {
    require(!pM, "Paused");
    wl3.WLM(msg.sender);
    _safeMint(msg.sender, totalSupply() + 1);
  }
  function whiteListMintForContest4() public {
    require(!pM, "Paused");
    wl4.WLM(msg.sender);
    _safeMint(msg.sender, totalSupply() + 1);
  }
  function isWL1() public view returns (bool){return wl1.isWL(msg.sender);}
  function isWL2() public view returns (bool){return wl2.isWL(msg.sender);}
  function isWL3() public view returns (bool){return wl3.isWL(msg.sender);}
  function isWL4() public view returns (bool){return wl4.isWL(msg.sender);}
  function isWLM1() public view returns (bool){return wl1.isWLM(msg.sender);}
  function isWLM2() public view returns (bool){return wl2.isWLM(msg.sender);}
  function isWLM3() public view returns (bool){return wl3.isWLM(msg.sender);}
  function isWLM4() public view returns (bool){return wl4.isWLM(msg.sender);}
  
  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {tokenIds[i] = tokenOfOwnerByIndex(_owner, i);}
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: nonexistent token");
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")): "";
  }
  
  //=================================ONLY OWNER FUNCTIONS================================//
  function setBaseURI(string memory _newBaseURI) public onlyOwner {baseURI = _newBaseURI;}
  function pauseMint(bool _state) public onlyOwner {pM = _state;}
  function pauseRedeem(bool _state) public onlyOwner {pR = _state;}
  function setDBAGNFTAddress(address _DBAGNFTAddress) public onlyOwner{DBAGNFTAddress = _DBAGNFTAddress;}
  function setDBAGMPAddress(address _DBAGMPAddress) public onlyOwner{DBAGMPAddress = _DBAGMPAddress;}
  function WLA1(address[] calldata _user) public onlyOwner{for (uint256 i; i < _user.length; i++) {wl1.WLA(_user[i]);}}
  function WLA2(address[] calldata _user) public onlyOwner{for (uint256 i; i < _user.length; i++) {wl2.WLA(_user[i]);}}
  function WLA3(address[] calldata _user) public onlyOwner{for (uint256 i; i < _user.length; i++) {wl3.WLA(_user[i]);}}
  function WLA4(address[] calldata _user) public onlyOwner{for (uint256 i; i < _user.length; i++) {wl4.WLA(_user[i]);}}

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(os);
  }
}