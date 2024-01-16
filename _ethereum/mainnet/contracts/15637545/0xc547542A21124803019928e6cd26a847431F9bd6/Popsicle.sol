// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//Standard NFT
import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./Counters.sol";
import "./Ownable.sol";

//Royalty
import "./ERC2981.sol";

contract Popsicle is ERC721, ERC721Holder, Ownable, ERC2981 {
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 public constant MAXSUPPLY = 2000;
  uint256 public constant RESERVED = 200;
  uint256 public constant MAXMINTAMOUNT = 1; 

  Counters.Counter private supply;
  address public cmContract;
  uint256 private firstIndex = 1;
  uint256 private lastIndex = MAXSUPPLY;
  
  address private t1 = 0x2283BF4705A9D4E850a4C8dEF2aAe9Ac98F4c495;
  string private _contractURI = "https://cubemelt.mypinata.cloud/ipfs/QmXYBxRBgrof2Ac3KpW8PigikJSoaRLasciLtuzKTY3MD4";

  string public baseURI = "https://cubemelt.mypinata.cloud/ipfs/QmNfuJyHu7J5RSKq4peyfqRRfpnDWTP9LdUpTiRw5AC7uu/";
  bool public paused = false;

  constructor() ERC721("Popsicle", "P") {
    //Contract interprets 10,000 as 100%.
    setDefaultRoyalty(t1, 750); //7.5%
   }

//*** INTERNAL FUNCTION ***//
  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, firstIndex);
      firstIndex++;
    }
  }

  function _reverseMintLoop(address _receiver, uint256 _mintAmount) internal {
    for(uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, lastIndex);
      lastIndex--;
    }
  }

//*** PUBLIC FUNCTION ***//
  function mint(address _to, uint256 _mintAmount) external {
    require(!paused);
    require(msg.sender == cmContract, "CP: CM Contracts");
    require(_mintAmount > 0 && _mintAmount <= MAXMINTAMOUNT, "Out of mint amount limit.");
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    _mintLoop(_to, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAXSUPPLY) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : "";
  }

  // Returns the URI for the contract-level metadata of the contract.
  function contractURI() public view returns (string memory) {
      return _contractURI;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function getAvailability() external returns (bool) {
    if(supply.current() < MAXSUPPLY)
      return true;

    return false;
  }

//*** ONLY OWNER FUNCTION **** //
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setCMContract(address _contract) public onlyOwner {
      cmContract = _contract;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function ownerMint(uint256 _mintAmount) public onlyOwner {
    require(!paused);
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    _mintLoop(t1, _mintAmount);
  }

  function mintUnsettledSupply() public onlyOwner {
    require(!paused);

    uint256 _mintAmount = MAXSUPPLY - supply.current();
    require(_mintAmount > 0, "Invalid mint amount.");
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    _mintLoop(t1, _mintAmount);
  }

  function mintUnsettledReserved() public onlyOwner {
    require(!paused);

    uint256 _mintAmount = lastIndex - (MAXSUPPLY - RESERVED);
    require(_mintAmount > 0, "Invalid mint amount.");
    require(supply.current() + _mintAmount <= MAXSUPPLY, "Out of supply.");

    _reverseMintLoop(t1, _mintAmount);
  }

  function airDropService(address[] calldata _airDropAddresses) public onlyOwner {
    require(!paused);
    require(supply.current() + _airDropAddresses.length <= MAXSUPPLY, "Out of supply.");

    //Reverse mint loop
    for (uint256 i = 0; i < _airDropAddresses.length; i++) {
      supply.increment();
      _safeMint(_airDropAddresses[i], lastIndex);
      lastIndex--;
    }
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(t1).call{value: address(this).balance}("");
    require(os);
  }

  // Sets contract URI for the contract-level metadata of the contract.
  function setContractURI(string calldata _URI) public onlyOwner {
      _contractURI = _URI;
  }

  function setDefaultRoyalty(address _receiver, uint96 _royaltyPercent) public onlyOwner {
      _setDefaultRoyalty(_receiver, _royaltyPercent);
  }

//REQUIRED OVERRIDE FOR ERC721 & ERC2981
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}