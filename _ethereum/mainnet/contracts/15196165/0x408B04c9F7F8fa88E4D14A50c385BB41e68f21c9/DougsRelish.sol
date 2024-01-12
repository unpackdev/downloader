// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ReentrancyGuard.sol";

interface IHotDougs {
  function ownerOf(uint256 _tokenId_) external view returns (address);
}

interface IPartner {
  function ownerOf(uint256 _tokenId_) external view returns (address);
}

contract DougsRelish is ReentrancyGuard, ERC1155Supply {
  string public name;
  string public symbol;
  address public owner;
  uint256 public editionId;
  address public HotDougContractAddress = 0xA9074445881FFD9bd1096414149f0FEb8147B4a9;

  constructor() ERC1155("") {
    name = "Dougs Relish";
    symbol = "DR";
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == address(owner), "Unauthorized");
    _;
  }

  mapping(uint256 => editionData) public editionIdToData;

  struct editionData {
    string baseURI;
    string name;
    bool redeemOpen;
    bool publicOpen;
    uint256 maxEditionCount;
    uint256 publicPrice;
    uint256 maxPublicPerTx;
    address allowedProjectAddress;
    uint256 projectRedeemCount;
    uint256 projectRedeemLimit;
    // if the token has been redeemed, mark as true
    mapping(uint256 => bool) redeemedTokens;
    // if the token has been redeemed, mark as true
    mapping(uint256 => bool) redeemedPartnerTokens;
  }

  /// @notice allow the owner to add an edition

  function createNewEdition(
    string memory _name,
    string memory _baseURI,
    bool _redeemOpen,
    bool _publicOpen,
    uint256 _publicPrice,
    uint256 _maxPublicPerTx,
    uint256 _maxEditionCount,
    address _allowedProjectAddress,
    uint256 _projectRedeemLimit
  ) external onlyOwner {
    uint256 nextEdition = editionId + 1;
    editionIdToData[nextEdition].name = _name;
    editionIdToData[nextEdition].baseURI = _baseURI;
    editionIdToData[nextEdition].redeemOpen = _redeemOpen;
    editionIdToData[nextEdition].publicOpen = _publicOpen;
    editionIdToData[nextEdition].publicPrice = _publicPrice;
    editionIdToData[nextEdition].maxPublicPerTx = _maxPublicPerTx;
    editionIdToData[nextEdition].maxEditionCount = _maxEditionCount;
    editionIdToData[nextEdition].allowedProjectAddress = _allowedProjectAddress;
    editionIdToData[nextEdition].projectRedeemLimit = _projectRedeemLimit;
    editionIdToData[nextEdition].projectRedeemCount = 0;
    editionId = nextEdition;
  }

  // ==== GETTERS ====

  /// @notice returns the edition's redemption status (true if open)

  function getEditionRedeemStatus(uint256 _editionId) public view returns (bool) {
    return editionIdToData[_editionId].redeemOpen;
  }

  /// @notice returns the edition's public mint status (true if open)

  function getPublicMintStatus(uint256 _editionId) public view returns (bool) {
    return editionIdToData[_editionId].publicOpen;
  }

  /// @notice returns the edition's name

  function getEditionName(uint256 _editionId) public view returns (string memory) {
    return editionIdToData[_editionId].name;
  }

  /// @notice returns the edition's base URI

  function getEditionBaseURI(uint256 _editionId) public view returns (string memory) {
    return editionIdToData[_editionId].baseURI;
  }

  /// @notice returns the edition's max count

  function getEditionMaxCount(uint256 _editionId) public view returns (uint256) {
    return editionIdToData[_editionId].maxEditionCount;
  }

  /// @notice returns the edition's public price

  function getEditionPublicPrice(uint256 _editionId) public view returns (uint256) {
    return editionIdToData[_editionId].publicPrice;
  }

  /// @notice returns the edition's max public per tx

  function getEditionMaxPerTx(uint256 _editionId) public view returns (uint256) {
    return editionIdToData[_editionId].maxPublicPerTx;
  }

  /// @notice returns the edition's allowed project address

  function getAllowedProjectAddress(uint256 _editionId) public view returns (address) {
    return editionIdToData[_editionId].allowedProjectAddress;
  }

  /// @notice returns the total number of Relish tokens redeemable by owners of the partner NFT

  function getProjectRedeemLimit(uint256 _editionId) public view returns (uint256) {
    return editionIdToData[_editionId].projectRedeemLimit;
  }

  /// @notice checks that the sender owns the required ERC-721 token

  function isOwnerOfPartnerNFT(uint256 _editionId, uint256 _tokenId) internal view returns (bool) {
    address _tokenAddress = editionIdToData[_editionId].allowedProjectAddress;
    return IPartner(_tokenAddress).ownerOf(_tokenId) == msg.sender;
  }

  /// @notice checks that the token has not been used to redeem already

  function isDougTokenRedeemable(uint256 _editionId, uint256 _tokenIdToRedeem)
    public
    view
    returns (bool redeemable)
  {
    return !editionIdToData[_editionId].redeemedTokens[_tokenIdToRedeem];
  }

  /// @notice checks that the token has not been used to redeem already

  function isPartnerAssetRedeemable(uint256 _editionId, uint256 _tokenId)
    public
    view
    returns (bool ownership)
  {
    return !editionIdToData[_editionId].redeemedPartnerTokens[_tokenId];
  }

  /// @notice used for Doug holder redemptions

  function redeemForEdition(uint256 _editionId, uint256[] calldata dougTokenIds)
    external
    payable
    nonReentrant
  {
    require(editionIdToData[_editionId].redeemOpen == true, "Redemption closed");

    uint256 dougTokenCount = dougTokenIds.length;
    uint256 redeemableCount;

    unchecked {
      for (uint256 i = 0; i < dougTokenCount; ++i) {
        uint256 _tokenIdToRedeem = dougTokenIds[i];

        if (
          IHotDougs(HotDougContractAddress).ownerOf(_tokenIdToRedeem) == msg.sender &&
          isDougTokenRedeemable(_editionId, _tokenIdToRedeem)
        ) {
          redeemableCount++;
        }
      }

      require(redeemableCount > 0, "No eligible NFTs");

      require(
        redeemableCount + editionTotalSupply(_editionId) <=
          editionIdToData[_editionId].maxEditionCount,
        "Sold out"
      );

      for (uint256 j = 0; j < dougTokenCount; ++j) {
        editionIdToData[_editionId].redeemedTokens[dougTokenIds[j]] = true;
      }
    }
    mintManyEditions(_editionId, redeemableCount);
  }

  /// @notice used for a partner allotment
  /// @dev only ERC-721 tokens are supported

  function partnerRedeemEdition(uint256 _editionId, uint256[] calldata partnerTokenIds) external {
    require(editionIdToData[_editionId].redeemOpen == true, "Redemption closed");

    uint256 remainingClaims = editionIdToData[_editionId].projectRedeemLimit -
      editionIdToData[_editionId].projectRedeemCount;

    require(remainingClaims > 0, "No claims available");
    
    uint256 partnerTokenCount = partnerTokenIds.length;

    uint256 redeemableCount;

    unchecked {
      for (uint256 i = 0; i < partnerTokenCount; ++i) {
        uint256 _tokenIdToRedeem = partnerTokenIds[i];

        if (
          isOwnerOfPartnerNFT(_editionId, _tokenIdToRedeem) &&
          isPartnerAssetRedeemable(_editionId, _tokenIdToRedeem)
        ) {
          redeemableCount++;
        }
      }

      require(redeemableCount > 0, "No eligible Partner NFTs");

      require(redeemableCount <= remainingClaims, "Not enough claims available");

      require(
        redeemableCount + editionTotalSupply(_editionId) <=
          editionIdToData[_editionId].maxEditionCount,
        "Sold out"
      );

      for (uint256 j = 0; j < redeemableCount; ++j) {
        editionIdToData[_editionId].redeemedPartnerTokens[partnerTokenIds[j]] = true;
      }
    }

    editionIdToData[_editionId].projectRedeemCount += redeemableCount;

    mintManyEditions(_editionId, redeemableCount);
  }

  /// @notice allow anyone to mint a Dougs Relish

  function mintEditionsPublic(uint256 _editionId, uint256 _editionsToMint)
    external
    payable
    nonReentrant
  {
    require(editionIdToData[_editionId].publicOpen == true, "Public not available");

    require(
      _editionsToMint <=
        editionIdToData[_editionId].maxEditionCount - editionTotalSupply(_editionId),
      "Sold out"
    );

    require(
      _editionsToMint <= editionIdToData[_editionId].maxPublicPerTx,
      "Too many mints requested"
    );

    require(
      msg.value >= editionIdToData[_editionId].publicPrice * _editionsToMint,
      "Not enough ETH"
    );

    mintManyEditions(_editionId, _editionsToMint);
  }

  /// @notice allows the contract owner to mint Dougs Relish NFTs

  function ownerMintEditions(uint256 _editionId, uint256 _editionsToMint) external onlyOwner {
    require(
      _editionsToMint <=
        editionIdToData[_editionId].maxEditionCount - editionTotalSupply(_editionId),
      "Sold out"
    );

    mintManyEditions(_editionId, _editionsToMint);
  }

  /// @notice mints many ERC-1155 tokens to the sender
  /// @dev only mints CURRENT editionId

  function mintManyEditions(uint256 _editionId, uint256 _editionsToMint) internal {
    _mint(msg.sender, _editionId, _editionsToMint, abi.encode(editionIdToData[editionId].name));
  }

  /// @notice returns token uri

  function uri(uint256 _editionId) public view override returns (string memory) {
    string memory baseURI = editionIdToData[_editionId].baseURI;

    require(bytes(baseURI).length > 0, "Invalid Edition");

    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, "/", Strings.toString(_editionId), ".json"))
        : baseURI;
  }

  // ==== SETTERS ====

  /// @notice sets HotDoug contract address

  function setHotDougContractAddress(address _contractAddress) external onlyOwner {
    HotDougContractAddress = _contractAddress;
  }

  /// @notice sets an edition's base URI

  function setEditionBaseURI(uint256 _editionId, string calldata _baseURI) external onlyOwner {
    editionIdToData[_editionId].baseURI = _baseURI;
  }

  /// @notice sets an edition's name

  function setEditionName(uint256 _editionId, string calldata _name) external onlyOwner {
    editionIdToData[_editionId].name = _name;
  }

  /// @notice sets an edition's redemption status

  function setEditionRedeemStatus(uint256 _editionId, bool _redeemOpen) external onlyOwner {
    editionIdToData[_editionId].redeemOpen = _redeemOpen;
  }

  /// @notice sets an edition's public status

  function setEditionPublicStatus(uint256 _editionId, bool _publicOpen) external onlyOwner {
    editionIdToData[_editionId].publicOpen = _publicOpen;
  }

  /// @notice sets an edition's public price

  function setEditionPublicPrice(uint256 _editionId, uint256 _publicPrice) external onlyOwner {
    editionIdToData[_editionId].publicPrice = _publicPrice;
  }

  /// @notice sets an edition's max count

  function setEditionMaxCount(uint256 _editionId, uint256 _maxEditionCount) external onlyOwner {
    editionIdToData[_editionId].maxEditionCount = _maxEditionCount;
  }

  /// @notice sets an edition's max public per tx

  function setEditionMaxPerTx(uint256 _editionId, uint256 _maxPublicPerTx) external onlyOwner {
    editionIdToData[_editionId].maxPublicPerTx = _maxPublicPerTx;
  }

  /// @notice sets an edition's partner project contract address

  function setEditionAllowedProjectAddress(uint256 _editionId, address _newContractAddress)
    public
    onlyOwner
  {
    editionIdToData[_editionId].allowedProjectAddress = _newContractAddress;
  }

  /// @notice set limit for a partner project redemption

  function setEditionProjectRedeemLimit(uint256 _editionId, uint256 _projectRedeemLimit)
    public
    onlyOwner
  {
    editionIdToData[_editionId].projectRedeemLimit = _projectRedeemLimit;
  }

  /// @notice allow the owner to remove an edition

  function deleteEdition(uint256 _editionId) public onlyOwner {
    delete editionIdToData[_editionId];
  }

  /// @notice transfers ownership of the contract to a new address

  function transferOwnership(address _newOwner) public onlyOwner {
    owner = _newOwner;
  }

  /// @notice withdraws contract ETH balance to owner address

  function withdrawBalance() external {
    (bool sent, ) = owner.call{ value: address(this).balance }("");
    if (!sent) revert("Could not withdraw balance!");
  }

  /// @notice returns the edition's current toal supply

  function editionTotalSupply(uint256 _editionId)
    public
    view
    returns (uint256 _editionTotalSupply)
  {
    return totalSupply(_editionId);
  }

  /// @notice Allows receiving ETH

  receive() external payable {}
}
