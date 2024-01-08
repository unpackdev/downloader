//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

contract Cityverse is ERC721Enumerable, ReentrancyGuard, Ownable {
  uint256 public immutable maxSupply;
  uint256 public immutable reserveCount;
  uint256 public immutable MAX_CLAIMS = 2;

  string public baseURI;
  uint256 public nextTokenId;
  uint256 public tokensReserved;
  bool public claimStatus;
  mapping(address => uint256) public claimed;

  event BaseURIChanged(string newBaseURI);
  event Claim(address minter);
  event ReserveToken(address minter, address recipient, uint256 count);
  event ClaimStatusChanged(bool status);

  constructor(
    uint256 _maxSupply,
    uint256 _reserveCount,
    string memory _initBaseURI
  ) ERC721("Cityverse", "CITY") {
    require(
      _reserveCount <= _maxSupply,
      "Cityverse: reserve count out of range"
    );
    maxSupply = _maxSupply;
    reserveCount = _reserveCount;
    baseURI = _initBaseURI;
  }

  function setBaseURI(string calldata newbaseURI) external onlyOwner {
    baseURI = newbaseURI;
    emit BaseURIChanged(newbaseURI);
  }

  function setClaimStatus(bool status) external onlyOwner {
    claimStatus = status;
    emit ClaimStatusChanged(status);
  }

  function reserveTokens(address recipient, uint256 count) external onlyOwner {
    require(recipient != address(0), "Cityverse: zero address");

    uint256 _nextTokenId = nextTokenId;

    require(count > 0, "Cityverse: invalid count");
    require(
      _nextTokenId + count <= maxSupply,
      "Cityverse: max supply exceeded"
    );

    require(
      tokensReserved + count <= reserveCount,
      "Cityverse: max reserve count exceeded"
    );
    tokensReserved += count;

    for (uint256 ind = 0; ind < count; ind++) {
      _safeMint(recipient, _nextTokenId + ind);
    }

    nextTokenId += count;

    emit ReserveToken(_msgSender(), recipient, count);
  }

  function mint() external nonReentrant {
    require(claimStatus, "Cityverse: claim has not started yet");
    require(
      claimed[_msgSender()] < MAX_CLAIMS,
      "Cityverse: already claimed enough tokens"
    );

    uint256 _nextTokenId = nextTokenId;
    claimed[_msgSender()] += 1;
    require(
      _nextTokenId + 1 + reserveCount - tokensReserved <= maxSupply,
      "Cityverse: max supply exceeded"
    );

    _safeMint(_msgSender(), _nextTokenId);
    nextTokenId += 1;

    emit Claim(_msgSender());
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
}
