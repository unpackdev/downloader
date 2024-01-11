//    _____       _     _ _       _____      _     _                       
//   / ____|     | |   | (_)     |  __ \    (_)   | |                      
//  | |  __  ___ | |__ | |_ _ __ | |__) | __ _  __| | ___  __  ___   _ ____
//  | | |_ |/ _ \| '_ \| | | '_ \|  ___/ '__| |/ _` |/ _ \ \ \/ / | | |_  /
//  | |__| | (_) | |_) | | | | | | |   | |  | | (_| |  __/_ >  <| |_| |/ / 
//   \_____|\___/|_.__/|_|_|_| |_|_|   |_|  |_|\__,_|\___(_)_/\_\\__, /___|
//                                                                __/ |    
//                                                               |___/ 

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract GoblinPride is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  bool public cunYuGetDem = false;
  bool public isRevealed = false;

  uint256 constant public muxZupply = 3334;
  uint256 constant public maxAmountPaid = 11;
  uint256 constant public freeMintAmount = 334;
  uint256 constant public luvLuv = 0.002 ether;

  mapping(address => uint256) public yuGotPridez;
  mapping(address => uint256) public freeGobPridez;

  constructor(
  ) ERC721A("goblinpride.xyz", "PRIDE") {
  }

  modifier cunYuGetMuh() {
    require(cunYuGetDem, "uughhaaah meh hidungg!");
    _;
  }

  modifier callerIsGobPride() {
    require(tx.origin == msg.sender, "yu are not a hooman!");
    _;
  }

  function meWuntPridez(uint256 quantity)
    external payable
    nonReentrant
    callerIsGobPride
    cunYuGetMuh
  {
    require(msg.value >= (luvLuv * quantity));
    require(totalSupply() + quantity < muxZupply, "yu cannut gettt soiso munnnny!");
    require(
      yuGotPridez[msg.sender] + quantity < maxAmountPaid,
      "yu cannut gettt soiso munnnny!"
    );
    yuGotPridez[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function freeMint(uint256 quantity) external nonReentrant callerIsGobPride cunYuGetMuh
  {
    require(quantity < 3, "yu cannut gettt soiso munnnny!");
    require(totalSupply() + quantity < freeMintAmount, "luvLuv!");
    require(freeGobPridez[msg.sender] < 2, "yu cannut gettt soiso munnnny!");
    freeGobPridez[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function mehEnable() public onlyOwner {
    cunYuGetDem = true;
  }

  function mehStop() public onlyOwner {
    cunYuGetDem = false;
  }

  function mehReveal() public onlyOwner {
    isRevealed = true;
  }

  function givvMehFunds() public payable onlyOwner {
	  (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		  require(success, "oh meee guiiitt???!!");
	}

  function amunntFree(address _address) public view returns (uint256){
    return freeGobPridez[_address];
  }

  function amunntNotFree(address _address) public view returns (uint256){
    return yuGotPridez[_address];
  }

  string private _itsPrideMonth;

  function _baseURI() internal view virtual override returns (string memory) {
    return _itsPrideMonth;
  }

  function setBaseURI(string calldata newRainbow) external onlyOwner {
    _itsPrideMonth = newRainbow;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "muhHiding!");

    string memory baseURI = _baseURI();
    string memory json = ".json";

    if(isRevealed){
      return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
        : '';
    }else{
      return baseURI;
    }
  }
}
