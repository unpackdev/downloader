// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Strings.sol";
import "./AccessControl.sol";
import "./Initializable.sol";
import "./Clones.sol";
import "./SafeMath.sol";

import "./NamelessMetadataURIV1.sol";
import "./NamelessDataV1.sol";
import "./INamelessTemplateLibrary.sol";
import "./INamelessToken.sol";
import "./INamelessTokenData.sol";

contract NamelessTokenData is INamelessTokenData, AccessControl, Initializable {
  using SafeMath for uint256;

  bytes32 public constant INFRA_ROLE = keccak256('INFRA_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  address private _templateLibrary;
  string private _uriBase;
  address public clonableTokenAddress;
  address public frontendAddress;
  address payable public royaltyAddress;
  uint256 public royaltyBps;
  uint256 public maxGenerationSize;

  function initialize (
    address templateLibrary_,
    address clonableTokenAddress_,
    address initialAdmin,
    uint256 maxGenerationSize_
  ) public override initializer {
    _templateLibrary = templateLibrary_;
    _uriBase = 'data:application/json;base64,';
    clonableTokenAddress = clonableTokenAddress_;
    maxGenerationSize = maxGenerationSize_;
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
  }

  constructor(
    address templateLibrary_,
    address clonableTokenAddress_,
    uint256 maxGenerationSize_
  ) {
    initialize(templateLibrary_, clonableTokenAddress_, msg.sender, maxGenerationSize_);
  }

  mapping (uint32 => bool) public generationSealed;

  modifier onlyUnsealed(uint32 generation) {
    require(!generationSealed[generation], 'generation is sealed');
    _;
  }

  modifier onlyFrontend() {
    require(msg.sender == frontendAddress, 'caller not frontend');
    _;
  }

  function sealGeneration(uint32 generation) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed(generation){
    generationSealed[generation] = true;
  }

  function _setColumnData(uint256 columnHash, bytes32[] memory data, uint offset ) internal  {
    bytes32[0xFFFF] storage storageData;
    uint256 columnDataHash = columnHash + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := columnDataHash
    }

    for( uint idx = 0; idx < data.length; idx++) {
      storageData[idx + offset] = data[idx];
    }
  }

  function _setColumnMetadata(uint256 columnHash, uint columnType ) internal {
    uint256[1] storage columnMetadata;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      columnMetadata.slot := columnHash
    }

    columnMetadata[0] = columnMetadata[0] | ((columnType & 0xFF) << 248);
  }

  struct ColumnConfiguration {
    uint256 columnHash;
    uint256 columnType;
    uint256 dataOffset;
    bytes32[] data;
  }

  function configureData( uint32 generation, ColumnConfiguration[] calldata configs) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed(generation) {
    for(uint idx = 0; idx < configs.length; idx++) {
      uint256 generationSlot = NamelessDataV1.getGenerationalSlot(configs[idx].columnHash, generation);
      _setColumnMetadata(generationSlot, configs[idx].columnType);
      _setColumnData(generationSlot, configs[idx].data, configs[idx].dataOffset);
    }
  }

  function idToGenerationIndex(uint256 tokenId) internal view returns (uint32 generation, uint index) {
    generation = uint32(tokenId / maxGenerationSize);
    index = tokenId % maxGenerationSize;
  }

  uint256 public constant TOKEN_TRANSFER_COUNT_EXTENSION = 0x1;
  uint256 public constant TOKEN_TRANSFER_TIME_EXTENSION  = 0x2;
  uint256 public constant TOKEN_REDEEMABLE_EXTENSION     = 0x4;

  mapping (uint => uint256) public extensions;
  function enableExtensions(uint32 generation, uint256 newExtensions) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed(generation) {
    extensions[generation] = extensions[generation] | newExtensions;

    if (newExtensions & TOKEN_TRANSFER_COUNT_EXTENSION != 0) {
      initializeTokenTransferCountExtension(generation);
    }

    if (newExtensions & TOKEN_TRANSFER_TIME_EXTENSION != 0) {
      initializeTokenTransferTimeExtension(generation);
    }

    if (newExtensions & TOKEN_REDEEMABLE_EXTENSION != 0) {
      initializeTokenRedeemableExtension(generation);
    }
  }

  uint256 public constant TOKEN_TRANSFER_COUNT_EXTENSION_SLOT = uint256(keccak256('TOKEN_TRANSFER_COUNT_EXTENSION_SLOT'));
  function initializeTokenTransferCountExtension(uint32 generation) internal {
    uint256[1] storage storageMetadata;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_TRANSFER_COUNT_EXTENSION_SLOT, generation);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageMetadata.slot := generationalSlot
    }

    storageMetadata[0] = 0x2 << 248;
  }

  function processTokenTransferCountExtension(uint32 generation, uint index) internal {
    uint256[0xFFFF] storage storageData;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_TRANSFER_COUNT_EXTENSION_SLOT, generation);
    uint256 dataSlot = generationalSlot + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := dataSlot
    }

    storageData[index] = storageData[index] + 1;
  }

  uint256 public constant TOKEN_TRANSFER_TIME_EXTENSION_SLOT = uint256(keccak256('TOKEN_TRANSFER_TIME_EXTENSION_SLOT'));
  function initializeTokenTransferTimeExtension(uint32 generation) internal {
    uint256[1] storage storageMetadata;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_TRANSFER_TIME_EXTENSION_SLOT, generation);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageMetadata.slot := generationalSlot
    }

    storageMetadata[0] = 0x2 << 248;
  }

  function processTokenTransferTimeExtension(uint32 generation, uint index) internal {
    uint256[0xFFFF] storage storageData;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_TRANSFER_COUNT_EXTENSION_SLOT, generation);
    uint256 dataSlot = generationalSlot + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := dataSlot
    }

    // solhint-disable-next-line not-rely-on-time
    storageData[index] = block.timestamp;
  }

  uint256 public constant TOKEN_REDEMPTION_EXTENSION_COUNT_SLOT = uint256(keccak256('TOKEN_REDEMPTION_EXTENSION_COUNT_SLOT'));

  function initializeTokenRedeemableExtension(uint32 generation) internal {
    uint256[1] storage storageMetadata;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_REDEMPTION_EXTENSION_COUNT_SLOT, generation);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageMetadata.slot := generationalSlot
    }

    storageMetadata[0] = 0x2 << 248;  // uint256
  }


  function beforeTokenTransfer(address from, address, uint256 tokenId) public onlyFrontend override returns (bool) {
    (uint32 generation, uint index) = idToGenerationIndex(tokenId);
    if (extensions[generation] & TOKEN_TRANSFER_COUNT_EXTENSION != 0) {
      // don't count minting as a transfer
      if (from != address(0)) {
        processTokenTransferCountExtension(generation, index);
      }
    }

    if (extensions[generation] & TOKEN_TRANSFER_TIME_EXTENSION != 0) {
      processTokenTransferTimeExtension(generation, index);
    }

    return extensions[generation] & (TOKEN_TRANSFER_COUNT_EXTENSION | TOKEN_TRANSFER_TIME_EXTENSION) != 0;
  }

  function redeem(uint256 tokenId) public onlyFrontend override {
    (uint32 generation, uint index) = idToGenerationIndex(tokenId);
    require(extensions[generation] & TOKEN_REDEEMABLE_EXTENSION != 0, 'Token is not redeemable' );

    uint256[65535] storage redemptionCount;
    uint generationalSlot = NamelessDataV1.getGenerationalSlot(TOKEN_REDEMPTION_EXTENSION_COUNT_SLOT, generation);
    uint256 redemptionCountSlot = generationalSlot + 1;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      redemptionCount.slot := redemptionCountSlot
    }

    redemptionCount[index] = redemptionCount[index] + 1;
  }

  struct RoyaltyInfo {
      address recipient;
      uint24 amount;
  }

  RoyaltyInfo private _royalties;

  //Contract Level Royalties
  function setRoyalties( address payable newRoyaltyAddress, uint256 newRoyaltyBps ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(royaltyBps <= 10000, 'ERC2981Royalties: Too high');
    _royalties = RoyaltyInfo(newRoyaltyAddress, uint24(newRoyaltyBps));
  }

  function royaltyInfo(uint256, uint256 _salePrice)
      external
      view
      override
      returns (address receiver, uint256 royaltyAmount)
  {
      RoyaltyInfo memory royalties = _royalties; 
      receiver = royalties.recipient;
      royaltyAmount = (_salePrice.mul(royalties.amount)).div(10000);
  }

  function getFeeRecipients(uint256) public view override returns (address payable[] memory) {
    address payable[] memory result = new address payable[](1);
    result[0] = royaltyAddress;
    return result;
  }

  function getFeeBps(uint256) public view override returns (uint256[] memory) {
    uint256[] memory result = new uint256[](1);
    result[0] = royaltyBps;
    return result;
  }

  function setURIBase(string calldata uriBase_) public onlyRole(INFRA_ROLE) {
    _uriBase = uriBase_;
  }

  mapping (uint32 => uint256) public templateIndex;
  mapping (uint32 => bytes32[]) public templateData;
  mapping (uint32 => bytes32[]) public templateCode;

  function setLibraryTemplate(uint32 generation, uint256 which) public onlyRole(DEFAULT_ADMIN_ROLE) {
    templateIndex[generation] = which;
    delete(templateData[generation]);
    delete(templateCode[generation]);
  }

  function setCustomTemplate(uint32 generation, bytes32[] calldata _data, bytes32[] calldata _code) public onlyRole(DEFAULT_ADMIN_ROLE) {
    delete(templateIndex[generation]);
    templateData[generation] = _data;
    templateCode[generation] = _code;
  }

  function getTokenURI(uint256 tokenId, address owner) public view override returns (string memory) {
    string memory arweaveContentApi;
    string memory ipfsContentApi;
    (arweaveContentApi, ipfsContentApi) = INamelessTemplateLibrary(_templateLibrary).getContentApis();
    (uint32 generation, uint index) = idToGenerationIndex(tokenId);

    if (templateCode[generation].length > 0) {
      return NamelessMetadataURIV1.makeDataURI(_uriBase, tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, templateData[generation], templateCode[generation]);
    } else {
      bytes32[] memory libraryTemplateData;
      bytes32[] memory libraryTemplateCode;
      (libraryTemplateData, libraryTemplateCode) = INamelessTemplateLibrary(_templateLibrary).getTemplate(templateIndex[generation]);
      return NamelessMetadataURIV1.makeDataURI(_uriBase, tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, libraryTemplateData, libraryTemplateCode);
    }
  }

  function getTokenMetadata(uint256 tokenId, address owner) public view returns (string memory) {
    string memory arweaveContentApi;
    string memory ipfsContentApi;
    (arweaveContentApi, ipfsContentApi) = INamelessTemplateLibrary(_templateLibrary).getContentApis();
    (uint32 generation, uint index) = idToGenerationIndex(tokenId);

    if (templateCode[generation].length > 0) {
      return NamelessMetadataURIV1.makeJson(tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, templateData[generation], templateCode[generation]);
    } else {
      bytes32[] memory libraryTemplateData;
      bytes32[] memory libraryTemplateCode;
      (libraryTemplateData, libraryTemplateCode) = INamelessTemplateLibrary(_templateLibrary).getTemplate(templateIndex[generation]);
      return NamelessMetadataURIV1.makeJson(tokenId, generation, index, owner, arweaveContentApi, ipfsContentApi, libraryTemplateData, libraryTemplateCode);
    }
  }

  function createFrontend(string calldata name, string calldata symbol) public onlyRole(MINTER_ROLE) returns (address) {
    require(frontendAddress == address(0), 'frontend already created');
    frontendAddress = Clones.clone(clonableTokenAddress);

    INamelessToken frontend = INamelessToken(frontendAddress);
    frontend.initialize(name, symbol, address(this), msg.sender);

    return frontendAddress;
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    * @dev can possibly remove this
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override( AccessControl) returns (bool) {
    return AccessControl.supportsInterface(interfaceId);
  }

}
