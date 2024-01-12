// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./CountersUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";

import "./VRFCoordinatorV2Interface.sol";

import "./IBNFTRegistry.sol";
import "./IBNFT.sol";

contract AirdropDistribution is
  Initializable,
  ContextUpgradeable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;

  error OnlyCoordinatorCanFulfill(address have, address want);
  event AirdropCreated(
    uint256 airdropId,
    address nftAsset,
    address airdropTokenAddress,
    uint256 airdropTokenType,
    uint256 claimType
  );
  event AidropERC20Claimed(address user, uint256 airdropId, uint256 nftTokenId, uint256 airdropAmount);
  event AidropERC721Claimed(address user, uint256 airdropId, uint256 nftTokenId, uint256 airdropTokenId);
  event AidropERC1155Claimed(
    address user,
    uint256 airdropId,
    uint256 nftTokenId,
    uint256 airdropTokenId,
    uint256 airdropAmount
  );

  // VRF Coordinator.
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  VRFCoordinatorV2Interface public vrfCoordinator;

  // Your subscription ID.
  uint64 public vrfSubscriptionId;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 public vrfKeyHash;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 public vrfCallbackGasLimit;
  // The default is 3, but you can set this higher.
  uint16 public vrfRequestConfirmations;
  // For this example, retrieve 1 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 public vrfNumWords;

  uint256[] public vrfAllRequestIds;
  // requestId => randomWords
  mapping(uint256 => uint256[]) public vrfAllRandomWords;

  IBNFTRegistry public bnftRegistry;

  /*
  1.one to one airdrop, like the bakc to bayc, number is the same, this kind of airdrop we should input the {address: airdrop}
    mapping to the contract to make them claim the airdrop which belongs to them.
  2.random airdrop, like the Bored Ape Chemistry Club, each of the bayc will get one NFT randomly,
    we would make all of them get the airdrops from those randomly.
  3.if some project make the airdrop not randomly, but like some of the {bayc: 50% chance, mayc: 10% chance}
    then maybe we need to support that too.
  */
  uint256 public constant TOKEN_TYPE_ERC20 = 1;
  uint256 public constant TOKEN_TYPE_ERC721 = 2;
  uint256 public constant TOKEN_TYPE_ERC1155 = 3;

  uint256 public constant CLAIM_TYPE_FIXED_SAME = 1; /* Fixed, same id */
  uint256 public constant CLAIM_TYPE_FIXED_DIFF = 2; /* Fixed, diff id */
  uint256 public constant CLAIM_TYPE_RANDOM = 3;

  // airdrop data
  struct AirdropData {
    uint256 airdropId;
    address nftAsset;
    address bnftProxy;
    address airdropTokenAddress;
    uint256 airdropTokenType; // 1-ERC20, 2-ERC721, 3-ERC1155
    uint256 claimType; // 1-Fixed, 2-Random
    uint256 vrfRequestId;
    address[] nftAllUsers;
    mapping(address => uint256[]) nftUserTokenIds;
    mapping(uint256 => bool) nftTokenClaimeds;
    uint256[] erc1155AirdropTokenIds;
  }

  // airdrop id tracker
  CountersUpgradeable.Counter public airdropIdTracker;
  // airdrop id => airdrop data
  mapping(uint256 => AirdropData) public airdropDatas;
  // nft address => airdrop address => airdrop id
  mapping(address => mapping(address => uint256)) public nftAirdropToIds;
  // vrf request id => airdrop id
  mapping(uint256 => uint256) public vrfReqIdToAirdropIds;

  function initialize(
    address bnftRegistry_,
    address vrfCoordinator_,
    uint64 subscriptionId_
  ) public initializer {
    __Context_init();
    __ReentrancyGuard_init();
    __Ownable_init();
    __ERC721Holder_init();
    __ERC1155Holder_init();

    bnftRegistry = IBNFTRegistry(bnftRegistry_);
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    vrfSubscriptionId = subscriptionId_;
    airdropIdTracker.increment();

    //vrfKeyHash = 0x
    vrfCallbackGasLimit = 100000;
    vrfRequestConfirmations = 3;
    vrfNumWords = 1;
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
    if (_msgSender() != address(vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(_msgSender(), address(vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal {
    vrfAllRandomWords[requestId] = randomWords;
  }

  function configureVRFCoordinator(address vrfCoordinator_, uint64 subscriptionId_) public onlyOwner nonReentrant {
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    vrfSubscriptionId = subscriptionId_;
  }

  function configureVRFParams(
    bytes32 keyHash,
    uint32 gasLimit,
    uint16 confirmations,
    uint32 numWords
  ) public onlyOwner nonReentrant {
    vrfKeyHash = keyHash;
    vrfCallbackGasLimit = gasLimit;
    vrfRequestConfirmations = confirmations;
    vrfNumWords = numWords;
  }

  // create airdrop.
  function createAirdrop(
    address nftAsset,
    address airdropTokenAddress,
    uint256 airdropTokenType,
    uint256 claimType
  ) public onlyOwner nonReentrant returns (uint256) {
    (address bnftProxy, ) = bnftRegistry.getBNFTAddresses(nftAsset);
    require(bnftProxy != address(0), "bnft not exist");

    uint256 airdropId = airdropIdTracker.current();
    airdropIdTracker.increment();

    nftAirdropToIds[nftAsset][airdropTokenAddress] = airdropId;

    AirdropData storage data = airdropDatas[airdropId];
    data.airdropId = airdropId;
    data.nftAsset = nftAsset;
    data.bnftProxy = bnftProxy;
    data.airdropTokenAddress = airdropTokenAddress;
    data.airdropTokenType = airdropTokenType;
    data.claimType = claimType;

    emit AirdropCreated(airdropId, nftAsset, airdropTokenAddress, airdropTokenType, claimType);

    return airdropId;
  }

  function requestVRFRandomWords(uint256 airdropId) public onlyOwner nonReentrant {
    AirdropData storage data = airdropDatas[airdropId];
    require(data.airdropId != 0, "invalid airdrop id");
    require(data.claimType == CLAIM_TYPE_RANDOM, "claim type not random");

    data.vrfRequestId = vrfCoordinator.requestRandomWords(
      vrfKeyHash,
      vrfSubscriptionId,
      vrfRequestConfirmations,
      vrfCallbackGasLimit,
      vrfNumWords
    );

    vrfAllRequestIds.push(data.vrfRequestId);

    vrfReqIdToAirdropIds[data.vrfRequestId] = airdropId;
  }

  function configureNftUserTokenIds(
    uint256 airdropId,
    address[] calldata nftUsers,
    uint256[] calldata nftTokenIds
  ) public onlyOwner nonReentrant {
    require(nftUsers.length == nftTokenIds.length, "inconsistent params");

    AirdropData storage data = airdropDatas[airdropId];
    require(data.airdropId != 0, "invalid airdrop id");

    for (uint256 i = 0; i < nftUsers.length; i++) {
      if (data.nftUserTokenIds[nftUsers[i]].length == 0) {
        data.nftAllUsers.push(nftUsers[i]);
      }
      data.nftUserTokenIds[nftUsers[i]].push(nftTokenIds[i]);
    }
  }

  function clearNftUserTokenIds(uint256 airdropId, address[] calldata nftUsers) public onlyOwner nonReentrant {
    AirdropData storage data = airdropDatas[airdropId];
    require(data.airdropId != 0, "invalid airdrop id");

    for (uint256 i = 0; i < nftUsers.length; i++) {
      delete data.nftUserTokenIds[nftUsers[i]];
    }
  }

  function getNftUserTokenIds(uint256 airdropId, address nftUser) public view returns (uint256[] memory) {
    AirdropData storage data = airdropDatas[airdropId];
    require(data.airdropId != 0, "invalid airdrop id");

    return data.nftUserTokenIds[nftUser];
  }

  function isNftTokenClaimed(uint256 airdropId, uint256 tokenId) public view returns (bool) {
    AirdropData storage data = airdropDatas[airdropId];
    require(data.airdropId != 0, "invalid airdrop id");

    return data.nftTokenClaimeds[tokenId];
  }

  function configureERC1155(uint256 airdropId, uint256[] calldata airdropTokenIds) public onlyOwner nonReentrant {
    AirdropData storage data = airdropDatas[airdropId];
    require(data.airdropId != 0, "invalid airdrop id");
    require(data.airdropTokenType == TOKEN_TYPE_ERC1155, "token type not erc1155");

    data.erc1155AirdropTokenIds = airdropTokenIds;
  }

  function getERC1155Config(uint256 airdropId) public view returns (uint256[] memory, uint256[] memory) {
    AirdropData storage data = airdropDatas[airdropId];
    require(data.airdropId != 0, "invalid airdrop id");

    uint256[] memory erc1155Balances = new uint256[](data.erc1155AirdropTokenIds.length);
    for (uint256 airIdIdx = 0; airIdIdx < data.erc1155AirdropTokenIds.length; airIdIdx++) {
      erc1155Balances[airIdIdx] = IERC1155Upgradeable(data.airdropTokenAddress).balanceOf(
        address(this),
        data.erc1155AirdropTokenIds[airIdIdx]
      );
    }
    return (data.erc1155AirdropTokenIds, erc1155Balances);
  }

  struct ClaimLocalVars {
    uint256 userNftTokenId;
    uint256 airdropTokenId;
    uint256 randomIndex;
    uint256 airdropTokenBalance;
    uint256[] erc1155NonEmptyTokenIds;
    uint256 erc1155NonEmptyIdNum;
    uint256 erc1155TokenIdBalance;
  }

  function claimERC721(uint256 airdropId) public nonReentrant {
    ClaimLocalVars memory vars;

    AirdropData storage data = airdropDatas[airdropId];
    require(data.airdropId != 0, "invalid airdrop id");

    require(data.airdropTokenType == TOKEN_TYPE_ERC721, "invalid token type");
    require(data.nftUserTokenIds[_msgSender()].length > 0, "claim nothing");

    // scan user original nft token ids
    for (uint256 i = 0; i < data.nftUserTokenIds[_msgSender()].length; i++) {
      vars.userNftTokenId = data.nftUserTokenIds[_msgSender()][i];
      require(data.nftTokenClaimeds[vars.userNftTokenId] == false, "nft token claimed");

      // allocate airdrop token to user by diff claim type
      if (data.claimType == CLAIM_TYPE_FIXED_SAME) {
        // simple 1:1, same token id
        vars.airdropTokenId = vars.userNftTokenId;
      } else if (data.claimType == CLAIM_TYPE_RANDOM) {
        uint256 randomWord = _getRandomWord(data);

        // select token id by random number
        vars.airdropTokenBalance = IERC721Upgradeable(data.airdropTokenAddress).balanceOf(address(this));
        vars.randomIndex = _calcRandomIndex(randomWord, vars.airdropTokenBalance);
        vars.airdropTokenId = IERC721EnumerableUpgradeable(data.airdropTokenAddress).tokenOfOwnerByIndex(
          address(this),
          vars.randomIndex
        );
      } else {
        vars.airdropTokenId = type(uint256).max;
        continue;
      }

      // mark orginal nft token has claimed
      data.nftTokenClaimeds[vars.userNftTokenId] = true;

      // transfer airdrop token to user
      IERC721Upgradeable(data.airdropTokenAddress).safeTransferFrom(address(this), _msgSender(), vars.airdropTokenId);

      emit AidropERC721Claimed(_msgSender(), data.airdropId, vars.userNftTokenId, vars.airdropTokenId);
    }
  }

  function claimERC1155(uint256 airdropId) public nonReentrant {
    ClaimLocalVars memory vars;

    AirdropData storage data = airdropDatas[airdropId];
    require(data.airdropId != 0, "invalid airdrop id");

    require(data.airdropTokenType == TOKEN_TYPE_ERC1155, "invalid token type");
    require(data.nftUserTokenIds[_msgSender()].length > 0, "claim nothing");

    // scan user original nft token ids
    vars.erc1155NonEmptyTokenIds = new uint256[](data.erc1155AirdropTokenIds.length);

    for (uint256 nftIdIdx = 0; nftIdIdx < data.nftUserTokenIds[_msgSender()].length; nftIdIdx++) {
      vars.userNftTokenId = data.nftUserTokenIds[_msgSender()][nftIdIdx];
      require(data.nftTokenClaimeds[vars.userNftTokenId] == false, "nft token claimed");

      // allocate airdrop token to user by diff claim type
      if (data.claimType == CLAIM_TYPE_FIXED_SAME) {
        vars.airdropTokenId = vars.erc1155NonEmptyTokenIds[0];
      } else if (data.claimType == CLAIM_TYPE_RANDOM) {
        uint256 randomWord = _getRandomWord(data);

        // purge empty token id
        vars.erc1155NonEmptyIdNum = 0;
        for (uint256 airIdIdx = 0; airIdIdx < data.erc1155AirdropTokenIds.length; airIdIdx++) {
          vars.erc1155TokenIdBalance = IERC1155Upgradeable(data.airdropTokenAddress).balanceOf(
            address(this),
            data.erc1155AirdropTokenIds[airIdIdx]
          );
          if (vars.erc1155TokenIdBalance > 0) {
            vars.erc1155NonEmptyTokenIds[vars.erc1155NonEmptyIdNum] = data.erc1155AirdropTokenIds[airIdIdx];
            vars.erc1155NonEmptyIdNum++;
          }
        }
        require(vars.erc1155NonEmptyIdNum > 0, "erc1155 id empty");

        // select token id by random number
        vars.randomIndex = _calcRandomIndex(randomWord, vars.erc1155NonEmptyIdNum);
        vars.airdropTokenId = vars.erc1155NonEmptyTokenIds[vars.randomIndex];
      } else {
        vars.airdropTokenId = type(uint256).max;
        continue;
      }

      // mark orginal nft token has claimed
      data.nftTokenClaimeds[vars.userNftTokenId] = true;

      // transfer airdrop token to user
      IERC1155Upgradeable(data.airdropTokenAddress).safeTransferFrom(
        address(this),
        _msgSender(),
        vars.airdropTokenId,
        1,
        new bytes(0)
      );

      emit AidropERC1155Claimed(_msgSender(), data.airdropId, vars.userNftTokenId, vars.airdropTokenId, 1);
    }
  }

  function _calcRandomIndex(uint256 vrfRandomWord, uint256 maxIndex) internal view returns (uint256) {
    uint256 randomSeed = uint256(
      keccak256(abi.encodePacked(vrfRandomWord, blockhash(block.number - 1), msg.sender, maxIndex))
    );
    return randomSeed % maxIndex;
  }

  function _getRandomWord(AirdropData storage airdropData) internal view returns (uint256) {
    require(airdropData.vrfRequestId != 0, "zero request id");
    require(vrfAllRandomWords[airdropData.vrfRequestId].length > 0, "zero random words");

    return vrfAllRandomWords[airdropData.vrfRequestId][0];
  }
}
