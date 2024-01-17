//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155Burnable.sol";
import "./Dogc.sol";

contract DogeSerum is ERC1155, Ownable, ReentrancyGuard, ERC1155Burnable {
  using Strings for uint256;

  Dogc public immutable dogc;
  string public baseURI;

  mapping(uint8 => bool) public mintState;
  bool public m1PublicMintState = false;
  bool public m2PublicMintState = false;

  uint256[3] public totalSupply;

  // doge serum types
  uint8 public constant M1_SERUM = 0;
  uint8 public constant M2_SERUM = 1;
  uint8 public constant MEGA_SERUM = 2;

  mapping(uint256 => bool) public isMinted; // dogc tokenId => isMinted
  mapping(uint256 => bool) public isM2Minted; // dogc tokenId => isMinted
  uint256 public price = 0; // free mint by default

  event SetBaseURI(string indexed _baseURI);

  constructor(string memory _baseURI, address _dogc) ERC1155(_baseURI) {
    baseURI = _baseURI;
    dogc = Dogc(_dogc);
    mintState[M1_SERUM] = false;
    mintState[M2_SERUM] = false;
    mintState[MEGA_SERUM] = false;
  }

  function contractURI() public pure returns (string memory) {
    return "https://ipfs.filebase.io/ipfs/QmWLj32V8gv6h1SoRDfCdhc7GEWhBwN9EmzXfspV57NzFp";
  }

  function uri(uint256 _typeId) public view override returns (string memory) {
    require(
      _typeId == M1_SERUM || _typeId == M2_SERUM || _typeId == MEGA_SERUM,
      "URI requested for invalid serum type"
    );
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _typeId.toString()))
        : baseURI;
  }

  function mintM1Batch() external payable nonReentrant {
    require(mintState[M1_SERUM], "Exclusive mint haven't start");

    uint256[] memory ids = dogc.tokensOfOwner(msg.sender);

    require(ids.length > 0, "Caller don't own any dogc");

    // check tokens haven't mint serum
    uint256[] memory validIds = new uint256[](ids.length);
    uint256 validIdsLength = 0;
    for (uint256 i = 0; i < ids.length; i++) {
      if (!isMinted[ids[i]]) {
        validIds[validIdsLength] = ids[i];
        validIdsLength++;
      }
    }

    require(msg.value >= price * validIdsLength, "Insufficient payment");

    // mint m1 serum to msg.sender
    _mint(msg.sender, M1_SERUM, validIdsLength, "");
    totalSupply[M1_SERUM] = totalSupply[M1_SERUM] + validIdsLength;

    for (uint256 i = 0; i < validIdsLength; i++) {
      isMinted[validIds[i]] = true;
    }
  }

  function mintM2Batch() external payable nonReentrant {
    require(mintState[M2_SERUM], "Public mint haven't start");
    uint256[] memory ids = dogc.tokensOfOwner(msg.sender);

    require(ids.length > 0, "Caller don't own any dogc");

    // check tokens haven't mint serum
    uint256[] memory validIds = new uint256[](ids.length);
    uint256 validIdsLength = 0;
    for (uint256 i = 0; i < ids.length; i++) {
      if (!isM2Minted[ids[i]]) {
        validIds[validIdsLength] = ids[i];
        validIdsLength++;
      }
    }

    require(msg.value >= price * validIdsLength, "Insufficient payment");

    // mint m2 serum to msg.sender
    _mint(msg.sender, M2_SERUM, validIdsLength, "");
    totalSupply[M2_SERUM] = totalSupply[M2_SERUM] + validIdsLength;

    for (uint256 i = 0; i < validIdsLength; i++) {
      isM2Minted[validIds[i]] = true;
    }
  }

  function flipM1PublicState() external onlyOwner {
    m1PublicMintState = !m1PublicMintState;
  }

  function flipM2PublicState() external onlyOwner {
    m2PublicMintState = !m2PublicMintState;
  }


  function m1PublicMint(uint256 _amount) external payable nonReentrant {
    require(m1PublicMintState, "Public mint haven't started");
    require(
      totalSupply[M1_SERUM] + _amount < dogc.totalSupply(),
      "Insufficient remains"
    );
    require(msg.value >= price * _amount, "Insufficient payment");

    _mint(msg.sender, M1_SERUM, _amount, "");
    totalSupply[M1_SERUM] = totalSupply[M1_SERUM] + _amount;
  }

  function m2PublicMint(uint256 _amount) external payable nonReentrant {
    require(m2PublicMintState, "Public mint haven't started");
    require(
      totalSupply[M2_SERUM] + _amount < dogc.totalSupply(),
      "Insufficient remains"
    );
    require(msg.value >= price * _amount, "Insufficient payment");

    _mint(msg.sender, M2_SERUM, _amount, "");
    totalSupply[M2_SERUM] = totalSupply[M2_SERUM] + _amount;
  }

  function airdrop(
    address _to,
    uint8 _type,
    uint256 _amount
  ) external onlyOwner {
    require(
      totalSupply[_type] + _amount < dogc.totalSupply(),
      "Insufficient tokens left"
    );
    _mint(_to, _type, _amount, "");
    totalSupply[_type] = totalSupply[_type] + _amount;
  }

  function airdropMany(address[] memory _to, uint8 _type) external onlyOwner {
    require(
      totalSupply[_type] + _to.length < dogc.totalSupply(),
      "Insufficient tokens left"
    );
    for (uint256 i = 0; i < _to.length; i++) {
      _mint(_to[i], _type, 1, "");
    }

    totalSupply[_type] = totalSupply[_type] + _to.length;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function flipMintState(uint8 _serumType) external onlyOwner {
    mintState[_serumType] = !mintState[_serumType];
  }

  function updateBaseUri(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
    emit SetBaseURI(baseURI);
  }

  // rescue
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawToken(address _tokenContract) external onlyOwner {
    IERC20 tokenContract = IERC20(_tokenContract);

    // transfer the token from address of this contract
    // to address of the user (executing the withdrawToken() function)
    bool success = tokenContract.transfer(
      msg.sender,
      tokenContract.balanceOf(address(this))
    );
    require(success, "Transfer failed.");
  }
}
