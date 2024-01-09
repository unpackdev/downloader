// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ========== Imports ==========
import "./AdminControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./IERC721.sol";
import "./IERC721Burnable.sol";
import "./IERC1155Burnable.sol";
import "./Strings.sol";


contract RemixBurnRewards is ERC1155, ERC1155Burnable, ERC1155Supply, Pausable, ReentrancyGuard, AdminControl, Ownable {
  using Strings for uint256;

  uint16 constant MAX_SUPPORTED_TOKENS = 65000;

  // ========== Mutable Variables ==========

  string public baseURI;
  mapping(uint16 => uint16) public numClaimsByTokenID;
  mapping(uint16 => uint16) public maximumSupplyByTokenID;

  enum ContractType {
    ERC721,
    ERC1155
  }

  struct BurnEdition {
    address contractAddress;
    uint16 tokenCost; // Number of tokens to burn to claim an edition
    ContractType contractType;
    uint16 supportedToken;
  }
  mapping(uint16 => BurnEdition) public burnEditions;
  uint16 public numBurnEditions;

  // ========== Events ==========
  event ClaimedPhysicalEdition(address indexed burner, uint16 editionId, uint16 tokenId);

  // ========== Constructor ==========

  constructor(
  ) ERC1155(baseURI)
  {
    baseURI = "https://storageapi.fleek.co/apedao-bucket/remix-rewards/";
    numBurnEditions = 0;
    
    _pause();
  }

  // ========== Claiming ==========

  function burnForPhysical(uint16[] calldata _burnTokenIds, uint16 editionId, uint16 editionTokenId, bool claimNFT) public whenNotPaused nonReentrant {
    require(editionId <= numBurnEditions, "Edition not found");
    require(_burnTokenIds.length > 0, "No tokens to burn");

    BurnEdition storage edition = burnEditions[editionId];

    require(edition.supportedToken == editionTokenId, "Token Id is not supported for edition");

    // Calculate quantity
    require(_burnTokenIds.length % edition.tokenCost == 0, "Quantity must be a multiple of token cost");
    uint16 _quantity = uint16(_burnTokenIds.length) / edition.tokenCost;

    // Can only claim if there is supply remaining
    numClaimsByTokenID[editionTokenId] += _quantity;
    require(numClaimsByTokenID[editionTokenId] <= maximumSupplyByTokenID[editionTokenId], "Not enough tokens remaining");

    // Check that tokens are owned by the caller and burn
    if(edition.contractType == ContractType.ERC721) {
      IERC721Burnable supportedContract = IERC721Burnable(edition.contractAddress);
      for (uint16 i=0; i < _burnTokenIds.length; i++) {
        supportedContract.burn(_burnTokenIds[i]);
      }
    } else if (edition.contractType == ContractType.ERC1155) {
      IERC1155Burnable supportedContract = IERC1155Burnable(edition.contractAddress);
      for (uint16 i=0; i < _burnTokenIds.length; i++) {
        supportedContract.burn(msg.sender, _burnTokenIds[i], 1);
      }
    }
    
    if(claimNFT) {
      _mint(msg.sender, editionTokenId, _quantity, "");
    }

    emit ClaimedPhysicalEdition(msg.sender, editionId, editionTokenId);
  }

  // ========== Public Methods ==========

  function getMaximumSupply(uint16 tokenId) public view returns (uint16) {
    return maximumSupplyByTokenID[tokenId];
  }

  function getRemainingSupply(uint16 tokenId) public view returns (uint16) {
    return maximumSupplyByTokenID[tokenId] - numClaimsByTokenID[tokenId];
  }

  function getEdition(uint16 editionId) public view returns (uint256, uint16, address, ContractType) {
    BurnEdition memory edition = burnEditions[editionId];
    return (edition.tokenCost, edition.supportedToken, edition.contractAddress, edition.contractType);
  }

  // ========== Admin ==========

  function addEdition(address _contractAddress, uint16 _tokenCost, uint16 _supportedToken, uint16 _maximumSupply, ContractType contractType) public onlyAdmin {
    uint16 newEditionId = numBurnEditions + 1; 
    burnEditions[newEditionId] = BurnEdition(
      _contractAddress,
      _tokenCost,
      contractType,
      _supportedToken
    );

    maximumSupplyByTokenID[_supportedToken] = _maximumSupply;

    numBurnEditions++;
  }

  function updateEdition(uint16 editionId, address _contractAddress, uint16 _tokenCost, uint16 _supportedToken, ContractType contractType) public onlyAdmin {
    burnEditions[editionId].contractAddress = _contractAddress;
    burnEditions[editionId].tokenCost = _tokenCost;
    burnEditions[editionId].contractType = contractType;
    burnEditions[editionId].supportedToken = _supportedToken;
  }

  function setMaximumSupply(uint16 tokenId, uint16 _maximumSupply) public onlyAdmin {
    maximumSupplyByTokenID[tokenId] = _maximumSupply;
  }

  function ownerMint(address _to, uint16 _tokenId, uint16 _quantity) public onlyAdmin {
    // Can only mint if there is supply remaining
    require(numClaimsByTokenID[_tokenId] + _quantity <= maximumSupplyByTokenID[_tokenId], "Not enough tokens remaining");

    _mint(_to, _tokenId, _quantity, "");
    numClaimsByTokenID[_tokenId] += _quantity;
  }

  function setBaseURI(string memory _baseURI) public onlyAdmin {
    baseURI = _baseURI;
  }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

  function withdraw() public onlyAdmin {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  // ============ Overrides ========

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AdminControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override(ERC1155, ERC1155Supply) {
    super._mint(account, id, amount, data);
  }

  function _mintBatch(address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
    super._mintBatch(account, ids, amounts, data);
  }

  function _burn(address account, uint256 id, uint256 amount) internal override(ERC1155, ERC1155Supply) {
    super._burn(account, id, amount);
  }

  function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal override(ERC1155, ERC1155Supply) {
    super._burnBatch(account, ids, amounts);
  }

  function uri(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId > 0 && _tokenId <= MAX_SUPPORTED_TOKENS, "URI requested for invalid token");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : baseURI;
  }

}
