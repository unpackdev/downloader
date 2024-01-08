// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ClonesUpgradeable.sol";
import "./IAuthToken.sol";
import "./ERC721Preset.sol";

/**
 * @title NFT contract for licenses
 * @notice The contract provides the issuer and the artists with the required functions to comply and evolve with the regulation
 */
contract LicensedNFT is ERC721Preset {
  using SafeMathUpgradeable for uint256;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  /* Access Control*/
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

  /* Public addresses */
  address public issuer;
  address public artist;

  /* Implementation addresses */
  address public authTokenImplementation;

  /* States */
  mapping(uint256 => bool) internal frozenToken;
  mapping(uint256 => string) internal stateDescription;
  mapping(uint256 => string) internal tokenLegalURI;

  mapping(uint256 => address) internal authToken;
  mapping(uint256 => uint256) internal parentLicense;

  mapping(uint256 => EnumerableSetUpgradeable.UintSet) internal childLicenses;
  bool public subLicensesDeployementPaused;
  bool public authTokenDeployementPaused;

  /* Events */
  event AuthTokensImplementationSet(address _tokenImplementation);
  event AuthTokenDeploymentPaused();
  event AuthTokenDeploymentResumed();
  event AuthTokenDeployed(uint256 _tokenId, address _authAddress);
  event SubLicensesDeploymentPaused();
  event SubLicensesDeploymentResumed();
  event SubLicenseDeployed(
    uint256 _parentLicense,
    uint256 _childLicense,
    address _recipient
  );
  event SubLicenseRevoked(uint256 _tokenId);
  event TokenFrozen(uint256 _tokenId);
  event TokenUnfrozen(uint256 _tokenId);
  event TokenColored(uint256 _tokenId, string _stateDescription);
  event FreezeRequestPrinted(uint256 _tokenId);
  event BaseURIUpdated(string _URI);
  event LegalURIUpdate(uint256 _tokenId, string _newLegalURI);

  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _baseTokenURI,
    address _admin,
    address _issuer,
    address _artist
  ) public initializer {
    super.initialize(_name, _symbol, _baseTokenURI);
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(ADMIN_ROLE, _admin);
    _setupRole(ISSUER_ROLE, _admin);
    _setupRole(ISSUER_ROLE, _issuer);

    subLicensesDeployementPaused = true;
    authTokenDeployementPaused = true;

    issuer = _issuer;
    artist = _artist;
  }

  /**
   * @notice Setter for the base URI of the NFTs
   * @param _baseURI the base URI of the NFTs
   */
  function setBaseURI(string memory _baseURI) public {
    require(hasRole(ADMIN_ROLE, msg.sender), "ERR_CALLER");
    _baseTokenURI = _baseURI;
    emit BaseURIUpdated(_baseURI);
  }

  /* Tokens control functions */
  /**
   * @notice Freeze a particular token
   * @param _tokenId the id of the token
   */
  function freezeToken(uint256 _tokenId) public {
    require(hasRole(ISSUER_ROLE, msg.sender), "ERR_CALLER");
    frozenToken[_tokenId] = true;
    emit TokenFrozen(_tokenId);
  }

  /**
   * @notice Unfreeze a particular token
   * @param _tokenId the id of the token
   */
  function unfreezeToken(uint256 _tokenId) public {
    require(hasRole(ISSUER_ROLE, msg.sender), "ERR_CALLER");
    frozenToken[_tokenId] = false;
    emit TokenUnfrozen(_tokenId);
  }

  /**
   * @notice Color a particular token with a described state
   * @param _tokenId the id of the token
   * @param _stateDescription the description of its state
   */
  function colorToken(uint256 _tokenId, string memory _stateDescription)
    public
  {
    require(hasRole(ISSUER_ROLE, msg.sender), "ERR_CALLER");
    stateDescription[_tokenId] = _stateDescription;
    emit TokenColored(_tokenId, _stateDescription);
  }

  /**
   * @notice Empty tx to record a freeze request by the artist
   * @param _tokenId the id of the token
   */
  function printFreezeRequest(uint256 _tokenId) public {
    require(msg.sender == artist, "ERR_CALLER");
    emit FreezeRequestPrinted(_tokenId);
  }

  /**
   * @notice Issuer function to burn a token
   * @param _tokenId the id of the token
   */
  function cancelToken(uint256 _tokenId) public {
    require(hasRole(ISSUER_ROLE, msg.sender), "ERR_CALLER");
    _burn(_tokenId);
  }

  /**
   * @notice Update the URI for the legal contract associated with a token
   * @param _tokenId the id of the token
   * @param _legalURI the new URI of the legal contract
   */
  function updateTokenLegalURI(uint256 _tokenId, string memory _legalURI)
    public
  {
    require(hasRole(ISSUER_ROLE, msg.sender), "ERR_CALLER");
    tokenLegalURI[_tokenId] = _legalURI;
    emit LegalURIUpdate(_tokenId, _legalURI);
  }

  /* Sub Licenses */
  /**
   * @notice Deploy a sub license of a specific token
   * @param _tokenId the id of the token
   * @param _recipient the address of the recipient of the sublicense
   * @param _name the name of the sublicense
   * @param _symbol the symbol of the sublicense
   * @param _legalURI the URI of the legal contract associated with the sublicense
   */
  function deploySubLicense(
    uint256 _tokenId,
    address _recipient,
    string memory _name,
    string memory _symbol,
    string memory _legalURI
  ) public {
    require(hasRole(ISSUER_ROLE, msg.sender), "ERR_CALLER");
    mint(_recipient, _name, _symbol, _legalURI);
    uint256 sublicenseID = _tokenIdTracker.current();
    parentLicense[sublicenseID] = _tokenId;
    childLicenses[_tokenId].add(sublicenseID);
    emit SubLicenseDeployed(_tokenId, sublicenseID, _recipient);
  }

  /**
   * @notice Revoke a sublicense token
   * @param _subLicenseId the id of the sublicence token
   */
  function revokeSubLicense(uint256 _subLicenseId) public {
    uint256 parentId = parentLicense[_subLicenseId];
    require(hasRole(ISSUER_ROLE, msg.sender), "ERR_CALLER");
    _burn(_subLicenseId);
    delete parentLicense[_subLicenseId];
    childLicenses[parentId].remove(_subLicenseId);
    emit SubLicenseRevoked(_subLicenseId);
  }

  /**
   * @notice Pause the deployement of sublicenses
   */
  function pauseSubLicenseDeployement() public {
    require(hasRole(ADMIN_ROLE, msg.sender), "ERR_CALLER");
    subLicensesDeployementPaused = true;
    emit SubLicensesDeploymentPaused();
  }

  /**
   * @notice Resume the deployement of sublicenses
   */
  function resumeSubLicenseDeployement() public {
    require(hasRole(ADMIN_ROLE, msg.sender), "ERR_CALLER");
    subLicensesDeployementPaused = false;
    emit SubLicensesDeploymentResumed();
  }

  /* Auth */
  function _deployAuthToken(
    uint256 _tokendId,
    string memory _name,
    string memory _symbol
  ) internal returns (address) {
    require(
      authTokenImplementation != address(0x0),
      "ERR_TOKEN_IMPLEMENTATION"
    );
    address newAuth = ClonesUpgradeable.clone(authTokenImplementation);
    IAuthToken(newAuth).initialize(_name, _symbol, _tokendId);
    authToken[_tokendId] = newAuth;
    emit AuthTokenDeployed(_tokendId, newAuth);
    return newAuth;
  }

  /**
   * @notice Pause the deployement of auth tokens
   */
  function pauseAuthTokenDeployement() public {
    require(hasRole(ADMIN_ROLE, msg.sender), "ERR_CALLER");
    authTokenDeployementPaused = true;
    emit AuthTokenDeploymentPaused();
  }

  /**
   * @notice Resume the deployement of auth tokens
   */
  function resumeAuthTokenDeployement() public {
    require(hasRole(ADMIN_ROLE, msg.sender), "ERR_CALLER");
    authTokenDeployementPaused = false;
    emit AuthTokenDeploymentResumed();
  }

  /**
   * @notice Setter for the auth token implementation
   * @param _tokenImplementation the implementation of the auth token
   */
  function setTokenImplementation(address _tokenImplementation) public {
    require(hasRole(ADMIN_ROLE, msg.sender), "ERR_CALLER");
    authTokenImplementation = _tokenImplementation;
    emit AuthTokensImplementationSet(_tokenImplementation);
  }

  /* Getters */

  /**
   * @notice Getter for the parent license of a token
   * @param _tokenId the token id
   * @return the token id of the parent license
   */
  function getParentLicense(uint256 _tokenId) public view returns (uint256) {
    require(_exists(_tokenId), "ERR_TOKEN_ID");
    return parentLicense[_tokenId];
  }

  /**
   * @notice Getter for the child licenses of a token
   * @param _tokenId the token id
   * @return the token ids of the parent license
   */
  function getChildLicenses(uint256 _tokenId)
    public
    view
    returns (uint256[] memory)
  {
    require(_exists(_tokenId), "ERR_TOKEN_ID");
    uint256[] memory childLicensesList =
      new uint256[](childLicenses[_tokenId].length());
    for (uint256 i = 0; i < childLicenses[_tokenId].length(); i++) {
      childLicensesList[i] = childLicenses[_tokenId].at(i);
    }
    return childLicensesList;
  }

  /**
   * @notice Getter for auth token address of a token
   * @param _tokenId the token id
   * @return the address of the auth token
   */
  function getAuthTokenAddress(uint256 _tokenId) public view returns (address) {
    require(_exists(_tokenId), "ERR_TOKEN_ID");
    return authToken[_tokenId];
  }

  /**
   * @notice Getter for the frozen state of a token
   * @param _tokenId the token id
   * @return true if frozen, false otherwise
   */
  function isTokenFrozen(uint256 _tokenId) public view returns (bool) {
    require(_exists(_tokenId), "ERR_TOKEN_ID");
    return frozenToken[_tokenId];
  }

  /**
   * @notice Getter decription of the state of a token
   * @param _tokenId the token id
   * @return the state of the token
   */
  function getTokenStateDescriptionRef(uint256 _tokenId)
    public
    view
    returns (string memory)
  {
    require(_exists(_tokenId), "ERR_TOKEN_ID");
    return stateDescription[_tokenId];
  }

  /* Overrides */
  function mint(
    address _to,
    string memory _name,
    string memory _symbol,
    string memory _legalURI
  ) public {
    require(hasRole(MINTER_ROLE, msg.sender), "ERR_CALLER");
    uint256 tokenId = _tokenIdTracker.current();
    _mint(_to, tokenId);
    _deployAuthToken(tokenId, _name, _symbol);
    _tokenIdTracker.increment();
    tokenLegalURI[tokenId] = _legalURI;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    require(!frozenToken[tokenId], "ERR_TOKEN_FROZEN");
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
