// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";

//                        :+%%+:
//                    .-*@@@@@@@@#=.
//                 :+%@@@@@@@@@@@@@@%+:
//              -*@@@@@@@%+:  :=#@@@@@@@*-.
//          :+#@@@@@@@*-       :+%@@@@@@@@@%+:
//       -*@@@@@@@%+:       -*@@@@@@@%*%@@@@@@@*-
//   .=#@@@@@@@*=.      :+%@@@@@@@*=.   .-*@@@@@@@#=.
//  @@@@@@@%+:       -*@@@@@@@%+:       -+%@@@@@@%+:
//  @@@@@=.      :=#@@@@@@@#=.      .=#@@@@@@@*-.  :+%
//  @@@@%     -*@@@@@@@%+-       :+%@@@@@@%+:  .=#@@@@
//  @@@@%    +@@@@@@#=.      .=#@@@@@@@#=.  :+%@@@@@@@
//  @@@@%    +@@@@+       :+%@@@@@@%+:  .-*@@@@@@@@@@@
//  @@@@%    +@@@@-    =*@@@@@@@#=.  :+%@@@@@@%*-#@@@@
//  @@@@%    +@@@@-    @@@@@%+:  .=*@@@@@@@#=.   *@@@@
//  @@@@%    +@@@@-    @@@@#  :+%@@@@@@@*-       *@@@@
//  @@@@%    +@@@@-    @@@@#  #@@@@@#+:          *@@@@
//  @@@@%    +@@@@-    @@@@#  #@@@@.      :+=    *@@@@
//  @@@@%    +@@@@-    @@@@#  #@@@@.    *@@@*    *@@@@
//  @@@@%    +@@@@-    @@@@#  #@@@@.   .@@@@+    *@@@@
//  @@@@%    +@@@@-    @@@@#  #@@@@.   .@%+:     *@@@@
//  @@@@%    +@@@@-    @@@@#  #@@@@.    .      .=%@@@@
//  %@@@%    +@@@@-    @@@@#  #@@@@.        :+%@@@@@@%
//   .-*#    +@@@@-    @@@@#  #@@@@.    .=#@@@@@@@*=.
//           +@@@@-    @@@@#  #@@@@. :+%@@@@@@%+:
//           :*@@@-    @@@@#  #@@@@#@@@@@@@#=.
//              :+:    @@@@#  #@@@@@@@@%+:
//                     @@@@#  #@@@@@#=.
//                     :+%@#  #@%+:

