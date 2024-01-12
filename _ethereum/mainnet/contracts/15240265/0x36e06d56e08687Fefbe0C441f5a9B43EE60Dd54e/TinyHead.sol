// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC1155Receiver.sol";
import "./ERC1155Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 *
 * @dev Inheritance details:
 *      Pausable           Allows functions to be Paused, note that this contract includes the metadrop
 *                         time-limited pause, where the contract can only be paused for a defined time period.
 *                         Imported from openzeppelin.
 *      ERC721             Allows the contract to be an ERC721 token. Imported from openzeppelin.
 *      Ownable            Gives the contract an owner, for third-party authentication and to gate pausable.
 *                         Imported from openzeppelin.
 *      IERC1155Received   Allow the contract to receive 1155 tokens. Imported from openzeppelin.
 *
 */

contract TinyHead is ERC721, Pausable, Ownable, IERC1155Receiver {
  using Strings for uint256;

  uint256 public constant STARTER = 0; // 479 total
  uint256 public constant REFILL = 1; // 86 total
  uint256 public constant PLATINUM = 2; // 6 total
  uint256 public constant pauseCutoffDays = 30;

  // ERC-2981: NFT Royalty Standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  uint256 public immutable deployTime;
  // the only address we honor ERC1155 tokens from for minting ERC721s
  address internal immutable _tinyseedContractAddress;

  address public royaltyReceipientAddress;
  uint256 public royaltyPercentageBasisPoints;

  string internal _tokenBaseURI;

  /**
   * Hold 3 counters for each type of NFT.
   * types:  STARTER, REFILL and PLATINUM
   * counts: 479, 86 and 6
   * tokenIds: 0-478 Starter, 479-565 Refill, 565-571 Platinum
   */
  uint256[3] internal _tokenCounts = [0, 479, 565];

  // ============================
  // Events
  // ============================

  event ERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes data
  );
  event ERC1155BatchReceived(
    address operator,
    address from,
    uint256[] ids,
    uint256[] values,
    bytes data
  );

  // ============================
  // Modifiers
  // ============================

  modifier whenTinySeed() {
    require(
      msg.sender == _tinyseedContractAddress,
      "We only accept tokens from TinySeed"
    );
    _;
  }

  // ============================
  // Constructor
  // ============================

  /**
   *
   * @dev constructor.
   * @param tinyseedContractAddress_ The address of the contract you want to burn EIP1155 on(needs to have a getTotalSupply function).
   * @param baseURI_ The base URI for the token metadata. ie. the arweave URL
   * @param royaltyRecipientAddress_ The address of the royalty recipient
   * @param royaltyPercentageBasisPoints_ How much royalties the recipient should receive
   *
   */
  constructor(
    address tinyseedContractAddress_,
    string memory baseURI_,
    address royaltyRecipientAddress_,
    uint256 royaltyPercentageBasisPoints_
  ) ERC721("Tinyhead", "TINYHEAD") {
    _tinyseedContractAddress = tinyseedContractAddress_;
    _tokenBaseURI = baseURI_;
    royaltyReceipientAddress = royaltyRecipientAddress_;
    royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
    deployTime = block.timestamp;
  }

  // ============================
  // Core
  // ============================

  /**
   * mint one ERC721 for each ERC1155 received
   * with each 721 id corresponding to the 1155.tokenId
   * This function is never called directly, but
   * runs when an 1155 token is received.
   */
  function onERC1155BatchReceived(
    address operator_,
    address from_,
    uint256[] calldata ids_,
    uint256[] calldata values_,
    bytes calldata data_
  ) external override returns (bytes4) {
    _mintTokens(from_, ids_, values_);
    emit ERC1155BatchReceived(operator_, from_, ids_, values_, data_);
    return IERC1155Receiver.onERC1155BatchReceived.selector;
  }

  /**
   * See above
   */
  function onERC1155Received(
    address operator_,
    address from_,
    uint256 id_,
    uint256 value_,
    bytes calldata data_
  ) external override returns (bytes4) {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory values = new uint256[](1);
    ids[0] = id_;
    values[0] = value_;
    _mintTokens(from_, ids, values);
    emit ERC1155Received(operator_, from_, id_, value_, data_);
    return IERC1155Receiver.onERC1155Received.selector;
  }

  /**
   * mints 721 tokens to the given address.
   * A different counter is
   * incremented for each 1155 tokenId,
   * corresponding to starter, refill and platinum.
   */
  function _mintTokens(
    address to_,
    uint256[] memory ids_,
    uint256[] memory values_
  ) internal whenTinySeed whenNotPaused {
    require(
      ids_.length == values_.length,
      "ids and values must be the same length"
    );
    for (uint256 i = 0; i < ids_.length; i++) {
      uint256 id = ids_[i];
      uint256 quantity = values_[i];
      require(validateTokenId(id), "Invalid token id");
      for (uint256 j = 0; j < quantity; j++) {
        uint256 tokenId = _tokenCounts[id] + j;
        _safeMint(to_, tokenId);
      }
      _tokenCounts[id] += quantity;
    }
  }

  function validateTokenId(uint256 tokenId_) internal pure returns (bool) {
    return tokenId_ == STARTER || tokenId_ == PLATINUM || tokenId_ == REFILL;
  }

  /**
   * Burn ERC1155 tokens received
   * @param ids_   The tokenIds to burn
   * @param values_ How many tokens to burn
   */
  function burnTinySeeds(uint256[] memory ids_, uint256[] memory values_)
    external
  {
    ERC1155Burnable(_tinyseedContractAddress).burnBatch(
      address(this),
      ids_,
      values_
    );
  }

  // ============================
  // METADATA
  // ============================

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    require(
      ERC721._exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
        : "";
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {
    return _tokenBaseURI;
  }

  // ===============
  // ROYALTY / EIP2981
  // ===============
  /**
   * @dev royaltyInfo: Returns recipent address and royalty.
   *
   */
  function royaltyInfo(uint256, uint256 salePrice_)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    uint256 royalty = (salePrice_ * royaltyPercentageBasisPoints) / 10000;
    return (royaltyReceipientAddress, royalty);
  }

  function setRoyaltyPercentageBasisPoints(
    uint256 royaltyPercentageBasisPoints_
  ) external onlyOwner {
    royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
  }

  function setRoyaltyReceipientAddress(address royaltyReceipientAddress_)
    external
    onlyOwner
  {
    royaltyReceipientAddress = royaltyReceipientAddress_;
  }

  // ===============
  // OVERRIDES
  // ===============

  function supportsInterface(bytes4 interfaceId_)
    public
    view
    override(ERC721, IERC165)
    returns (bool)
  {
    return
      interfaceId_ == _INTERFACE_ID_ERC2981 ||
      super.supportsInterface(interfaceId_);
  }

  // ===============
  // PAUSABLE
  // ===============

  /**
   * contract can only be paused for pauseCutoffDays after deployment
   */
  function pause() external onlyOwner {
    require(
      block.timestamp < (deployTime + pauseCutoffDays * 1 days),
      "Can only pause until the cutoff"
    );
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}
