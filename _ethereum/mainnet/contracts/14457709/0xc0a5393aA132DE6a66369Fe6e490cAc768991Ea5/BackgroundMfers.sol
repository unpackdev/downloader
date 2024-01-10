//SPDX-License-Identifier: UNLICENSED

/*
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒███▓░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒▒▒▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒▒▒▒▒▓▒░░▒▒░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░▒░░░▒░░░░░░░░░░▒▒▒▒░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓██▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒░░▒░░░░░░░░░░▒▒▒▒░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░▒█▓▓▓▓▒░░▒▒▒▒▒░░░░░░░░░░░░░░░░░░░▒▒░▒▒░░▒▒░░░░░░░▒▒░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓░░▒▒▒░░░░░░░░░▒▒▒▒▒▒▒░░░░▒▒▒░░▒░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░▒▒▒▒░▒▒▒▒▒░▒▒░░░▒▒▒░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▓▒░░░▒░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░▒▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░
*/

pragma solidity >=0.7.0 <0.9.0;
interface nftInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./console.sol";

contract BackgroundMfers is ERC721, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private supply;

  uint256 public publicCost = .0169 ether;
  uint256 public mferCost = .0069 ether;
  uint public presalemaxMintAmountPlusOne = 3;
  mapping(address => uint256) public whitelistBalances;

  uint256 public maxMintAmountPlusOne = 21;

  bytes32 public merkleRoot;

  uint256 public maxSupplyPlusOne = 10_001;
  uint256 public devMintAmount = 25;

// dadmfers v1 0x14C93de3b7665373a398e3b75613666213c8fD1b
// Background Mfers V3 0x298614db08ed42CC05BE520C313f35ABaE6a05fE
  nftInterface dadmfersV1Contract = nftInterface(0x14C93de3b7665373a398e3b75613666213c8fD1b);

// dadmfers v2 0x68CCdcf9d5CB0e61d72c0b31b654d6408A93C65a
// Background Mfers V2 0x04C4fdC5216206B3627D69dB045FdabF26e25c9f
  nftInterface dadmfersV2Contract = nftInterface(0x68CCdcf9d5CB0e61d72c0b31b654d6408A93C65a);

