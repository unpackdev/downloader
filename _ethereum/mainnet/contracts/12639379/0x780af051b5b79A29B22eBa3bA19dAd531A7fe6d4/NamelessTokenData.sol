// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Strings.sol";
import "./AccessControl.sol";
import "./Initializable.sol";
import "./Clones.sol";

import "./NamelessMetadataURIV1.sol";
import "./INamelessTemplateLibrary.sol";
import "./INamelessToken.sol";
import "./INamelessTokenData.sol";

contract NamelessTokenData is INamelessTokenData, AccessControl, Initializable {
  bytes32 public constant INFRA_ROLE = keccak256('INFRA_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  address private _templateLibrary;
  string private _uriBase;
  address public clonableTokenAddress;
  address public frontendAddress;
  address payable public royaltyAddress;
  uint256 public royaltyBps;

  function initialize (
    address templateLibrary_,
    address clonableTokenAddress_,
    address initialAdmin
  ) public override initializer {
    _templateLibrary = templateLibrary_;
    _uriBase = 'data:application/json;base64,';
    clonableTokenAddress = clonableTokenAddress_;
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
  }

  constructor(
    address templateLibrary_,
    address clonableTokenAddress_
  ) {
    initialize(templateLibrary_, clonableTokenAddress_, msg.sender);
  }

  bool public isSealed;

  modifier onlyUnsealed() {
    require(!isSealed, 'tokens are sealed');
    _;
  }

  modifier onlyFrontend() {
    require(msg.sender == frontendAddress, 'caller not frontend');
    _;
  }

  function sealData() public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!isSealed, 'tokens are sealed');
    isSealed = true;
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

  function configureData( ColumnConfiguration[] calldata configs) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed {
    for(uint idx = 0; idx < configs.length; idx++) {
      _setColumnMetadata(configs[idx].columnHash, configs[idx].columnType);
      _setColumnData(configs[idx].columnHash, configs[idx].data, configs[idx].dataOffset);
    }
  }

  uint256 public constant TOKEN_TRANSFER_COUNT_EXTENSION = 0x1;
  uint256 public constant TOKEN_TRANSFER_TIME_EXTENSION  = 0x2;

  uint256 public extensions;
  function enableExtensions(uint256 newExtensions) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed {
    extensions = extensions | newExtensions;

    if (newExtensions & TOKEN_TRANSFER_COUNT_EXTENSION != 0) {
      initializeTokenTransferCountExtension();
    }

    if (newExtensions & TOKEN_TRANSFER_TIME_EXTENSION != 0) {
      initializeTokenTransferTimeExtension();
    }
  }

  uint256 public constant TOKEN_TRANSFER_COUNT_EXTENSION_SLOT = uint256(keccak256('TOKEN_TRANSFER_COUNT_EXTENSION_SLOT'));
  function initializeTokenTransferCountExtension() internal {
    uint256[1] storage storageMetadata;
    uint256 metadataSlot = TOKEN_TRANSFER_COUNT_EXTENSION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageMetadata.slot := metadataSlot
    }

    storageMetadata[0] = 0x2 << 248;
  }

  function processTokenTransferCountExtension(uint256 tokenId) public onlyFrontend {
    uint256[0xFFFF] storage storageData;
    uint256 columnDataHash = TOKEN_TRANSFER_COUNT_EXTENSION_SLOT + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := columnDataHash
    }

    storageData[tokenId] = storageData[tokenId] + 1;
  }

  uint256 public constant TOKEN_TRANSFER_TIME_EXTENSION_SLOT = uint256(keccak256('TOKEN_TRANSFER_TIME_EXTENSION_SLOT'));
  function initializeTokenTransferTimeExtension() internal {
    uint256[1] storage storageMetadata;
    uint256 metadataSlot = TOKEN_TRANSFER_TIME_EXTENSION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageMetadata.slot := metadataSlot
    }

    storageMetadata[0] = 0x2 << 248;
  }

  function processTokenTransferTimeExtension(uint256 tokenId) public onlyFrontend {
    uint256[0xFFFF] storage storageData;
    uint256 columnDataHash = TOKEN_TRANSFER_TIME_EXTENSION_SLOT + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := columnDataHash
    }

    // solhint-disable-next-line not-rely-on-time
    storageData[tokenId] = block.timestamp;
  }

  function beforeTokenTransfer(address from, address, uint256 tokenId) public onlyFrontend override returns (bool) {
    if (extensions & TOKEN_TRANSFER_COUNT_EXTENSION != 0) {
      // don't count minting as a transfer
      if (from != address(0)) {
        processTokenTransferCountExtension(tokenId);
      }
    }

    if (extensions & TOKEN_TRANSFER_TIME_EXTENSION != 0) {
      processTokenTransferTimeExtension(tokenId);
    }

    return extensions != 0;
  }

  function setRoyalties( address payable newRoyaltyAddress, uint256 newRoyaltyBps ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyAddress = newRoyaltyAddress;
    royaltyBps = newRoyaltyBps;
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

  uint256 public templateIndex;
  bytes32[] public templateData;
  bytes32[] public templateCode;

  function setLibraryTemplate(uint256 which) public onlyRole(DEFAULT_ADMIN_ROLE) {
    templateIndex = which;
    delete(templateData);
    delete(templateCode);
  }

  function setCustomTemplate(bytes32[] calldata _data, bytes32[] calldata _code) public onlyRole(DEFAULT_ADMIN_ROLE) {
    templateIndex = type(uint256).max;
    templateData = _data;
    templateCode = _code;
  }

  function getTokenURI(uint256 tokenId, address owner) public view override returns (string memory) {
    string memory arweaveContentApi;
    string memory ipfsContentApi;
    (arweaveContentApi, ipfsContentApi) = INamelessTemplateLibrary(_templateLibrary).getContentApis();

    if (templateIndex == type(uint256).max) {
      return NamelessMetadataURIV1.makeDataURI(_uriBase, tokenId, owner, arweaveContentApi, ipfsContentApi, templateData, templateCode);
    } else {
      bytes32[] memory libraryTemplateData;
      bytes32[] memory libraryTemplateCode;
      (libraryTemplateData, libraryTemplateCode) = INamelessTemplateLibrary(_templateLibrary).getTemplate(templateIndex);
      return NamelessMetadataURIV1.makeDataURI(_uriBase, tokenId, owner, arweaveContentApi, ipfsContentApi, libraryTemplateData, libraryTemplateCode);
    }
  }

  function getTokenMetadata(uint256 tokenId, address owner) public view returns (string memory) {
    string memory arweaveContentApi;
    string memory ipfsContentApi;
    (arweaveContentApi, ipfsContentApi) = INamelessTemplateLibrary(_templateLibrary).getContentApis();

    if (templateIndex == type(uint256).max) {
      return NamelessMetadataURIV1.makeJson(tokenId, owner, arweaveContentApi, ipfsContentApi, templateData, templateCode);
    } else {
      bytes32[] memory libraryTemplateData;
      bytes32[] memory libraryTemplateCode;
      (libraryTemplateData, libraryTemplateCode) = INamelessTemplateLibrary(_templateLibrary).getTemplate(templateIndex);
      return NamelessMetadataURIV1.makeJson(tokenId, owner, arweaveContentApi, ipfsContentApi, libraryTemplateData, libraryTemplateCode);
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
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override( AccessControl) returns (bool) {
    return AccessControl.supportsInterface(interfaceId);
  }

}
