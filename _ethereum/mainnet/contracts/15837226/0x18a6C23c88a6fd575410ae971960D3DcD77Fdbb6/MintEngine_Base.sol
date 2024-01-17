//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MintEngineContract.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract MintEngineV1 is ERC721Enumerable, Ownable, MintEngineContract  {
  using Strings for uint256;
  using SafeMath for uint256;
  using ECDSA for bytes32;

  //NFT params
  string public baseURI;
  string public defaultURI;
  string public mycontractURI;
  bool public finalizeBaseUri = false;
  
  uint256 public presalePrice;
  uint256 public presaleSupply;

  uint256 public salePrice;
  uint256 public totalSaleSupply;  

  bool public isSalePaused = false;
  bool public isRevealed = false;
  bool public mintPassActive = false;
  bool public preSaleActive = false;
  bool public mintActive = false;

  //royalty
  address public royaltyAddr;
  uint256 public royaltyBasis;

  address private vaultAddress;

  constructor(
  string memory _name, 
  string memory _symbol, 
  string memory _bURI, 
  string memory _dURI, 
  string memory _cURI,
  uint256 _psp,
  uint256 _pss,
  uint256 _sp,
  uint256 _tss,
  address _ra,
  uint256 _rb
  ) ERC721(_name, _symbol) { 
    setBaseURI(_bURI);
    defaultURI = _dURI;
    mycontractURI = _cURI;
    presalePrice = _psp;
    presaleSupply = _pss;
    salePrice = _sp;
    totalSaleSupply = _tss;
    royaltyAddr = _ra;
    royaltyBasis = _rb;
    vaultAddress = msg.sender;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mintPassMint(bytes memory signature, uint8 _mintAmount) external payable {
    uint256 supply = totalSupply();

    require(!isSalePaused, "Sale Paused");
    require(mintPassActive, "MintPass Inactive");
    require(super.verifySigner(msg.sender, "mintPassMint", signature), "INVALID MINTPASS SIGNATURE!");
    require(supply + _mintAmount <= totalSaleSupply, "TOTAL SUPPLY REACHED!"); 
    
    _mint(_mintAmount, supply);
  }

  function preSaleMint(bytes memory signature, uint8 _mintAmount) external payable {
    uint256 supply = totalSupply();

    require(!isSalePaused, "Sale Paused");
    require(preSaleActive, "Pre-Sale Inactive");
    require(super.verifySigner(msg.sender, "preSaleMint", signature), "INVALID PRESALE SIGNATURE!");
    require(supply + _mintAmount <= presaleSupply, "PRESALE SUPPLY REACHED");     
    require(msg.value >= presalePrice * _mintAmount, "INVALID PAYMENT");

    _mint(_mintAmount, supply);
  }

  function mint(uint8 _mintAmount) external payable  {
    uint256 supply = totalSupply();

    require(!isSalePaused, "Sale Paused");
    require(mintActive, "Mint Inactive");
    require(supply + _mintAmount <= totalSaleSupply, "TOTAL SUPPLY REACHED!");
    require(msg.value >= salePrice * _mintAmount, "INVALID PAYMENT");

    _mint(_mintAmount, supply);
  }

  function _mint(uint8 _mintAmount, uint256 supply) internal {
       
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }

  }

  function walletOfOwner(address _owner)
    external
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

  function tokenURI(uint256 id)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(id),
      "ERC721Metadata: URI query for nonexistent token"
    );

    uint256 supply = totalSupply();
    string memory currentBaseURI = _baseURI();

    if (isRevealed && supply >= id) {
      return string(abi.encodePacked(currentBaseURI, id.toString()));
    }

    return defaultURI;
  }

  function contractURI() external view returns (string memory) {
    return string(abi.encodePacked(mycontractURI));
  }

  //ERC-2981
  function royaltyInfo(uint256, uint256 _salePrice) external view 
  returns (address receiver, uint256 royaltyAmount){
    return (royaltyAddr, _salePrice.mul(royaltyBasis).div(10000));
  }
  
  //OWNER FUNCTIONS

  function toggleMintPass(bool _state) external onlyOwner {
    mintPassActive = _state;
  }

  function togglePreSale(bool _state) external onlyOwner {
    preSaleActive = _state;
  }

  function toggleMint(bool _state) external onlyOwner {
    mintActive = _state;
  }

  function toggleReveal(bool _state) external onlyOwner {
    isRevealed = _state;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    require(!finalizeBaseUri);
    baseURI = _newBaseURI;
  }

  function finalizeBaseURI() external onlyOwner {
    finalizeBaseUri = true;
  }

  function setContractURI(string memory _contractURI) external onlyOwner {
    mycontractURI = _contractURI; //Contract Metadata format based on:  https://docs.opensea.io/docs/contract-level-metadata    
  }

  function setRoyalty(address _royaltyAddr, uint256 _royaltyBasis) external onlyOwner {
    royaltyAddr = _royaltyAddr;
    royaltyBasis = _royaltyBasis;
  }

  function setVaultAddress(address _va) external onlyOwner {
    vaultAddress = _va;
  }

  function pause(bool _state) external onlyOwner {
    isSalePaused = _state;
  } 

  function reserveMint(uint256 _mintAmount, address _to) external onlyOwner {
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= totalSaleSupply, "TOTAL SUPPLY REACHED!");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function withdraw() external onlyOwner {
    _withdraw();
  }

  function mintEngineWithdraw() external onlyMintEngine {
    _withdraw();
  }

  function _withdraw() private {
    require(address(this).balance > 0);
    uint256 originalBalance = (address(this).balance);

    // MintEngine Fee
    payable(super.getMintEngineVault()).transfer(originalBalance.mul(super.getMintEngineFee()).div(10000));
    
    // Dynamic payees
    MintEnginePayee[] memory payees = Payees;
    for (uint i = 0; i < payees.length; i++){
      MintEnginePayee memory p = payees[i];      
      payable(p.payeeAddress).transfer(originalBalance.mul(p.basisFee).div(10000));
    }

    // Owner
    payable(vaultAddress).transfer(address(this).balance);
  }
      
  function addPayee(
        address _address,
        uint256 _fee
  ) external onlyOwner {
      Payees.push(MintEnginePayee(_address, _fee));
  }

  function editPayee(
        uint256 _index,        
        address _address,
        uint256 _fee
  ) external onlyOwner {
      MintEnginePayee storage p = Payees[_index];
      p.payeeAddress = _address;
      p.basisFee = _fee;
  }

  function healthCheck() external pure returns (bool) {
    return true;
  }

  function setPresalePrice(uint256 psp) external onlyOwner {
    presalePrice = psp;
  } 

  function setSalePrice(uint256 sp) external onlyOwner {
    salePrice = sp;
  }

  function getContractBalance() external view returns (uint256) {
    return address(this).balance;
  }
}