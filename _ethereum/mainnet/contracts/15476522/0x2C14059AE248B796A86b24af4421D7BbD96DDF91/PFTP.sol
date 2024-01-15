// SPDX-License-Identifier: MIT

/*
 *    ________    ________  _________    ________   
 *   |\   __  \  |\  _____\|\___   ___\ |\   __  \  
 *   \ \  \|\  \ \ \  \__/ \|___ \  \_| \ \  \|\  \ 
 *    \ \   ____\ \ \   __\     \ \  \   \ \   ____\
 *     \ \  \___|  \ \  \_|      \ \  \   \ \  \___|
 *      \ \__\      \ \__\        \ \__\   \ \__\   
 *       \|__|       \|__|         \|__|    \|__|   
 *                                                  
 *
 *
 *    PFTP PROJECT
 *    Amended by github.com/rickliujh
 */

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract PFTP is ERC721Enumerable, Ownable {
  uint256 public mintPrice = 0.05 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxAddrMintNum = 2;
  uint256 public maxFreeMintAmount = 900;
  uint256 public openMintDuration = 60 days;
  bool public enable = true;
  string public baseURI = "ipfs://bafybeigvvf6x3szliylqn554sp6sokfgsvpmz5vmiay2w3klx7lp2udury/";

  uint256 public publishTime;
  address payable private founderAddr;
  address payable private cofounderAddr;
  mapping(address => bool) public whiteList;

  constructor(
    address payable  _founderAddr,
    address payable _cofounderAddr,
    address[] memory _initWhiteList
  ) payable ERC721("PFTP", "PFTP") {
    founderAddr = _founderAddr;
    cofounderAddr = _cofounderAddr;
    publishTime = block.timestamp;

    for (uint i = 0; i < _initWhiteList.length; i++) {
      setWhiteList(_initWhiteList[i]);
    }
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(enable, "the contract was discarded");
    require((_mintAmount + balanceOf(msg.sender) <= maxAddrMintNum) || (_mintAmount + balanceOf(_to) <= maxAddrMintNum), "you're trying to mint over limit");
    require(supply + _mintAmount <= maxSupply);
    
    if (!whiteList[msg.sender]) {
      require(((block.timestamp < publishTime + openMintDuration) && (supply + _mintAmount <= maxFreeMintAmount)) 
        || (msg.value >= mintPrice * _mintAmount), "you're not open to free mint");
    }

    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function getAddrTokenIds(address _addr)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_addr);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i = 0; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_addr, i);
    }
    return tokenIds;
  }

  //only owner
  function gain(address _to, uint _amount) public onlyOwner {
    uint256 supply = totalSupply();
    require(supply + _amount <= maxSupply);
    
    for (uint256 i = 0; i < _amount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function setEnable(bool _flag) public onlyOwner {
    enable = _flag;
  }

  function setMintPrice(uint256 _newPrice) public onlyOwner {
    mintPrice = _newPrice;
  }

  function setBaseURL(string memory _baseURL) public onlyOwner {
    baseURI = _baseURL;
  }

  function setOpenMintDuration(uint256 _duration) public onlyOwner {
    openMintDuration = _duration;
  }

  function setWhiteList(address _addr) public onlyOwner {
    whiteList[_addr] = true;
  }
 
  function removeWhiteList(address _addr) public onlyOwner {
    delete whiteList[_addr];
  }

  function setFounderAddr(address payable _addr) public onlyOwner {
    founderAddr = _addr;
  }

  function setCofounderAddr(address payable _addr) public onlyOwner {
    cofounderAddr = _addr;
  }

  function withdraw() public payable onlyOwner {
    (bool hs1, ) = payable(cofounderAddr).call{value: address(this).balance / 2}("");
    require(hs1);

    (bool hs2, ) = payable(founderAddr).call{value: address(this).balance}("");
    require(hs2);
  }
}