//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./IBendoPass.sol";
import "./BendoPassUsed.sol";

contract Murasai is ERC721Enumerable, IERC2981, Ownable {

  address public beneficiary;
  address public royalties;

  IBendoPass bendoPass;
  BendoPassUsed bendoPassUsed;

  uint256 constant MAX_SUPPLY = 5802;
  uint256 private _currentId;

  string public baseURI;
  string private _contractURI;

  bool public isActive = false;
  bool public isFreeMintActive = false;
  bool public isBendoPassActive = false;
  uint8 public MAX_MINT = 5;
  uint public idBendo = 1;
  uint public bendoPassLeft = 500;

  uint256 public mintPrice = 0.08 ether;

  mapping (address => uint8) whitelist;
  mapping (address => uint8) freemint;

  constructor(address _beneficiary, address _bendoPassAddress, address _bendoPassUsedAddress, string memory _initialBaseURI
  ) ERC721("Murasai", "MURASAI") {
    beneficiary = _beneficiary;
    royalties = _beneficiary;
    baseURI = _initialBaseURI;
    bendoPass = IBendoPass(_bendoPassAddress);
    bendoPassUsed = BendoPassUsed(_bendoPassUsedAddress);
  }

  //#region modifier

  modifier isNotNull(uint amount) {
    require(amount > 0);
    _;
  }

  //#endregion

  //#region setter

  //#region bendopass
  function setBendoPass(address bendoPassAddr) public onlyOwner {
    bendoPass = IBendoPass(bendoPassAddr);
  }
  
  function setIdBendo(uint newId) public onlyOwner {
    idBendo = newId;
  }

  function setBendoPassLeft(uint _bendoPassLeft) public onlyOwner {
    bendoPassLeft = _bendoPassLeft;
  }

  //#endregion

  //#region bendopassUsed

  function setBendoPassUsed(address bendopassUsedAddr) public onlyOwner {
    bendoPassUsed = BendoPassUsed(bendopassUsedAddr);
  }

  //#endregion

  //#region beneficiaries
  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setRoyalties(address _royalties) public onlyOwner {
    royalties = _royalties;
  }
  //#endregion

  //#region Activation
  function setActive(bool _isActive) public onlyOwner {
    isActive = _isActive;
  }

  function setBendoPassActive(bool _isBendoPassActive) public onlyOwner {
    isBendoPassActive = _isBendoPassActive;
  }
  
  function setFreeMintActive(bool _isFreeMintActive) public onlyOwner {
    isFreeMintActive = _isFreeMintActive;
  }
  //#endregion

  //#region Freemint
  function addFreemint(address addr, uint8 nb) public onlyOwner {
      freemint[addr] = nb;
  }

  function addMultipleFreemint(address[] memory addrs, uint8[] memory nb) public onlyOwner {
      uint gasCost = 0;
      uint gas = gasleft();
      bool firstTime = true;
      for(uint16 i = 0; i < addrs.length && gasCost > gasleft();i++){
          addFreemint(addrs[i], nb[i]);
          if(firstTime){
            firstTime=false;
            gasCost = gas - gasleft();
          }
      }
  }
  //#endregion
  
  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }
  //#endregion

  //#region mint
  function mintFree(uint8 amount) public isNotNull(amount) {
    require(freemint[_msgSender()] >= amount, "you can't mint this number");
    _internalMint(_msgSender(), amount, isFreeMintActive);
    require(_currentId + amount <= MAX_SUPPLY - bendoPassLeft, "Will exceed maximum supply");
    freemint[_msgSender()] -= amount;
  }

  function mint(uint8 amount) public payable isNotNull(amount){
    require(balanceOf(_msgSender()) + amount <= MAX_MINT , "you can't mint this number");
    require(msg.value >= mintPrice * amount, "Incorrect payable amount");
    require(_currentId + amount <= MAX_SUPPLY - bendoPassLeft, "Will exceed maximum supply");
    _internalMint(_msgSender(), amount, isActive);
  }

  function bendoPassMint(uint amount) public isNotNull(amount){
    require(amount <= bendoPass.balanceOf(_msgSender(), idBendo), "you can't mint this number");
    require(_currentId + amount <= MAX_SUPPLY, "Will exceed maximum supply");
    _internalMint(_msgSender(), amount, isBendoPassActive);
    bendoPass.burn(_msgSender(), idBendo, amount);
    bendoPassLeft--;
    bendoPassUsed.openTheBox(_msgSender(), amount);

  }

  function _internalMint(address to, uint256 amount, bool mintIsActive) private {
    require(mintIsActive, "mint is closed");
    for (uint256 newSupply = _currentId + amount; _currentId < newSupply;) {
      _safeMint(to, ++_currentId);
    }
  }
  //#endregion

  function setPrice(uint _price) public onlyOwner {
    mintPrice = _price;
  }

  function withdraw(uint amount) public onlyOwner {
    require(address(this).balance >= amount);
    payable(beneficiary).transfer(amount);
  }

  //#region getter
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function totalSupply() public view override returns (uint256) {
    return _currentId;
  }

  function getFreemintAmountOf(address addr) public view returns(uint) {
    return freemint[addr];
  }
  //#endregion

  // IERC2981
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
    _tokenId; // silence solc warning
    royaltyAmount = (_salePrice / 100) * 5;
    return (royalties, royaltyAmount);
  }
}