// mfers 0x79FCDEF22feeD20eDDacbB2587640e45491b757f
// Background Mfers 0x972492ED350895501Bc2Aafc265216Be3354D2Ad
  nftInterface mfersContract = nftInterface(0x79FCDEF22feeD20eDDacbB2587640e45491b757f);

  mapping(uint256 => bool) public usedV1Ids;
  mapping(uint256 => bool) public usedV2Ids;
  mapping(uint256 => bool) public usedMferIds;


  string private _baseURIextended;

  bool public saleIsActive = false;

    // TODO: update
  address payable public immutable creatorAddress = payable(0x4873F1768E1833FA6Fb720b183715c7F57ECF953);

  constructor() ERC721("Background Mfers", "BGRNDMFER") {
    _baseURIextended = "ipfs://QmYraZ6dy9jDd3tnxtCwrnVwiCmVfhRVpa5tekTNsU2obR/";
    _mintLoop(0xc59Af5b5730Fd0D7541Af26D5e7F9Dd13a514947, devMintAmount);
    saleIsActive = false;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "Invalid mint amount!");
    require(supply.current() + _mintAmount < maxSupplyPlusOne, "Max supply exceeded!");
    require (saleIsActive, "Public sale inactive");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function foreignNftsForWallet(address account, uint256 input)
    external 
    view 
    returns (uint256[] memory)
  {
    uint256 foreignSupply = 0;
    if (input == 0) {
      foreignSupply = dadmfersV1Contract.totalSupply();
    } else if (input == 1) {
      foreignSupply = dadmfersV2Contract.totalSupply();
    } else if (input == 2) {
      foreignSupply = mfersContract.totalSupply();
    }

    uint256[] memory tokenIdsOwned = new uint256[](foreignSupply);
    uint256 index = 0;
    for (uint256 tokenid = 1; tokenid < foreignSupply; tokenid++) {
      bool owned = false;
      if (input == 0) {
        try dadmfersV1Contract.ownerOf(tokenid) returns (address retAddr) {
            owned = (retAddr == account) && !usedV1Ids[tokenid];
        } catch Error(string memory) {
          owned = false;
        }
      } else if (input == 1) {
        try dadmfersV2Contract.ownerOf(tokenid) returns (address retAddr) {
            owned = (retAddr == account) && !usedV2Ids[tokenid];
        } catch Error(string memory) {
          owned = false;
        }
      } else if (input == 2) {
        try mfersContract.ownerOf(tokenid) returns (address retAddr) {
            owned = (retAddr == account) && !usedMferIds[tokenid];
        } catch Error(string memory) {
          owned = false;
        }
      }

      if (owned) {
        tokenIdsOwned[index] = tokenid;
        index++;
      }
    }

    uint256[] memory trimmedResult = new uint256[](index);
    for (uint j = 0; j < trimmedResult.length; j++) {
        trimmedResult[j] = tokenIdsOwned[j];
    }

    return trimmedResult;
  }

  function mintWithDadmfersV1(uint256 [] memory nftIds) public mintCompliance(nftIds.length) {
    for (uint256 i = 0; i < nftIds.length; i++) {
      require(dadmfersV1Contract.ownerOf(nftIds[i]) == msg.sender, "You must own all the dadmfer V1s!");
      require(usedV1Ids[nftIds[i]] == false, "One of the dadmfer IDs has already been used!");
      supply.increment();
      _safeMint(msg.sender, supply.current());
      usedV1Ids[nftIds[i]] = true;
    }
  }

  function mintWithDadmfersV2(uint256 [] memory nftIds) public mintCompliance(nftIds.length) {
    for (uint256 i = 0; i < nftIds.length; i++) {
      require(dadmfersV2Contract.ownerOf(nftIds[i]) == msg.sender, "You must own all the dadmfer V2s!");
      require(usedV2Ids[nftIds[i]] == false, "One of the dadmfer IDs has already been used!");
      supply.increment();
      _safeMint(msg.sender, supply.current());
      usedV2Ids[nftIds[i]] = true;
    }
  }

  function mintWithMfers(uint256 [] memory nftIds) public payable mintCompliance(nftIds.length) {
    require(msg.value >= mferCost * nftIds.length, "Not enough eth sent!");
    
    for (uint256 i = 0; i < nftIds.length; i++) {
      require(mfersContract.ownerOf(nftIds[i]) == msg.sender, "You must own all the mfers!");
      require(usedMferIds[nftIds[i]] == false, "One of the mfer IDs has already been used!");
      supply.increment();
      _safeMint(msg.sender, supply.current());
      usedMferIds[nftIds[i]] = true;
    }
  }

  function mintPublic(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(msg.value >= publicCost * _mintAmount, "Not enough eth sent!");
    require(_mintAmount < maxMintAmountPlusOne, "trying to mint too many!");
    _mintLoop(msg.sender, _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata merkleProof) public mintCompliance(_mintAmount) {
    require(_mintAmount < presalemaxMintAmountPlusOne, "trying to mint too many!");
    require(whitelistBalances[msg.sender] + _mintAmount < presalemaxMintAmountPlusOne, "Attempting to mint too many for pre-sale");
    
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "You're not whitelisted for presale!");
    _mintLoop(msg.sender, _mintAmount);
    whitelistBalances[msg.sender] += _mintAmount;
  }

  function setSale(bool newState) public onlyOwner {
    saleIsActive = newState;
  }

  function setPublicCost(uint256 _newCost) public onlyOwner {
    publicCost = _newCost;
  }

  function setMferCost(uint256 _newCost) public onlyOwner {
    mferCost = _newCost;
  }

  function lowerSupply(uint256 newSupply) public onlyOwner {
      if (newSupply < maxSupplyPlusOne) {
          maxSupplyPlusOne = newSupply;
      }
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function setBaseURI(string memory baseURI_) external onlyOwner() {
    _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;  
    Address.sendValue(creatorAddress, balance);
  }

}
