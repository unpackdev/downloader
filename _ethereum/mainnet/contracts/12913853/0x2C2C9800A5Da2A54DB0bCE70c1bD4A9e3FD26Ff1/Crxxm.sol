// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  .g8"""bgd
.dP'     `M
dM'       `     `7Mb,od8     `7M'   `MF'    `7M'   `MF'    `7MMpMMMb.pMMMb.
MM                MM' "'       `VA ,V'        `VA ,V'        MM    MM    MM
MM.               MM             XMX            XMX          MM    MM    MM
`Mb.     ,'       MM           ,V' VA.        ,V' VA.        MM    MM    MM
  `"bmmmd'      .JMML.       .AM.   .MA.    .AM.   .MA.    .JMML  JMML  JMML.
*/

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Crxxm is ERC721Enumerable, Ownable {

  uint public constant MAX_SUPPLY = 8888;
  uint public price;
	string _baseTokenURI;
	bool public paused;

  // team wallets
  address public t1 = 0xbef231D151d9e6dDafe6b9b646E586D9956279a8; // 20%
  address public t2 = 0xF200fe2893c7fBd64b0e8eb9A383dd9Ee1947b0E; // 20%
  address public t3 = 0xdd7Ae672443D17A5d4F565C7395cE0236ee737C4; // 20% 

  // community wallets
  address public designWallet = 0x1D052559CD02a5343F5330FB0ccf4a5a24e0eC37; // 20%
  address public marketingWallet = 0xeA2996E63b19A824B01AF329D4733e291D6EB680; // 10%
  address public charityWallet = 0xb3245aa1209B28dDeFd42453A107e84478056201; // 10%

  constructor(string memory baseURI) ERC721("Crxxm", "CRXXM")  {
      setBaseURI(baseURI);
      paused = true;
      price = 30000000000000000; // 0.03 ETH
  }

  modifier saleIsOpen{
      require(totalSupply() < MAX_SUPPLY, "Sale end");
      _;
  }

  function mintCrxxm(address _to, uint _count) public payable saleIsOpen {
      if(msg.sender != owner()){
          require(!paused, "Pause");
      }
      require(totalSupply() + _count <= MAX_SUPPLY, "Max limit");
      require(totalSupply() < MAX_SUPPLY, "Sale end");
      require(_count <= 8, "Exceeds 8");
      require(msg.value >= price * _count, "Value below price");

      for(uint i = 0; i < _count; i++){
          _safeMint(_to, totalSupply());
      }
  }

  function getPrice(uint _count) public view returns (uint) {
      return price * _count;
  }

  function setPrice(uint _price) external onlyOwner {
      price = _price;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }
  function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
  }

  function walletOfOwner(address _owner) external view returns(uint[] memory) {
      uint tokenCount = balanceOf(_owner);

      uint[] memory tokensId = new uint[](tokenCount);
      for(uint i = 0; i < tokenCount; i++){
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }

      return tokensId;
  }

  function pause(bool val) public onlyOwner {
      paused = val;
  }

  modifier onlyTeam{
    require(
      msg.sender == t1 ||
      msg.sender == t2 ||
      msg.sender == t3 ||
      msg.sender == owner(),
      "Only team can do this"
    );
    _;
  }

  function withdrawAll() public onlyTeam {
      uint share = address(this).balance / 5;

      payable(t1).transfer(share);
      payable(t2).transfer(share);
      payable(t3).transfer(share);

      payable(designWallet).transfer(share);
      payable(marketingWallet).transfer(share/2);
      payable(charityWallet).transfer(share/2);
  }
}
