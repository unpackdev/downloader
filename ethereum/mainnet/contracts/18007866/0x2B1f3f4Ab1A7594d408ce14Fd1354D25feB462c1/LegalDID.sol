// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract LegalDID is
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721BurnableUpgradeable,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeMathUpgradeable for uint256;

  event RNSAddressAuthorized(string _rnsId, address indexed _wallet);
  event RNSNewID(string _rnsId, address indexed _wallet, uint256 _tokenId);
  event RNSBurnID(string _rnsId, address indexed _wallet, uint256 _tokenId);

  uint256 public mintPrice;
  uint256 public lastTokenId;
  string private baseURI;
  address private destination;

  // do any admin operations but receive fund
  bytes32 public constant SECONDARY_ADMIN_ROLE = keccak256('SECONDARY_ADMIN_ROLE');

  mapping(string => bool) public isMinted;
  mapping(string => bool) public isAuthorized;
  mapping(string => uint256) public numMinted;
  mapping(address => bool) private isBlockedAddress;
  mapping(string => bool) private isBlockedRnsID;

  // Metadata for ID NFT
  mapping(uint256 => bytes32) public tokenIdToMerkle;
  mapping(uint256 => address) public tokenIdToWallet;
  mapping(uint256 => string) public tokenIdToRnsId;

  function initialize() public initializer {
    __ERC721_init('Legal DID', 'LDID');

    // todo: update price; Bril and team please decide mintPrice
    mintPrice = 0.01 ether;

    // todo: change to prod
    baseURI = 'https://api.rns.id/api/v2/portal/identity/nft/';
    __AccessControl_init();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(SECONDARY_ADMIN_ROLE, msg.sender);
    // set contract deployer to be admin role of default and secondary admin role
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(SECONDARY_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    destination = msg.sender;
  }

  function getIdentityKey(string memory _rnsId, address _wallet) internal pure returns (string memory) {
    return string(abi.encodePacked(_rnsId, string(abi.encodePacked(_wallet))));
  }

  function setMintPrice(uint256 _mintPrice) external onlyRole(SECONDARY_ADMIN_ROLE) {
    mintPrice = _mintPrice;
  }

  function setBaseURI(string memory _URI) external onlyRole(SECONDARY_ADMIN_ROLE) {
    baseURI = _URI;
  }

  function setIsBlockedAddress(address _wallet, bool _isBlocked) public onlyRole(SECONDARY_ADMIN_ROLE) {
    isBlockedAddress[_wallet] = _isBlocked;
  }

  function setIsBlockedRnsID(string memory _rnsId, bool _isBlocked) public onlyRole(SECONDARY_ADMIN_ROLE) {
    isBlockedRnsID[_rnsId] = _isBlocked;
  }

  function setTokenIdToMerkle(uint256 tokenId, bytes32 _merkelRoot) external onlyRole(SECONDARY_ADMIN_ROLE) {
    tokenIdToMerkle[tokenId] = _merkelRoot;
  }

  function authorizeMint(string memory _rnsId, address _wallet) external payable nonReentrant {
    string memory idAddressKey = getIdentityKey(_rnsId, _wallet);
    require(!isAuthorized[idAddressKey], 'Authorization is in process, please wait.');
    require(!isBlockedAddress[_wallet], 'the wallet is blacklisted');
    require(!isBlockedRnsID[_rnsId], 'the LDID is blacklisted');
    uint256 fee = mintPrice;
    uint256 numMintedForID = numMinted[_rnsId];
    if (hasRole(SECONDARY_ADMIN_ROLE, msg.sender)) {
      fee = 0;
    }
    require(msg.value >= fee, 'insufficient fund');
    numMinted[_rnsId] = numMintedForID.add(1);
    isAuthorized[idAddressKey] = true;
    emit RNSAddressAuthorized(_rnsId, _wallet);
  }

  function airdrop(
    string memory _rnsId,
    address _wallet,
    bytes32 _merkelRoot
  ) external onlyRole(SECONDARY_ADMIN_ROLE) nonReentrant {
    string memory idAddressKey = getIdentityKey(_rnsId, _wallet);
    require(!isMinted[idAddressKey], 'One LDID can only mint once to the same wallet.');
    require(!isBlockedAddress[_wallet], 'the wallet is blacklisted');
    require(!isBlockedRnsID[_rnsId], 'the LDID is blacklisted');
    isMinted[idAddressKey] = true;
    uint256 tokenId = lastTokenId.add(1);
    lastTokenId = tokenId;

    _safeMint(_wallet, tokenId);

    tokenIdToMerkle[tokenId] = _merkelRoot;
    tokenIdToWallet[tokenId] = _wallet;
    tokenIdToRnsId[tokenId] = _rnsId;

    emit RNSNewID(_rnsId, _wallet, tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenIdToRnsId[tokenId], '.json')) : '';
  }

  function tokenMerkleRoot(uint256 tokenId) public view virtual returns (bytes32) {
    _requireMinted(tokenId);

    return tokenIdToMerkle[tokenId];
  }

  function setFundDestination(address _destination) public onlyRole(DEFAULT_ADMIN_ROLE) {
    destination = _destination;
  }

  function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
    payable(destination).transfer(address(this).balance);
  }

  function supportsInterface(
    bytes4 _interfaceId
  ) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
    return super.supportsInterface(_interfaceId);
  }

  function burn(uint256 _tokenId) public override(ERC721BurnableUpgradeable) {
    super.burn(_tokenId);
    address wallet = tokenIdToWallet[_tokenId];
    string memory rnsId = tokenIdToRnsId[_tokenId];
    string memory idAddressKey = getIdentityKey(rnsId, wallet);
    isMinted[idAddressKey] = false;
    emit RNSBurnID(tokenIdToRnsId[_tokenId], tokenIdToWallet[_tokenId], _tokenId);
  }

  function _beforeTokenTransfer(
    address from, address to, uint256 firstTokenId, uint256 batchSize
) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
    if (from != address(0)) {
        address owner = ownerOf(firstTokenId);
        require(owner == msg.sender, 'Only the owner of LDID can burn it.');
        require(to == address(0) || from == address(0), 'A LDID can only be airdropped or burned.');
    }
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
}
}
