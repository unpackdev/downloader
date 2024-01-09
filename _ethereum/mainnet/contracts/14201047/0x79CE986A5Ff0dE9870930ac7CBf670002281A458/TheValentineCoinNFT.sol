// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface ITheValentineCoinNFTMetadata {
  function contractURI() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ITheValentineCoinOG {
  function ownerOf(uint256 coinId) external view returns (address walletAddress);
  function engrave(uint256 coinId, string memory coinEngraving) external;

  function getApproved(uint256 coinId) external view returns (address approvedWallet);
  function transfer(address newCoinOwner, uint256 coinId) external;
  function transferFrom(address currentCoinOwner, address newCoinOwner, uint256 coinId) external;
  function engravingOf(uint256 coinId) external view returns (string memory coinEngraving);
  function distributeCoin(uint256 coinId, address newCoinOwner, string memory coinEngraving) external;
}

contract TheValentineCoinNFT is ERC721, Ownable {
  using Strings for uint256;

  string private BASE_URI             = "https://api.thevalentinecoin.com/metadata/";
  uint256 public tokenCount           = 0;
  uint256 public constant totalSupply = 33333;
  uint256 public constant tokenPrice  = 33000000000000000;

  address payable _metadataContract;
  address payable _originalContract;

  event MintToken(uint256 indexed tokenId, address indexed minter);
  event EngraveToken(uint256 indexed tokenId, string coinEngraving);

  constructor(address originalContractAddress) ERC721("TheValentineCoin NFT", "LOVE") {
    _originalContract = payable(originalContractAddress);
  }

  modifier _tokenExists(uint256 tokenId) {
    require(_exists(tokenId), "ERC721: query for nonexistent token");
    _;
  }

  modifier _tokenCanBeDistributed(uint256 tokenId) {
    require(tokenId <= totalSupply, "TheValentineCoinNFT: there is no NFT number 33333 or above available");
    require(tokenId > 0, "TheValentineCoinNFT: there is no NFT number 0 available");
    address originalOwner = ITheValentineCoinOG(_originalContract).ownerOf(tokenId);
    require(originalOwner == address(0), "TheValentineCoinNFT: coin on original contract is already owned");
    _;
  }

  function contractURI() public view returns (string memory) {
    if (address(_metadataContract) == address(0)) {
      return BASE_URI;
    }
    return ITheValentineCoinNFTMetadata(_metadataContract).contractURI();
  }

  function tokenURI(uint256 tokenId) _tokenExists(tokenId) public view override returns (string memory) {
    if (address(_metadataContract) == address(0)) {
      return string(abi.encodePacked(BASE_URI, tokenId.toString()));
    }
    return ITheValentineCoinNFTMetadata(_metadataContract).tokenURI(tokenId);
  }

  function engravingOf(uint256 tokenId) _tokenExists(tokenId) public view returns (string memory coinEngraving) {
    return ITheValentineCoinOG(_originalContract).engravingOf(tokenId);
  }

  function engrave(uint256 tokenId, string calldata coinEngraving) external {
    require(ownerOf(tokenId) == _msgSender(), "TheValentineCoinNFT: only the NFT owner can engrave a Valentine Coin");
    require(bytes(engravingOf((tokenId))).length == 0, "TheValentineCoinNFT: a message can only be engraved on a clean Valentine Coin");
    require(bytes(coinEngraving).length > 0, "TheValentineCoinNFT: you can not engrave an empty message");

    ITheValentineCoinOG(_originalContract).engrave(tokenId, coinEngraving);
    emit EngraveToken(tokenId, coinEngraving);
  }

  function mint(uint256 tokenId, string calldata coinEngraving) _tokenCanBeDistributed(tokenId) external payable {
    require(tokenPrice <= msg.value, "TheValentineCoinNFT: value sent is not sufficient");

    ITheValentineCoinOG(_originalContract).distributeCoin(tokenId, address(this), coinEngraving);
    tokenCount += 1;
    _safeMint(_msgSender(), tokenId);
    emit MintToken(tokenId, _msgSender());
    if (bytes(coinEngraving).length > 0) {
      emit EngraveToken(tokenId, coinEngraving);
    }
  }

  function wrap(uint256 tokenId) public {
    address originalOwnerOfToken = ITheValentineCoinOG(_originalContract).ownerOf(tokenId);
    require(originalOwnerOfToken == _msgSender(), "TheValentineCoinNFT: cannot wrap a token you are not the owner of");
    address approvedTransfer = ITheValentineCoinOG(_originalContract).getApproved(tokenId);
    require(approvedTransfer == address(this), "TheValentineCoinNFT: approve transfers from this contract for this token");

    ITheValentineCoinOG(_originalContract).transferFrom(_msgSender(), address(this), tokenId);
    tokenCount += 1;
    _safeMint(_msgSender(), tokenId);
  }

  function unwrap(uint256 tokenId) external {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "TheValentineCoinNFT: cannot unwrap a token you are not the owner of");

    tokenCount -= 1;
    _burn(tokenId);
    ITheValentineCoinOG(_originalContract).transfer(_msgSender(), tokenId);
  }

  function ZZ_adminAirdrop(address to, uint256 tokenId, string calldata coinEngraving) onlyOwner _tokenCanBeDistributed(tokenId) external {
    require(to != address(0), "ERC721: cannot transfer to the genesis address");

    ITheValentineCoinOG(_originalContract).distributeCoin(tokenId, address(this), coinEngraving);
    tokenCount += 1;
    _safeMint(to, tokenId);
    emit MintToken(tokenId, _msgSender());
    if (bytes(coinEngraving).length > 0) {
      emit EngraveToken(tokenId, coinEngraving);
    }
  }

  function ZZ_adminSetMetadataContract(address newMetadataContract) external onlyOwner {
    _metadataContract = payable(newMetadataContract);
  }

  function ZZ_adminRetrieveFunds() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function ZZ_adminTerminateContract() external onlyOwner {
    selfdestruct(payable(_msgSender()));
  }
}
