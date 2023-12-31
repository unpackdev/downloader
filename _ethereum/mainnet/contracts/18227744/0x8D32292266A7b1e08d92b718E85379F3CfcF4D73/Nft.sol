// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./Initializable.sol";

interface INFTV4 {
  // function depositOnMarketplace(uint256 _itemId) external;

  function mint(string calldata _tokenUri) external returns (uint256);

  function transferToken(address _to, uint256 _tokenId) external;
}

contract NFTV4 is
  Initializable,
  ERC721Upgradeable,
  ERC721URIStorageUpgradeable,
  INFTV4
{
  uint256 public tokenCount;
  address public marketplaceContractAddress;
  mapping(address => bool) public gap01; // GAP creators
  address payable public owner; // the account that receives fees

  function initialize(address _marketplaceContractAddress) public initializer {
    __ERC721_init("aidablockchain.com", "AIDA");
    __ERC721URIStorage_init();
    marketplaceContractAddress = _marketplaceContractAddress;
    owner = payable(msg.sender);
  }

  // modifiers
  modifier onlyMarketplace() {
    require(
      msg.sender == marketplaceContractAddress,
      "Only marketplace can do this operation"
    );
    _;
  }
  modifier onlyNftOwner(uint256 _tokenId) {
    require(
      ownerOf(_tokenId) == msg.sender,
      "Only the NFT owner can do this operation"
    );
    _;
  }
  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can do this operation");
    _;
  }

  // The following functions are overrides required by Solidity.
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _burn(
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
    super._burn(tokenId);
  }

  function tokenURI(
    uint256 tokenId
  )
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  // operations
  function increaseTokenCount() external onlyOwner {
    tokenCount++;
  }

  function mint(
    string calldata _tokenURI
  ) external onlyMarketplace returns (uint256) {
    _mint(msg.sender, tokenCount);
    _setTokenURI(tokenCount, _tokenURI);
    tokenCount++;

    return (tokenCount - 1);
  }

  function burn(uint256 _tokenId) external onlyMarketplace {
    _burn(_tokenId);
  }

  function transferToken(
    address _to,
    uint256 _tokenId
  ) external onlyMarketplace {
    _transfer(ownerOf(_tokenId), _to, _tokenId);
  }
}