/*
* @title ERC1155 contract for MetaOrganization (https://metaorganization.com/)
*
* @author loltapes.eth
*/
contract MetaOrganizationAccessPass is ERC1155, ERC1155Burnable, ERC1155Supply, Ownable, Pausable {
  // @notice configuration of a single pass
  struct Pass {
    uint128 mintPrice;
    uint96 maxSupply;
    uint32 walletMintLimit;
    string metadataUri;
  }

  // tokenId => (wallet => amount minted)
  mapping(uint256 => mapping(address => uint256)) public minted;

  // @notice indicates which pass is currently up for sale
  uint256 public tokenIdForSale;

  // tokenId => Pass
  mapping(uint256 => Pass) public tokens;

  // @notice allows to freeze the configuration of a pass to prevent further modification
  // tokenId => is frozen flag
  mapping(uint256 => bool) public frozenTokens;

  // @notice indicates a token metadata was frozen
  // compatibility with OpenSea https://docs.opensea.io/docs/metadata-standards
  event PermanentURI(string _value, uint256 indexed _id);

  // @notice address to withdraw funds
  address payable private _payoutAddress;

  // @notice Current root for reserved sale proofs
  bytes32 public currentMerkleRoot;

  constructor(
    address payoutAddress
  ) ERC1155("") {
    // payment
    _payoutAddress = payable(payoutAddress);
    // start sales paused
    _pause();
  }

  // region Pass Configuration

  function addPass(
    uint256 tokenId,
    uint128 mintPrice,
    uint96 maxSupply,
    uint32 walletMintLimit,
    string calldata metadataUri,
    uint256 teamReserve
  )
  external
  onlyOwner
  {
    require(tokens[tokenId].maxSupply == 0, "Token already exists");
    require(maxSupply > 0, "Supply must be > 0");
    require(maxSupply >= teamReserve, "Max supply must be >= team reserve");

    tokens[tokenId] = Pass(mintPrice, maxSupply, walletMintLimit, metadataUri);

    if (teamReserve > 0) {
      mintInternal(msg.sender, tokenId, teamReserve);
    }

    // required as per ERC1155 standard
    emit URI(metadataUri, tokenId);
  }

  function editPass(
    uint256 tokenId,
    uint128 mintPrice,
    uint96 maxSupply,
    uint32 walletMintLimit,
    string calldata metadataUri
  )
  external
  onlyOwner
  whenTokenValid(tokenId)
  whenNotFrozen(tokenId)
  {
    require(maxSupply > 0, "Supply must be > 0");
    require(maxSupply >= totalSupply(tokenId), "Max supply must be >= existing supply");

    tokens[tokenId] = Pass(mintPrice, maxSupply, walletMintLimit, metadataUri);

    // required as per ERC1155 standard
    emit URI(metadataUri, tokenId);
  }

  function setPassWalletMintLimit(uint256 tokenId, uint32 walletMintLimit)
  external
  onlyOwner
  whenTokenValid(tokenId)
  whenNotFrozen(tokenId)
  {
    tokens[tokenId].walletMintLimit = walletMintLimit;
  }

  function setPassMetadataUri(uint256 tokenId, string calldata metadataUri)
  external
  onlyOwner
  whenTokenValid(tokenId)
  whenNotFrozen(tokenId)
  {
    tokens[tokenId].metadataUri = metadataUri;

    // required as per ERC1155 standard
    emit URI(metadataUri, tokenId);
  }

  function freezeMetadata(uint256 tokenId)
  external
  onlyOwner
  whenTokenValid(tokenId)
  {
    frozenTokens[tokenId] = true;
    emit PermanentURI(tokens[tokenId].metadataUri, tokenId);
  }

  function uri(uint256 tokenId)
  public
  view
  override
  whenTokenValid(tokenId)
  returns (string memory)
  {
    if (bytes(tokens[tokenId].metadataUri).length > 0) {
      return tokens[tokenId].metadataUri;
    } else {
      return "";
    }
  }

  // endregion

  // region Sale

  function saleState() external view returns (uint256 state) {
    if (paused()) {
      // paused
      return 0;
    } else if (currentMerkleRoot != 0) {
      // reserved
      return 1;
    } else {
      // public
      return 2;
    }
  }

  function startPublicSale(uint256 tokenId)
  external
  onlyOwner
  whenPaused
  whenTokenValid(tokenId)
  {
    tokenIdForSale = tokenId;
    currentMerkleRoot = 0;
    _unpause();
  }

  function startReservedSale(uint256 tokenId, bytes32 merkleRoot)
  external
  onlyOwner
  whenPaused
  whenTokenValid(tokenId)
  {
    tokenIdForSale = tokenId;
    currentMerkleRoot = merkleRoot;
    _unpause();
  }

  function pauseSale() external onlyOwner whenNotPaused {
    _pause();
  }

  function mintSale(uint256 amount, bytes32[] calldata proof) external payable whenNotPaused {
    // Reserved validation
    if (currentMerkleRoot != 0) {
      require(verify(createLeaf(msg.sender), proof), "Invalid merkle proof");
    }

    // require to mint at least one
    require(amount > 0, "Amount must be > 0");

    Pass storage pass = tokens[tokenIdForSale];

    // require enough supply
    require(totalSupply(tokenIdForSale) + amount <= pass.maxSupply, "Over supply");

    // enforce per wallet mint limit (0 == no limit)
    if (pass.walletMintLimit > 0) {
      require(minted[tokenIdForSale][msg.sender] + amount <= pass.walletMintLimit, "Over wallet mint limit");
    }

    // require exact payment
    require(msg.value == amount * pass.mintPrice, "Wrong ETH amount");

    mintInternal(msg.sender, tokenIdForSale, amount);

    // finish sale automatically
    if (totalSupply(tokenIdForSale) == pass.maxSupply) {
      _pause();
    }
  }

  function mintOwner(uint256 tokenId, uint256 amount) external onlyOwner {
    require(totalSupply(tokenId) + amount <= tokens[tokenId].maxSupply, "Over supply");
    mintInternal(msg.sender, tokenId, amount);
  }

  function mintInternal(address to, uint256 tokenId, uint256 amount) internal {
    _mint(to, tokenId, amount, "");
    minted[tokenId][to] = minted[tokenId][to] + amount;
  }

  function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    currentMerkleRoot = merkleRoot;
  }

  function verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
    return MerkleProof.verify(proof, currentMerkleRoot, leaf);
  }

  function createLeaf(address account) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(account));
  }

  // endregion

  // region Payment

  receive() external payable {}

  function withdraw() external onlyOwner {
    Address.sendValue(_payoutAddress, address(this).balance);
  }

  function setPayoutAddress(address payoutAddress) external onlyOwner {
    _payoutAddress = payable(payoutAddress);
  }

  // endregion

  // region Default Overrides

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  // endregion

  // region modifiers

  modifier whenTokenValid(uint256 tokenId) {
    require(tokens[tokenId].maxSupply > 0, "Invalid token");
    _;
  }

  modifier whenNotFrozen(uint256 tokenId) {
    require(!frozenTokens[tokenId], "Configuration is frozen");
    _;
  }

  // endregion
}

/* Contract by loltapes.eth
          _       _ _
    ____ | |     | | |
   / __ \| | ___ | | |_ __ _ _ __   ___  ___
  / / _` | |/ _ \| | __/ _` | '_ \ / _ \/ __|
 | | (_| | | (_) | | || (_| | |_) |  __/\__ \
  \ \__,_|_|\___/|_|\__\__,_| .__/ \___||___/
   \____/                   | |
                            |_|
*/
