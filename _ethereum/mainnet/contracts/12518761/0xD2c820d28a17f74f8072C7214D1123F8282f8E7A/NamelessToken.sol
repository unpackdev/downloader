// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Initializable.sol";

import "./NamelessMetadataURIV1.sol";
import "./INamelessTemplateLibrary.sol";

contract NamelessToken is ERC721Enumerable, AccessControl, Initializable {
  event TokenMetadataChanged(uint256 tokenId);

  bytes32 public constant INFRA_ROLE = keccak256('INFRA_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  // Duplicate Token name for cloneability
  string private _name;
  // Duplicate Token symbol for cloneability
  string private _symbol;

  address private _templateLibrary;
  string private _uriBase;

  address payable public royaltyAddress;
  uint256 public royaltyBps;

  function initialize (
    string memory name_,
    string memory symbol_,
    address templateLibrary_,
    address initialAdmin
  ) public initializer {
    _name = name_;
    _symbol = symbol_;
    _templateLibrary = templateLibrary_;
    _uriBase = 'data:application/json;base64,';
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
  }

  constructor(
    string memory name_,
    string memory symbol_,
    address templateLibrary_
  ) ERC721(name_, symbol_) {
    initialize(name_, symbol_, templateLibrary_, msg.sender);
  }

  bool public isSealed;

  modifier onlyUnsealed() {
    require(!isSealed, 'tokens are sealed');
    _;
  }

  modifier onlySealed() {
    require(isSealed, 'tokens are not sealed');
    _;
  }

  function sealTokens() public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed {
    isSealed = true;
  }

  function setColumnData(uint256 columnHash, bytes32[] calldata data, uint offset ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed {
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

  function setColumnMetadata(uint256 columnHash, uint columnType ) public onlyRole(DEFAULT_ADMIN_ROLE) onlyUnsealed {
    uint256[1] storage columnMetadata;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      columnMetadata.slot := columnHash
    }

    columnMetadata[0] = columnMetadata[0] | ((columnType & 0xFF) << 248);
  }

  function setURIBase(string calldata uriBase_) public onlyRole(INFRA_ROLE) {
    _uriBase = uriBase_;
  }

  /**
    * @dev See {IERC721Metadata-name}.
    */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
    * @dev See {IERC721Metadata-symbol}.
    */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  function getFeeRecipients(uint256) public view returns (address payable[] memory) {
    address payable[] memory result = new address payable[](1);
    result[0] = royaltyAddress;
    return result;
  }

  function getFeeBps(uint256) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](1);
    result[0] = royaltyBps;
    return result;
  }

  function setRoyalties( address payable newRoyaltyAddress, uint256 newRoyaltyBps ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyAddress = newRoyaltyAddress;
    royaltyBps = newRoyaltyBps;
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

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), 'no such token');
    string memory arweaveContentApi;
    string memory ipfsContentApi;
    (arweaveContentApi, ipfsContentApi) = INamelessTemplateLibrary(_templateLibrary).getContentApis();

    if (templateIndex == type(uint256).max) {
      return NamelessMetadataURIV1.makeDataURI(_uriBase, tokenId, ownerOf(tokenId), arweaveContentApi, ipfsContentApi, templateData, templateCode);
    } else {
      bytes32[] memory libraryTemplateData;
      bytes32[] memory libraryTemplateCode;
      (libraryTemplateData, libraryTemplateCode) = INamelessTemplateLibrary(_templateLibrary).getTemplate(templateIndex);
      return NamelessMetadataURIV1.makeDataURI(_uriBase, tokenId, ownerOf(tokenId), arweaveContentApi, ipfsContentApi, libraryTemplateData, libraryTemplateCode);
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

  function processTokenTransferCountExtension(uint256 tokenId) internal {
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

  function processTokenTransferTimeExtension(uint256 tokenId) internal {
    uint256[0xFFFF] storage storageData;
    uint256 columnDataHash = TOKEN_TRANSFER_TIME_EXTENSION_SLOT + 1;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      storageData.slot := columnDataHash
    }

    // solhint-disable-next-line not-rely-on-time
    storageData[tokenId] = block.timestamp;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);
    if (extensions & TOKEN_TRANSFER_COUNT_EXTENSION != 0) {
      // don't count minting as a transfer
      if (from != address(0)) {
        processTokenTransferCountExtension(tokenId);
      }
    }

    if (extensions & TOKEN_TRANSFER_TIME_EXTENSION != 0) {
      processTokenTransferTimeExtension(tokenId);
    }

    if (extensions != 0) {
      emit TokenMetadataChanged(tokenId);
    }
  }

  function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) onlySealed {
    _safeMint(to, tokenId);
  }

  function mint(address creator, address recipient, uint256 tokenId) public onlyRole(MINTER_ROLE) onlySealed {
    _safeMint(creator, tokenId);
    _safeTransfer(creator, recipient, tokenId, '');
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
    return interfaceId == _INTERFACE_ID_FEES
      || ERC721Enumerable.supportsInterface(interfaceId)
      || AccessControl.supportsInterface(interfaceId);
  }
}
