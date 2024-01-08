// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

//  _   __                    _ _   _____ _      _
// | | / /                   (_|_) |  __ (_)    | |       ___
// | |/ /  __ ___      ____ _ _ _  | |  \/_ _ __| |___   ( _ )
// |    \ / _` \ \ /\ / / _` | | | | | __| | '__| / __|  / _ \/\
// | |\  \ (_| |\ V  V / (_| | | | | |_\ \ | |  | \__ \ | (_>  <
// \_| \_/\__,_| \_/\_/ \__,_|_|_|  \____/_|_|  |_|___/  \___/\/
//   ___        _                 _       _____       _ _           _   _
//  / _ \      (_)               | |     /  __ \     | | |         | | (_)
// / /_\ \_ __  _ _ __ ___   __ _| |___  | /  \/ ___ | | | ___  ___| |_ _  ___  _ __
// |  _  | '_ \| | '_ ` _ \ / _` | / __| | |    / _ \| | |/ _ \/ __| __| |/ _ \| '_ \
// | | | | | | | | | | | | | (_| | \__ \ | \__/\ (_) | | |  __/ (__| |_| | (_) | | | |
// \_| |_/_| |_|_|_| |_| |_|\__,_|_|___/  \____/\___/|_|_|\___|\___|\__|_|\___/|_| |_|

import "./ERC721.sol";
import "./Ownable.sol";

import "./RoyaltiesV2.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

bytes4 constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract KawaiiGirlsAndAnimalsCollection is ERC721, Ownable, RoyaltiesV2 {
  uint96 public defaultPercentageBasisPoints = 1000;
  address public defaultRoyaltiesReceipientAddress = 0xdC10f29d2f606B5f973ff90C68c624f62a6B14B9;
  address public proxyRegistryAddress;
  string public customBaseURI;

  mapping(uint256 => bytes) public ipfsHashMap;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory customBaseURI_,
    address proxyRegistryAddress_
  ) ERC721(name_, symbol_) {
    customBaseURI = customBaseURI_;
    proxyRegistryAddress = proxyRegistryAddress_;
  }

  function mint(address _to, uint256 _tokenId) public onlyOwner {
    _mint(_to, _tokenId);
  }

  function setCustomBaseURI(string memory _customBaseURI) public onlyOwner {
    customBaseURI = _customBaseURI;
  }

  function setDefaultPercentageBasisPoints(uint96 _defaultPercentageBasisPoints) public onlyOwner {
    defaultPercentageBasisPoints = _defaultPercentageBasisPoints;
  }

  function setDefaultRoyaltiesReceipientAddress(address _defaultRoyaltiesReceipientAddress) public onlyOwner {
    defaultRoyaltiesReceipientAddress = _defaultRoyaltiesReceipientAddress;
  }

  function setIpfsHash(uint256 _tokenId, bytes memory _ipfsHash) public onlyOwner {
    ipfsHashMap[_tokenId] = _ipfsHash;
  }

  function deleteIpfsHash(uint256 _tokenId) public onlyOwner {
    delete ipfsHashMap[_tokenId];
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "token must exist");
    bytes memory ipfsHash = ipfsHashMap[_tokenId];
    if (ipfsHash.length > 0) {
      return string(abi.encodePacked("ipfs://", ipfsHash));
    } else {
      return super.tokenURI(_tokenId);
    }
  }

  function getRaribleV2Royalties(uint256) external view override returns (LibPart.Part[] memory) {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = defaultPercentageBasisPoints;
    _royalties[0].account = payable(defaultRoyaltiesReceipientAddress);
    return _royalties;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    return (defaultRoyaltiesReceipientAddress, (_salePrice * defaultPercentageBasisPoints) / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }
}
