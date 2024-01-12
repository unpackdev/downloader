// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC721A.sol";

import "./IBurnable.sol";

contract UdansNecklace is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard, IBurnable {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  string public singleTokenURI = "";

  address public burnContractAddress = address(0);
  address public wothfContractAddress = address(0);

  bool public claimIsActive = true;
  mapping(uint256 => bool) public claimed;

  address[] payees = [
    0x3a7C5DA808096a79bB0b33c0655C32c02ed3dee0
  ];

  uint256[] payeeShares = [
    100
  ];

  constructor(address _wothfContractAddress, string memory _singleTokenURI)
    ERC721A("Udans Necklace", "UDANSNECKLACE")
    PaymentSplitter(payees, payeeShares)
  {
    wothfContractAddress = _wothfContractAddress;
    singleTokenURI = _singleTokenURI;
  }

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenIdsIdx;
    address currOwnershipAddr;
    uint256 tokenIdsLength = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenIdsLength);
    TokenOwnership memory ownership;

    for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; i++) {
      ownership = _ownerships[i];
      if (ownership.burned) {
        continue;
      }
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == _owner) {
        tokenIds[tokenIdsIdx++] = i;
      }
    }
    return tokenIds;
  }

  function claim(uint256[] calldata _tokenIds) external payable nonReentrant {
    require(claimIsActive, "claim is disabled");
    require(wothfContractAddress != address(0), "missing contract address");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      require(!claimed[_tokenIds[i]], "already claimed");
      require(IERC721(wothfContractAddress).ownerOf(_tokenIds[i]) == msg.sender, "not owner of token");

      claimed[_tokenIds[i]] = true;
    }

    _safeMint(msg.sender, _tokenIds.length);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "invalid token");
    return singleTokenURI;
  }

  function setSingleTokenURI(string memory _singleTokenURI) external onlyOwner {
    singleTokenURI = _singleTokenURI;
  }

  function setClaimIsActive(bool _claimIsActive) external onlyOwner {
    claimIsActive = _claimIsActive;
  }

  function setWOTHFContractAddress(address _wothfContractAddress) external onlyOwner {
    wothfContractAddress = _wothfContractAddress;
  }

  function setBurnContractAddress(address _burnContractAddress) external onlyOwner {
    burnContractAddress = _burnContractAddress;
  }

  function burn(uint256[] calldata _tokenIds) external {
    require(msg.sender == burnContractAddress, "illegal operation");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _burn(_tokenIds[i]);
    }
  }
}