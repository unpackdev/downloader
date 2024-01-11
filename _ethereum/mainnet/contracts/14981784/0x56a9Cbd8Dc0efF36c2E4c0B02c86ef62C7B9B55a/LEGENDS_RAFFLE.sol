// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.6;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
// import "./console.sol";

interface IERC721 {
    function mint(address to, uint amount) external;
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}

// Simpler implementation
contract LEGENDS_RAFFLE is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;


  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
  // MAINNET IS 0x27

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
  // MAINNET IS 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  // uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;
  uint public mint_index = 0;
  uint public genesisTokens = 8000;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  // uint32 numWords =  2;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  uint64 public s_subscriptionId;
  address public s_owner;
  address public mintingContract;
  address public genesisContract;

  constructor() VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
  }

  function setSubscriptionId(uint64 _s_subscriptionId) public onlyOwner {
    s_subscriptionId = _s_subscriptionId;
  }

  function setMintingContract(address mintingContract_) public onlyOwner {
    mintingContract = mintingContract_;
  }

  function setGenesisContract(address genesisContract_) public onlyOwner {
    genesisContract = genesisContract_;
  }

  function setGenesisTokens(uint genesisTokens_) public onlyOwner {
    genesisTokens = genesisTokens_;
  }

  function setVRFCoordinator(address coord) public onlyOwner {
    vrfCoordinator = coord;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords(uint32 _numWords, uint32 _callbackGasLimit) external onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      _callbackGasLimit,
      _numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    for (uint i = 0; i < randomWords.length; i++) {
      s_randomWords.push(randomWords[i] % genesisTokens);
    }
  }

  // get all words
  function words() public view returns (uint256[] memory) {
    uint256[] memory words_ = new uint256[](s_randomWords.length);

    for (uint256 idx = 0; idx < s_randomWords.length; idx++) {
      words_[idx] = s_randomWords[idx];
    }
    return words_;
  }


  function identifyFirstDupe(uint startIdx, uint endIdx) public view returns (uint) {
    require(endIdx > startIdx, "End index must be greater than start end");
    require(s_randomWords.length >= endIdx, "End index cannot exceed random words length");
    
    for (uint256 idx = startIdx; idx < endIdx; idx++) {
      for (uint256 jdx = idx; jdx < endIdx; jdx++) {
        if (idx == jdx) {
          continue;
        }
        uint word1 = s_randomWords[idx];
        uint word2 = s_randomWords[jdx];
        if (word1 == word2) {
          return idx;
        }
      }
    }

    return 0;
  }

  function dedupWords(uint startIdx, uint endIdx) public onlyOwner {
    require(endIdx > startIdx, "End index must be greater than start end");
    require(s_randomWords.length >= endIdx, "End index cannot exceed random words length");

    for (uint256 idx = startIdx; idx < endIdx; idx++) {
      for (uint256 jdx = idx; jdx < endIdx; jdx++) {
        if (idx == jdx) {
          continue;
        }
        uint word1 = s_randomWords[idx];
        uint word2 = s_randomWords[jdx];
        if (word1 == word2) {
          s_randomWords[jdx] = (word2 + 1) % genesisTokens;
        }
      }
    }
  }

  function genesisOwnerOf(uint tokenId) public view returns (address) {
    address owner = IERC721(genesisContract).ownerOf(tokenId);
    return owner;
  }

  // minting function
  // mint index
  function mintRaffleWinners(uint32 numToMint) public onlyOwner {
    require(s_randomWords.length >= numToMint + mint_index, "Not enough words");
    require(genesisContract != address(0), "Must set genesis contract");
    require(mintingContract != 0x0000000000000000000000000000000000000000, "Need to set minting contract");
    for (uint idx = mint_index; idx < numToMint + mint_index; idx++) {
        uint tokenId = s_randomWords[idx];
        address owner = IERC721(genesisContract).ownerOf(tokenId);

        IERC721(mintingContract).mint(owner, 1);
    }
    mint_index = numToMint + mint_index;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}
