//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC721.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./MerkleProofIndexed.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract GiveawayContractV2 is VRFConsumerBaseV2, IERC721Receiver {
  struct ERC721Token {
    address contractAddress;
    uint256 tokenId;
    bool claimed;
  }

  ERC721Token[] public nftToDrop;

  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  bytes32 keyHash;

  // A reasonable default is 100000, but this value could be different
  // on other networks.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // Storage parameters
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  uint64 public s_subscriptionId;
  address s_owner;

  // Index of the NFT array from where to start to drop
  uint256 public startIndex;

  bytes32[] merkleRoot;
  uint256[] numberOfParticipants;
  uint256[] numberOfPrizes;

  // Whenever the drop has been succesfully set
  bool public dropSet;

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

  modifier onlyIfNotSet() {
    require(!dropSet, "Drop already set");
    _;
  }

  modifier onlyWithNFT() {
    require(nftToDrop.length > 0, "No NFT to drop");
    _;
  }

  constructor(
    uint64 subscriptionId,
    address vrfCoordinator,
    address link_token_contract,
    bytes32 keyHash_
  ) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link_token_contract);
    keyHash = keyHash_;
    s_subscriptionId = subscriptionId;
    s_owner = msg.sender;
  }

  /// Once the drop is set it automatically starts
  function setupDrop(
    bytes32[] memory merkleRoot_,
    uint256[] memory numberOfParticipants_,
    uint256[] memory numberOfPrizes_
  ) public onlyOwner onlyIfNotSet {
    require(
      merkleRoot_.length == numberOfParticipants_.length &&
        merkleRoot_.length == numberOfPrizes_.length,
      "Invalid drop configuration"
    );
    require(merkleRoot_.length < 5, "To much drops");

    merkleRoot = merkleRoot_;
    numberOfParticipants = numberOfParticipants_;
    numberOfPrizes = numberOfPrizes_;

    dropSet = true;

    s_requestId = getRandomNumber(2);
  }

  /// Send the NFTs you want to drop to the contract
  function addNFT(address contractAddress, uint256[] memory tokenIds)
    public
    onlyOwner
    onlyIfNotSet
  {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      IERC721(contractAddress).safeTransferFrom(IERC721(contractAddress).ownerOf(tokenIds[i]), address(this), tokenIds[i]);
      nftToDrop.push(
        ERC721Token({contractAddress: contractAddress, tokenId: tokenIds[i], claimed: false})
      );
    }
  }

  function adjustLeafIndex(uint256 dropNumber, uint256 index) internal view returns (uint256) {
    uint256 _startIndex = s_randomWords[1] % numberOfParticipants[dropNumber];
    int256 difference = int256(index) - int256(_startIndex);
    uint256 remaining = numberOfParticipants[dropNumber] - _startIndex;

    if (difference >= 0) {
      return uint256(difference);
    } else {
      return remaining + index;
    }
  }

  function adjustNFTIndex(uint256 index) internal view returns (uint256) {
    uint256 _startIndex = s_randomWords[0] % nftToDrop.length;
    if (_startIndex + index >= nftToDrop.length) {
      return (_startIndex + index) % nftToDrop.length;
    } else {
      return _startIndex + index;
    }
  }

  function getPrecDropLength(uint256 dropNumber) public view returns (uint256) {
    uint256 sum = 0;
    for (uint8 i = 0; i < dropNumber; i++) {
      sum = sum + numberOfPrizes[i];
    }

    return sum;
  }

  function claimNFT(
    uint256 dropNumber,
    bytes32[] memory proof,
    bytes32 leaf,
    uint256 leafIndex,
    address receiver
  ) public {
    require(dropNumber < merkleRoot.length, "Invalid drop number");
    require(verifyProof(dropNumber, proof, leaf, leafIndex), "Invalid proof");
    require(keccak256(abi.encodePacked(receiver)) == leaf, "Invalid receiver");
    require(leafIndex < numberOfParticipants[dropNumber], "Invalid leaf index");

    uint256 adjustedLeafIndex = adjustLeafIndex(dropNumber, leafIndex);
    require(adjustedLeafIndex < numberOfPrizes[dropNumber], "No more NFT for this drop");

    uint256 precDropLength = getPrecDropLength(dropNumber);
    uint256 indexToClaim = adjustNFTIndex(adjustedLeafIndex + precDropLength);

    require(nftToDrop[indexToClaim].claimed != true, "Already claimed token");

    nftToDrop[indexToClaim].claimed = true;
    IERC721(nftToDrop[indexToClaim].contractAddress).safeTransferFrom(
      address(this),
      receiver,
      nftToDrop[indexToClaim].tokenId
    );
  }

  /// Start drop
  function getRandomNumber(uint32 numWords) internal returns (uint256 requestId) {
    return
      COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
      );
  }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }

  /// Verifies a merkle proof given a leaf hash, the corresponding leafIndex and the merkle root (saved in the contract)
  function verifyProof(
    uint256 dropNumber,
    bytes32[] memory proof,
    bytes32 leaf,
    uint256 leafIndex
  ) public view returns (bool) {
    return MerkleProofIndexed.verify(proof, merkleRoot[dropNumber], leaf, leafIndex);
  }

  /// @notice Function needed to let the contract being able to receive ERC721 NFTs
  /// @dev Mandatory for IERC721Receiver
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}
