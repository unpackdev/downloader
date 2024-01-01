// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.4;

import "./ERC721URIStorageUpgradeable.sol";
import "./Counters.sol";
import "./ERC2981Royalties.sol";


contract DynamicNft is ERC721URIStorageUpgradeable, ERC2981Royalties {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    RoyaltyInfo private _royalty;

    mapping(address => uint256) private _tokenIdMapping;

    function initialize(
      string memory name,
      string memory symbol
    ) public initializer {
        __ERC721_init(name, symbol);
    }

    function mintNft(
      address recipient,
      string memory tokenUri,
      uint256 royaltyValue,
      address airDropContract
    ) public returns (uint256) {
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      _mint(recipient, newItemId);
      _setTokenURI(newItemId, tokenUri);
      _setTokenRoyalty(recipient, royaltyValue);
      _tokenIdMapping[recipient] = newItemId;

      if(airDropContract != address(0)){
        setApprovalForAll(airDropContract, true);
      }

      return newItemId;
    }

    function updateNFT(
      address recipient,
      string memory tokenUri
    ) public returns (uint256) {
      uint256 tokenID = _tokenIdMapping[recipient];
      _requireMinted(tokenID);
      _setTokenURI(tokenID, tokenUri);
      return tokenID;
    }

    function _setTokenRoyalty(address recipient, uint256 value) private{
      require(value <= 1000, 'ERC2981Royalties: Too high');
      _royalty = RoyaltyInfo(recipient, uint24(value));
    }

    function tokenId(address recipient) public view returns (uint256) {
      return _tokenIdMapping[recipient];
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC2981Royalties, ERC721URIStorageUpgradeable)
        returns (bool)
    {
      return super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    )
        external
        view
        override
        returns (address _receiver, uint256 _royaltyAmount)
    {
      RoyaltyInfo memory royalty = _royalty;
      _receiver = royalty.recipient;
      _royaltyAmount = (_salePrice * royalty.amount) / 10000;
      return(_receiver, _royaltyAmount);
    }
}
