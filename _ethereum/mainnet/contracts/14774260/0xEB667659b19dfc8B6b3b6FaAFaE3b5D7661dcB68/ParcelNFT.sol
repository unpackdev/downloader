// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721RoyaltyUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./AllowListClaim.sol";
import "./RoyaltyEventSupport.sol";
import "./TokenUriStorage.sol";
import "./Roles.sol";
import "./ERC721BatchTransfer.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BG5YJ??7777777?JY5PB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@&BPJ7!!!7?JY55PPPP55YJ?7!!!7J5B&@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@&GJ7!!?YPB&&@@@@@@@@@@@@@@@&BGY?!!!JP#@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@BY!!7YG#@@@@@@@@@@@@@@@@@@@@@@@@@@&GY7!!JG@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@P?!!JG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BY!!?P&@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@B?!!Y#@@@@@@@@@@@@@@@@&GYJ@@@@@@@@@@@@@@@@@@#57!7G@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@&Y!!J#@@@@@@@@@@@@@@&B5??YG#@@@@@@@@@@@@@@@@@@@@&Y!!J#@@@@@@@@@@@@@
 * @@@@@@@@@@@@#?!!P@@@@@@@@@@@@@#PJ?JPB&#PY@@@@@@@@@@@@@@@@@@@@@@G7!7B@@@@@@@@@@@@
 * @@@@@@@@@@@B7!7B@@@@@@@@@@@GY??5B##GY??5B@@@@@@@@@@@@@@@@##@@@@@#?!!G@@@@@@@@@@@
 * @@@@@@@@@@#7!7#@@@@@@@@@@@@5P#&B5??YG#&G5@@@@@@@@@@@@&GY?!7?5B&@@&?!!B@@@@@@@@@@
 * @@@@@@@@@@?!!B@@@@@@@@@@@@@#PJ?JP#&BPJ?JG@@@@@@@@&B5J7!!!!J#PJ?JP##7!7&@@@@@@@@@
 * @@@@@@@@@P!!Y@@@@@@@@@@@@@@Y5B&#GY?J5B&#G@@@@@#PY7!!!!!!!!J@@@&B5JJ7!!Y@@@@@@@@@
 * @@@@@@@@@?!!#@@@@@@@@@@@@@@&B5??YG&#GY??P@@@@J!!!!!!!!!!!!J@@@@@@@&BPJ?&@@@@@@@@
 * @@@@@@@@#!!?@@@@@@@@@@@@@@@YJP#&B5J?YG#&B@@@&7!!!!!!!!!!!!J@@@@@@@@@@@&@@@@@@@@@
 * @@@@@@@@B!!Y@@@@@@@@@@@@@@@&#PJ?JP#&#PJ?Y@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@B!!Y@@@@@@@@@@@@@@@Y?5B&#GY??5B&#@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@#!!?@@@@@@@@@@@@@@@&&B5??YG#&BY?J@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@?!!#@@@@@@#GYJ5B&@5?JP#&BPJ?YG#&@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@G!!Y@@&B5?!!!!YJ?JYB#GY?JPB&#PJJ@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@J!!YJ7!!!!!!7&@#GY?!!JB#GY??5B&@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@&7!!!!!!!!!!7&@@@@@#PJ??YG#&B5Y@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@#7!!!!!!!!!7&@@@@@@@@&&#PJ?JP#@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@&?!!!!!!!!7&@@@@@@@@@Y?5B&#PY@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@5!!!!!!!7&@@@@@@@@@&&GY??5B@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@#J!!!!!7&@@@@@@@@@Y?YG#&BP@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@BJ!!!7&@@@@@@@@@#&#PJ?JG@@@&7!!!!!!!!!!!!J@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@#57!&@@@@@@@@@5?J5B&#B@@@&7!!!!!!!!!!!!Y@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@&B&@@@@@@@@@G#&B5?!7@@@@7!!!!!!!!!?YG&@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J?7!!!!7YYYJ!!!!!7?YP#@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@PYJJJ??????JY5PB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * |--------------------------------------------------------------------------------|
 * Hello fellow CityDAO Citizen,
 * In this smart contract you find the Parcel-0 Drop from CityDAO!
 * We are using an merkle proof whitelisting drop to reduce gas cost.
 *
 * ~ Let's Build this City!
 *
 * Developed By: @slyRacoon23 & @mdnatx
 */
