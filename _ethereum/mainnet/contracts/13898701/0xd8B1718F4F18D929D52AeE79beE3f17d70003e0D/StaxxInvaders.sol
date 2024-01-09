// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

import "./LibAppStorage.sol";

//    _____ __                     ____                     __
//   / ___// /_____ __  ___  __   /  _/___ _   ______ _____/ /__  __________
//   \__ \/ __/ __ `/ |/_/ |/_/   / // __ \ | / / __ `/ __  / _ \/ ___/ ___/
//  ___/ / /_/ /_/ />  <_>  <   _/ // / / / |/ / /_/ / /_/ /  __/ /  (__  )
// /____/\__/\__,_/_/|_/_/|_|  /___/_/ /_/|___/\__,_/\__,_/\___/_/  /____/
//
// The minting contract for Staxx Invaders.
//
// The contract provides two paths for minting.
//   1) through an access list (merkle proof) with a free reward allocation
//   2) through the public sale
//
// The access list will go live before the public sale to give existing holders of STAXX a chance
// to mint early.
contract StaxxInvaders is Initializable, ERC721Upgradeable, ERC721PausableUpgradeable, OwnableUpgradeable {
  using MerkleProofUpgradeable for bytes32[];
  using LibAppStorage for LibAppStorage.AppStorage;

  /// The price each pass will sell for.
  uint256 public constant price = 0.03 ether;

  // The root hash of the merkle proof used to validate the minting order and image details.
  bytes32 public constant provenanceHash = 0xbc09e38d70d0b6508dd2d7bb5d8a491467f497122c35618eb87c0f5e6510e056;
  string public constant provenanceUri = "ipfs://QmWZsoopdqzuxka5npPE9oEwnDqSH7tFpUza5sPPA8QbNs";

  /// Events.
  event TokensClaimed(address sender, uint256 claimed, uint256 amount, uint256 free);
  event ContractInit(bytes32 hash, string name);
  event WithdrawBalance(address caller, uint256 amount);

  event ErrorHandled(string reason);

  struct Args {
    bytes32 rootHash;
    string uri;
    string name;
    string symbol;
    uint40 launchDate;
  }

  /// Initialisation function that serves as a constructor for the upgradeable contract.
  function init(Args memory args_) external initializer {
    __ERC721_init(args_.name, args_.symbol);
    __Ownable_init();
    LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

    // Default: 2021-12-03 08:00:00.0Z
    s.publicLaunchDate = args_.launchDate;
    s.rootHash = args_.rootHash;
    s.baseUrl = args_.uri;

    emit ContractInit(s.rootHash, name());
  }

  /// Fallback to be able to receive ETH payments (just in case!)
  receive() external payable {}

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return LibAppStorage.getTokenUri(tokenId);
  }

  /// Minting method for people on the access list that can mint before the public sale and
  /// potentially with a reward of free passes.
  ///
  /// The merkle proof is for the combination of the senders address and number of allocated passes.
  /// These values are encoded to a fixed length padding to help prevent attacking the hash.
  ///
  /// The minter will only pay for any passes they mint beyond those allocated to them. They can
  /// mint as many times as they like, and with as many tokens at a time as they would like. We
  /// track the number of claimed tokens to prevent double dipping.
  function mintWithAllocation(
    uint16 count,
    uint16 allocated,
    bytes32[] calldata proof
  ) external payable {
    LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
    s.ensureEnoughSupply(count);

    address sender = _msgSender();
    bytes32 leaf = keccak256(abi.encode(sender, allocated));

    require(proof.verify(s.rootHash, leaf), "Mint: could not verify merkle proof");

    uint256 claiming = s.claimedByAddress[_msgSender()];
    uint256 remaining = (claiming < allocated) ? allocated - claiming : 0;

    uint256 paid = remaining > count ? 0 : count - remaining;
    emit TokensClaimed(sender, claiming, count, paid);

    uint256 cost = paid * price;
    require(msg.value >= cost, "Insufficient funds");

    s.claimedByAddress[sender] += (count - paid);

    _safeMintTokens(count);

    if (msg.value > cost) {
      uint256 refund = msg.value - cost;
      (bool success, ) = payable(sender).call{value: refund}("");
      require(success, "Failed to refund additional value");
    }
  }

  /// Perform a regular mint with no limit on passes per transaction. All passes are charged at full
  /// price.
  function mint(uint16 count) external payable {
    LibAppStorage.appStorage().ensureSaleLive();
    uint256 cost = count * price;
    require(msg.value >= cost, "Insufficient funds");

    _safeMintTokens(count);

    if (msg.value > cost) {
      uint256 refund = msg.value - cost;
      (bool success, ) = payable(msg.sender).call{value: refund}("");
      require(success, "Failed to refund additional value");
    }
  }

  function _safeMintTokens(uint16 count) internal {
    LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
    s.ensureEnoughSupply(count);
    for (uint16 i = 0; i < count; i++) {
      uint256 id = s.nextTokenId();
      _safeMint(msg.sender, id);
    }
  }

  /// Pauses the contract to prevent further sales.
  function pause() external virtual onlyOwner {
    _pause();
  }

  /// Unpauses the contract to allow sales to continue.
  function unpause() external virtual onlyOwner {
    _unpause();
  }

  function total() external pure returns (uint256) {
    return LibAppStorage.TOTAL;
  }

  function totalSupply() external view returns (uint256) {
    return LibAppStorage.appStorage().totalSupply();
  }

  /// Returns the number of free passes claimed by a given wallet.
  function claimed(address addr) external view returns (uint256) {
    return LibAppStorage.appStorage().claimedByAddress[addr];
  }

  /// Returns the number of free passes claimed by the caller.
  function claimedByMe() external view returns (uint256) {
    return LibAppStorage.appStorage().claimedByAddress[msg.sender];
  }

  /// Returns the root hash of the merkle tree proof used to validate the access list.
  function rootHash() external view returns (bytes32) {
    return LibAppStorage.appStorage().rootHash;
  }

  /// Returns the timestamp of the public sale start time.
  function publicLaunch() external view returns (uint256) {
    return LibAppStorage.appStorage().publicLaunchDate;
  }

  /// Lets us set an updated launch date.
  function setPublicLaunch(uint32 publicLaunch_) external onlyOwner {
    LibAppStorage.appStorage().publicLaunchDate = publicLaunch_;
  }

  /// Updates the root hash of the merkle proof.
  function setRootHash(bytes32 rootHash_) external onlyOwner {
    LibAppStorage.appStorage().rootHash = rootHash_;
  }

  /// Updates the metadata URI.
  function setURI(string calldata baseURI) external onlyOwner {
    LibAppStorage.appStorage().baseUrl = baseURI;
  }

  /// Transfers the funds out of the contract to the owners wallet.
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
    emit WithdrawBalance(msg.sender, balance);
  }

  /// DANGER: Here be dragons!
  function destroy() external onlyOwner {
    selfdestruct(payable(msg.sender));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 id
  ) internal virtual override(ERC721Upgradeable, ERC721PausableUpgradeable) {
    super._beforeTokenTransfer(from, to, id);
  }
}
