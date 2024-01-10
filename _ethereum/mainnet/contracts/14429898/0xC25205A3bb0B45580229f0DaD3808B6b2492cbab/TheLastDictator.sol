// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Context.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract TheLastDictator is  Context, Ownable, ERC721, Pausable {
  using Strings for uint256;

  address constant UkraineCryptoDonation = 0x165CD37b4C644C2921454429E7F9358d18A45e14;
  address proxyRegistryAddress;

  string private _baseMetadataURI;
  mapping (uint256 => uint256) private _donation;
  uint256 private _tokenId;

  constructor(address _proxyRegistryAddress) {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /// MARK: Minters
  function retrieve() public payable whenNotPaused {
    require(msg.value > 0.0001 ether, "Min. 0.0001 eth required");

    _safeMint(_msgSender(), _tokenId);
    _donation[_tokenId] = msg.value;

    _tokenId++;

    uint256 half = msg.value / 2;
    (bool success, ) = payable(UkraineCryptoDonation).call{value: half}("");
    require(success, "Could not forward funds");
  }

  /// MARK: Export
  function transfer(address payable to, uint256 amount) public onlyOwner whenNotPaused {
    require(to != address(0), "Can't burn");
    require(to != address(this), "Can't send to itself");

    (bool success, ) = to.call{value: amount}("");
    require(success, "Failed to send Ether");
  }

  /// MARK: ERC721 Overrides
  function isApprovedForAll(address owner, address operator) override public view returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");

    uint256 balance;

    for (uint256 i = 0; i < _tokenId; i++) {
      if (_owners[i] == owner) {
        balance++;
      }
    }

    return balance;
  }

  function burn(uint256 tokenId) public whenNotPaused {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
    _burn(tokenId);
    delete _donation[tokenId];
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {}

  /// MARK: ERC165
  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return
    interfaceId == type(IERC721).interfaceId ||
    interfaceId == type(IERC721Metadata).interfaceId ||
    interfaceId == type(IERC721Enumerable).interfaceId ||
    super.supportsInterface(interfaceId);
  }


  /// MARK: ERC721Metadata
  function name() public pure returns (string memory) {
    return "The Last Dictator";
  }

  function symbol() public pure returns (string memory) {
    return "TLD";
  }

  function decimals() public pure returns (uint256) {
    return 0;
  }

  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseMetadataURI, "contract"));
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseMetadataURI = baseURI;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseMetadataURI, tokenId.toString(), '_', _donation[tokenId].toString()));
  }


  /// MARK: ERC721 Enumerable
  function totalSupply() public view returns (uint256) {
    uint256 _total = 0;

    for (uint256 i = 0; i < _tokenId; i++) {
      if (_owners[i] != address(0)) {
        _total++;
      }
    }

    return _total;
  }

  function tokenByIndex(uint256 index) public view returns (uint256) {
    uint256 supply = totalSupply();

    uint256[] memory tokens = new uint256[](supply);
    uint256 idx;
    for (uint256 i = 0; i < _tokenId; i++) {
      if (_owners[i] != address(0)) {
        tokens[idx] = i;
        idx++;
      }
    }

    return tokens[index];
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    uint256[] memory tokens = tokensByOwner(owner);
    return tokens[index];
  }

  /// MARK: Custom
  function tokensByOwner(address owner) public view returns (uint256[] memory) {
    require(owner != address(0), "ERC721: query for the zero address");

    uint256 length = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](length);

    uint256 idx;
    for (uint256 i = 0; i < _tokenId; i++) {
      if (_owners[i] == owner) {
        tokenIds[idx] = i;
        idx++;
      }
    }

    return tokenIds;
  }

  function donation() public view returns (uint256) {
    uint256 _sum = 0;

    for (uint256 i = 0; i < _tokenId; i++) {
      _sum += _donation[i];
    }

    return _sum;
  }


  /// MARK: Pausers
  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }
}