contract ParcelNFT is
  UUPSUpgradeable,
  AllowListClaim,
  ERC721URIStorageUpgradeable,
  RoyaltyEventSupport,
  ERC721RoyaltyUpgradeable,
  ERC721BatchTransfer,
  AccessControlUpgradeable,
  PausableUpgradeable
{
  struct InitParams {
    string name;
    string symbol;
    address superAdmin;
  }

  function initialize(InitParams memory initParams) public initializer {
    __ERC721_init(initParams.name, initParams.symbol);
    __ERC721Enumerable_init_unchained();
    __ERC721URIStorage_init_unchained();
    __ERC2981_init_unchained();
    __ERC721Royalty_init_unchained();
    __AccessControl_init_unchained();
    __Pausable_init_unchained();

    if (initParams.superAdmin == address(0)) {
      initParams.superAdmin = _msgSender();
    }
    _setupRole(Roles.SUPER_ADMIN, initParams.superAdmin);
  }

  /**
   * @notice Attempts to mint the given amount of tokens to the given account.
   */
  function allowListMint(
    uint256 amount,
    uint256 allowance,
    bytes32[] calldata proof
  ) public payable {
    _allowListMint(_msgSender(), amount, allowance, proof);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(
      AccessControlUpgradeable,
      AllowListClaim,
      ERC721RoyaltyUpgradeable,
      ERC721Upgradeable,
      ERC721BatchTransfer,
      ERC2981Upgradeable
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @notice Gets base URI for all tokens, if set.
   */
  function baseURI() public view returns (string memory) {
    return _baseURI();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return TokenUriStorage.baseURI();
  }

  /**
   * @notice Sets `baseURI` as the base URI for all tokens. Used when explicit tokenURI not set.
   */
  function setBaseURI(string calldata __baseURI) external onlyRole(Roles.PARCEL_MANAGER) {
    TokenUriStorage.setBaseURI(__baseURI);
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  /**
   * @notice Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyRole(Roles.PARCEL_MANAGER) {
    _setTokenURI(tokenId, _tokenURI);
  }

  /**
   * @notice sets the claim period start and end with block timestamps
   */
  function setClaimPeriod(uint256 start, uint256 end) public onlyRole(Roles.PARCEL_MANAGER) {
    _setClaimPeriod(start, end);
  }

  /**
   * @notice Sets the merkle root for the allow list claim
   */
  function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(Roles.PARCEL_MANAGER) {
    _setMerkleRoot(_merkleRoot);
  }

  /**
   * @notice Sets the royalty information that all ids in this contract will default to.
   *
   * Requirements:
   *
   * - `receiver` cannot be the zero address.
   * - `feeNumerator` cannot be greater than the fee denominator.
   */
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(Roles.PARCEL_MANAGER) {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   * @inheritdoc ERC2981Upgradeable
   */
  function _setDefaultRoyalty(address receiver, uint96 feeNumerator)
    internal
    virtual
    override(RoyaltyEventSupport, ERC2981Upgradeable)
  {
    super._setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   * @notice Removes default royalty information.
   */
  function deleteDefaultRoyalty() external onlyRole(Roles.PARCEL_MANAGER) {
    _deleteDefaultRoyalty();
  }

  /**
   * @inheritdoc ERC2981Upgradeable
   */
  function _deleteDefaultRoyalty() internal virtual override(RoyaltyEventSupport, ERC2981Upgradeable) {
    super._deleteDefaultRoyalty();
  }

  /**
   * @notice Sets the royalty information for a specific token id, overriding the global default.
   *
   * Requirements:
   *
   * - `tokenId` must be already minted.
   * - `receiver` cannot be the zero address.
   * - `feeNumerator` cannot be greater than the fee denominator.
   */
  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external onlyRole(Roles.PARCEL_MANAGER) {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  /**
   * @inheritdoc ERC2981Upgradeable
   */
  function _setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) internal virtual override(RoyaltyEventSupport, ERC2981Upgradeable) {
    super._setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  /**
   * @notice Resets royalty information for the token id back to the global default.
   */
  function resetTokenRoyalty(uint256 tokenId) external onlyRole(Roles.PARCEL_MANAGER) {
    _resetTokenRoyalty(tokenId);
  }

  /**
   * @inheritdoc ERC2981Upgradeable
   */
  function _resetTokenRoyalty(uint256 tokenId) internal virtual override(RoyaltyEventSupport, ERC2981Upgradeable) {
    super._resetTokenRoyalty(tokenId);
  }

  /**
   * @notice Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function pause() external onlyRole(Roles.PAUSER) {
    _pause();
  }

  /**
   * @notice Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function unpause() external onlyRole(Roles.PAUSER) {
    _unpause();
  }

  function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable, ERC721Upgradeable)
  {
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(Roles.UPGRADER) {}
}
