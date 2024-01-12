//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./base64.sol";
import "./Strings.sol";
import "./AccessControl.sol";
import "./ERC721.sol";
import "./CitizenAlphaMetadata.sol";

/**
 _    _      _      _____   _____ _ _   _               
| |  | |    | |    |____ | /  __ (_) | (_)              
| |  | | ___| |__      / / | /  \/_| |_ _ _______ _ __  
| |/\| |/ _ \ '_ \     \ \ | |   | | __| |_  / _ \ '_ \ 
\  /\  /  __/ |_) |.___/ / | \__/\ | |_| |/ /  __/ | | |
 \/  \/ \___|_.__/ \____/   \____/_|\__|_/___\___|_| |_|

🗺️ Overview:
CitizenAlpha (Beta) is an experiment for bootstrapping a Decentralized Society.
Combining on-chain permissions and off-chain data (ENS text fields i.e. DIDs, pointers, etc...)
CitizenAlpha is an attempt to better understand Web3 of Trust mechanics.
Simple in nature, the contract is only responsible for issuing/revoking of soulbounds. 
Metadata is generated via an external contract: allowing on-going updates during the Beta.

🏗️ Architecture:
Citizens:
  - Issue Citizenship
Founders:
  - Issue Citizenship
  - Revoke Citizenship
  Admin:
  - Issue Citizenship
  - Revoke Citizenship
  - Add Founder
  - Remover Founder
*/

/**
 * @title CitizenAlpha
 * @author Kames Geraghty
 * @notice CitizenAlpha is a Web3 of Trust experiment.
           Combining Soulbounds and Decentralized Identifiers to bootstrap a Decentralized Society.
 */
contract CitizenAlpha is ERC721, AccessControl {
  using Strings for uint256;
  using Strings for address;

  /// @notice Total citizenships issued
  uint256 private _idCounter;

  /// @notice CitizenAlphaMetadata instance used to generate token metadata
  CitizenAlphaMetadata private metadata;

  /// @notice Reverse lookup of a tokenId using the owner address
  mapping(address => uint256) private _tokens;

  /// @notice Lookup address of Citizenship issuer
  mapping(address => address) private _citizenLinks;

  /// @notice Founder Role to enforce access controls
  bytes32 public constant FOUNDER = keccak256("FOUNDER");

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
   * @notice GaugeController Construction
   * @param _metadata CitizenAlphaMetadata instance (manage token metadata)
   * @param _founders Array of Founding Citizens
   */
  constructor(CitizenAlphaMetadata _metadata, address[] memory _founders) ERC721("Citizen", "CIZ") {
    metadata = _metadata;
    for (uint256 i = 0; i < _founders.length; i++) {
      _issue(_founders[i], 0x0000000000000000000000000000000000000000);
      _setupRole(DEFAULT_ADMIN_ROLE, _founders[i]);
      _setupRole(FOUNDER, _founders[i]);
    }
  }

  modifier isAuthorizedCitizen(address _citizen) {
    require(balanceOf(_citizen) == 1, "CitizenAlpha:unauthorized-access");
    _;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  /**
   * @notice Read totalCitizens (_idCounter)
   * @return totalCitizens uint256
   */
  function totalCitizens() external view returns (uint256) {
    return _idCounter;
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
   * @notice Check Citizenship ID
   * @param citizen address
   * @return id uint256
   */
  function getId(address citizen) external view returns (uint256) {
    require(_isCitizen(citizen), "CitizenAlpha:not-active-citizen");
    return _tokens[citizen];
  }

  /**
   * @notice Lookup the issuer of Citizenship
   * @param citizen address
   * @return issuer address
   */
  function getLink(address citizen) external view returns (address issuer) {
    return _citizenLinks[citizen];
  }

  /**
   * @notice Issue a new Citizenship
   * @param to address
   */
  function issue(address to) external isAuthorizedCitizen(msg.sender) {
    require(!_isCitizen(to), "CitizenAlpha:active-citizenship");
    require(!_isPreviouslyIssued(to), "CitizenAlpha:revoked-citizenship");
    _issue(to, msg.sender);
  }

  /**
   * @notice Revoke an existing Citizenship
   * @param from address
   */
  function revoke(address from) external onlyRole(FOUNDER) isAuthorizedCitizen(msg.sender) {
    require(_isCitizen(from), "CitizenAlpha:not-active-citizen");
    uint256 tokenId = _tokens[from];
    _burn(tokenId);
    emit Revoked(tokenId, from, msg.sender);
  }

  /**
   * @notice Add Founder access
   * @param citizen address
   */
  function addFounder(address citizen) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_isCitizen(citizen), "CitizenAlpha:not-active-citizen");
    grantRole(FOUNDER, citizen);
  }

  /**
   * @notice Remove Founder access
   * @param citizen address
   */
  function removeFounder(address citizen) external onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(FOUNDER, citizen);
  }

  /**
   * @notice Check Founder status
   * @param founder address
   * @return status bool
   */
  function isFounder(address founder) external view returns (bool status) {
    return hasRole(FOUNDER, founder);
  }

  /**
   * @notice Override transferFrom to make non-transferable
   */
  function transferFrom(
    address,
    address,
    uint256
  ) public virtual override {
    require(false, "CitizenAlpha: Soulbound");
  }

  /**
   * @notice Generate token URI
   * @param tokenId uint256
   * @return metadata string
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return metadata.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, AccessControl)
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
   */
  function _isPreviouslyIssued(address citizen) internal view returns (bool) {
    return _tokens[citizen] != 0 ? true : false;
  }

  function _issue(address to, address link) internal {
    uint256 __idCounter = _idCounter++;
    _citizenLinks[to] = link;
    _tokens[to] = __idCounter;
    _mint(to, __idCounter);
    emit Issued(__idCounter, to, msg.sender);
  }
}
