//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Metadata.sol";
import "./Nation.sol";
import "./Notary.sol";

/**
 * @title CitizenAlpha
 * @author Kames Geraghty
 * @notice A Web3 of Trust experiment.
 */
contract CitizenAlpha is ERC721, Ownable {
  /// @notice Total citizenships issued
  uint256 private _idCounter;

  /// @notice Metadata instance; External tokenURI call
  address private _metadata;

  /// @notice Nation instance; Global AccessControl
  address private _nation;

  /// @notice Notary instance; Citizenship Management
  address private _notary;

  /// @notice TrustResolver instance; Unique tokenURI
  address private _resolver;

  /// @notice Enable tokenURI split logic operator
  bool private _tokenURISplit;

  /// @notice Reverse lookup of a tokenId using the owner address
  mapping(address => uint256) private _tokenIds;

  /// @notice Lookup address of Citizenship trust link
  mapping(address => address) private _links;

  /**
   * @notice Emit when Citizenship is issued.
   * @param id Citizen ID
   * @param citizen Address of new Citizen
   * @param link Address of  Citizen issuing new Citizenship
   */
  event Issued(uint256 id, address indexed citizen, address indexed link);

  /**
   * @notice Emit when Citizenship is revoked.
   * @param id Citizen ID
   * @param citizen Address of new Citizen
   * @param link Address of Founder revoking Citizenship
   */
  event Revoked(uint256 id, address indexed citizen, address indexed link);

  /**
   * @notice Emit when Metadata instnace is updated.
   * @param metadata Address of new Metadata instance
   */
  event NewMetadata(address metadata);

  /**
   * @notice Emit when Nation instnace is updated.
   * @param nation Address of new Nation instance
   */
  event NewNation(address nation);

  /**
   * @notice Emit when Notary instnace is updated.
   * @param notary Address of new Notary instance
   */
  event NewNotary(address notary);

  /**
   * @notice Emit when Resolver instnace is updated.
   * @param resolver Address of new Resolver instance
   */
  event NewResolver(address resolver);

  /**
   * @notice CitizenAlpha Construction
   * @param metadata_ address - Metadata instance
   * @param name_ string - Name of ERC721 token
   * @param symbol_ string - Symbol of ERC721 token
   */
  constructor(
    address metadata_,
    string memory name_,
    string memory symbol_
  ) ERC721(name_, symbol_) {
    _metadata = metadata_;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  /**
   * @notice Get Metadata instance
   * @return metadata Metadata
   */
  function getMetadata() external view returns (address metadata) {
    return _metadata;
  }

  /**
   * @notice Get Nation instance
   * @return nation Nation
   */
  function getNation() external view returns (address nation) {
    return _nation;
  }

  /**
   * @notice Get Notary instance
   * @return notary Notary
   */
  function getNotary() external view returns (address notary) {
    return _notary;
  }

  /**
   * @notice Get Resolver instance
   * @return resolver Resolver
   */
  function getResolver() external view returns (address resolver) {
    return _resolver;
  }

  /**
   * @notice Read totalIssued (_idCounter)
   * @return totalIssued uint256
   */
  function totalIssued() external view returns (uint256) {
    return _idCounter;
  }

  /**
   * @notice Check Citizenship ID
   * @param citizen address
   * @return id uint256
   */
  function getId(address citizen) external view returns (uint256) {
    require(_isCitizen(citizen), "CitizenAlpha:not-active-citizen");
    return _tokenIds[citizen];
  }

  /**
   * @notice Lookup Citizenship link
   * @param citizen address
   * @return link address
   */
  function getLink(address citizen) external view returns (address link) {
    return _links[citizen];
  }

  /**
   * @notice Check Role status of Citizen via Nation
   * @param citizen Address of Citizen
   * @return status bool
   */
  function hasRole(bytes32 role, address citizen) external view returns (bool) {
    return Nation(_nation).hasRole(role, citizen);
  }

  /**
   * @notice Check Citizenship status
   * @param citizen Address of potential Citizen
   * @return status bool
   */
  function isCitizen(address citizen) external view returns (bool status) {
    return balanceOf(citizen) == 1 ? true : false;
  }

  /**
   * @notice Generate token URI
   * @param tokenId uint256
   * @return metadata string
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    Metadata metadata_ = Metadata(_metadata);
    if (!_tokenURISplit) {
      return metadata_.tokenURI(tokenId);
    } else {
      return
        _resolver == _msgSender()
          ? metadata_.tokenURIResolver(tokenId)
          : metadata_.tokenURI(tokenId);
    }
  }

  /**
   * @notice Issue a new Citizenship
   * @param to address
   */
  function issue(address to) external {
    address _sender = _msgSender();
    require(Notary(_notary).isNotary(_sender), "CitizenAlpha:not-notary");
    require(!_isCitizen(to), "CitizenAlpha:is-citizen");
    require(!_isPreviouslyIssued(to), "CitizenAlpha:revoked-citizenship");
    _issue(to, _sender);
  }

  /**
   * @notice Revoke an existing Citizenship
   * @param from address
   */
  function revoke(address from) external {
    address _sender = _msgSender();
    require(Notary(_notary).isNotary(_sender), "CitizenAlpha:not-notary");
    require(_isCitizen(from), "CitizenAlpha:not-citizen");
    _revoke(from, _sender);
  }

  /**
   * @notice Reset Citizenship status
   * @param citizen address
   */
  function reset(address citizen) external {
    require(Notary(_notary).isNotary(_msgSender()), "CitizenAlpha:not-notary");
    require(!_isCitizen(citizen), "CitizenAlpha:is-citizen");
    require(_isPreviouslyIssued(citizen), "CitizenAlpha:never-citizen");
    _tokenIds[citizen] = 0;
  }

  /**
   * @notice Set URI Splitter status
   * @param status bool
   */
  function setURISplitter(bool status) external onlyOwner {
    _tokenURISplit = status;
  }

  /**
   * @notice Set Metadata instance
   * @param metadata address
   */
  function setMetadata(address metadata) external onlyOwner {
    _metadata = metadata;
    emit NewMetadata(metadata);
  }

  /**
   * @notice Set Nation instance
   * @param nation address
   */
  function setNation(address nation) external onlyOwner {
    _nation = nation;
    emit NewNation(nation);
  }

  /**
   * @notice Set Notary instance
   * @param notary address
   */
  function setNotary(address notary) external onlyOwner {
    _notary = notary;
    emit NewNotary(notary);
  }

  /**
   * @notice Set Resolver instance
   * @param resolver address
   */
  function setResolver(address resolver) external onlyOwner {
    _resolver = resolver;
    emit NewResolver(resolver);
  }

  /**
   * @notice Override transferFrom to make non-transferable
   */
  function transferFrom(
    address,
    address,
    uint256
  ) public virtual override {
    revert("CitizenAlpha: Soulbound");
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _isCitizen(address citizen) internal view returns (bool) {
    return balanceOf(citizen) == 1 ? true : false;
  }

  /**
   * @dev First Founder can be issued<>revoked<>issued.
   *      All other address can only be issued<>revoked.
   *      Unless the account is reset.
   */
  function _isPreviouslyIssued(address citizen) internal view returns (bool) {
    return _tokenIds[citizen] != 0 ? true : false;
  }

  function _issue(address to, address link) internal {
    uint256 __idCounter = _idCounter++;
    _links[to] = link;
    _tokenIds[to] = __idCounter;
    _mint(to, __idCounter);
    emit Issued(__idCounter, to, link);
  }

  function _revoke(address from, address link) internal {
    uint256 tokenId = _tokenIds[from];
    _burn(tokenId);
    emit Revoked(tokenId, from, link);
  }
}
