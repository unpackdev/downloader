//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract Station is ERC721Enumerable, ERC721URIStorage {
  uint256 public constant SALE_LIMIT = 9000;
  uint256 public constant TEAM_LIMIT = 1000;
  uint256 public constant PRICE = 0.08 ether;
  bytes16 internal constant ALPHABET = '0123456789abcdef';

  address public operator;
  uint256 public sold;
  uint256 public teamMinted;
  bool public saleIsActive = true;
  address payable public stationLabs;
  address public signer;

  mapping(address => uint256) public bought;

  constructor(
    string memory _name,
    string memory _symbol,
    address payable _stationLabs,
    address _signer
  ) ERC721(_name, _symbol) {
    operator = msg.sender;
    stationLabs = _stationLabs;
    signer = _signer;
  }

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
  }

  function buy(uint256 _count, uint256 _maxCount, uint8 _v, bytes32 _r, bytes32 _s) public payable {
    require(_count > 0, "Spaceship count cannot be Zero!");
    require(_count <= SALE_LIMIT - sold, "Sale out of stock!");
    require(saleIsActive, "Sale is not active!");
    require(bought[msg.sender] + _count <= _maxCount);
    bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _maxCount));
    require(verifyHash(_hash, _v, _r, _s) == signer);
    uint256 amountDue = _count * PRICE;
    require(msg.value == amountDue, "Sent ether is not equal to the required amount for purchase completion");
    for(uint i=0; i<_count; i++) {
      string memory _tokenURI = string(abi.encodePacked("https://station0x.com/api/", addressToString(address(this)), "/", toString(totalSupply()), ".json"));
      mint(msg.sender, totalSupply(), _tokenURI, "");
    }
    sold += _count;
    bought[msg.sender] += _count;
    (bool success,) = stationLabs.call{value:msg.value}('');
    require(success, 'Failed to forward funds');
  }

  function getStuckFunds() public onlyOperator {
    payable(msg.sender).transfer(address(this).balance);
  }

  function mintTo(address _to, uint256 _count) public onlyOperator {
    require(_count <= TEAM_LIMIT - teamMinted);
    require(_count > 0);

    for(uint i=0; i<_count; i++) {
      string memory _tokenURI = string(abi.encodePacked("https://station0x.com/api/", addressToString(address(this)), "/", toString(totalSupply()), ".json"));
      mint(_to, totalSupply(), _tokenURI, "");
    }
    teamMinted += _count;
  }

  function setSaleStatus(bool _status) public onlyOperator {
    saleIsActive = _status;
  }

  function mint(address to, uint256 tokenId, string memory _tokenURI, bytes memory _data) internal {
    _safeMint(to, tokenId, _data);
    _setTokenURI(tokenId, _tokenURI);
  }

  function changeOperator(address _newOperator) public onlyOperator {
    operator = _newOperator;
    emit ChangeOperator(_newOperator);
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOperator {
    _setTokenURI(tokenId, _tokenURI);
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return ERC721URIStorage.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
    return ERC721Enumerable.supportsInterface(interfaceId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    ERC721URIStorage._burn(tokenId);
  }

  function addressToString(address _addr) internal pure returns (string memory) {
    uint value = uint256(uint160(_addr));
    uint length = 20;
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = '0';
    buffer[1] = 'x';
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = ALPHABET[value & 0xf];
      value >>= 4;
    }
    require(value == 0, 'Strings: hex length insufficient');
    return string(buffer);
  }
    
  function toString(uint256 value) internal pure returns (string memory) {
  // Inspired by OraclizeAPI's implementation - MIT licence
  // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function verifyHash(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address _signer) {
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    return ecrecover(messageDigest, _v, _r, _s);
  }

  function changeStationLabs(address payable _newStationLabs) public {
    require(msg.sender == address(stationLabs));
    stationLabs = _newStationLabs;
  }

  event ChangeOperator(address _newOperator);
}