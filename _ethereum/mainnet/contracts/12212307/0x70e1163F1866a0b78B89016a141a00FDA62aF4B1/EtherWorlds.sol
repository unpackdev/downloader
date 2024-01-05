// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract EtherWorlds is ERC721, Ownable {
  using Counters for Counters.Counter;

  string public constant md5_win86 = "7f0e66b532c247f3851f690662a02d4c";
  string public constant md5_win64 = "b28c3797224ec93ea6c3e604342737e6";
  string public constant md5_portable = "91498913be6a22fd8b5571231ad19b47";
  
  uint256 public constant SALE_START_TIMESTAMP = 1618070400;
  uint256 public constant CONTEST_SIGNUP_END_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 3);
  uint256 public constant CONTEST_END_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 7);
  uint256 public constant REWARD_RELEASE_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 14);
  uint256 public constant SALE_NFT_SUPPLY = 3072;
  uint256 public constant CONTEST_NFT_SUPPLY = 32;
  uint256 public constant CONTEST_MAX_PARTICIPANTS = 256;
  uint256 public constant ALL_NFT_SUPPLY = SALE_NFT_SUPPLY + CONTEST_NFT_SUPPLY;

  mapping (address => bool) public mintedNft;
  address[] public contestParticipants;
  Counters.Counter public contestNftMinted;
  mapping (address => bool) public claimedReward;
  Counters.Counter public rewardsClaimedByLastPlaceOwners;

  Counters.Counter[] public contestTokens;
  // Index increased by 1 due to the default value of '0' in mapping [ address -> uint ]
  mapping (address => uint) public contestShiftedIndexOf;

  constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
    _setBaseURI(baseURI);
  }

  function saleStarted() public view returns (bool) {
    return block.timestamp >= SALE_START_TIMESTAMP;
  }
  function contestSignUpEnded() public view returns (bool) {
    return block.timestamp >= CONTEST_SIGNUP_END_TIMESTAMP;
  }
  function contestEnded() public view returns (bool) {
    return block.timestamp >= CONTEST_END_TIMESTAMP;
  }
  function rewardsReleased() public view returns (bool) {
    return block.timestamp >= REWARD_RELEASE_TIMESTAMP;
  }

  function totalSold() public view returns (uint256) {
    return totalSupply() - contestNftMinted.current();
  }

  function getMaxAmountToMint() public view returns (uint256) {
    uint256 currentSupply = totalSold();

    if (currentSupply >= 320) {
      return 32;
    } 
    else if (currentSupply >= 64) {
      return 16;
    } 
    else {
      return 1;
    }
  }

  function getPrice() public view returns (uint256) {
    uint currentSupply = totalSold();

    if (currentSupply >= 3008) {
      return 5000000000000000000; // 3009 - 3072 5 ETH
    } else if (currentSupply >= 2880) {
      return 1000000000000000000; // 2881 - 3008 1 ETH
    } else if (currentSupply >= 2368) {
      return 800000000000000000; // 2369  - 2880 0.8 ETH
    } else if (currentSupply >= 1344) {
      return 500000000000000000; // 1345 - 2368 0.5 ETH
    } else if (currentSupply >= 832) {
      return 300000000000000000; // 833 - 1344 0.3 ETH
    } else if (currentSupply >= 320) {
      return 200000000000000000; // 321 - 832 0.2 ETH
    } else if (currentSupply >= 64) {
      return 100000000000000000; // 65 - 320 0.1 ETH
    } else {
      return 20000000000000000; // 0 - 64 0.02 ETH 
    }
  }

  function mint(uint256 numberOfNft) public payable {
    require(saleStarted(), "Sale has not started yet.");
    require(totalSold() < SALE_NFT_SUPPLY, "Sale has already ended.");
    require(numberOfNft > 0, "Cannot mint less than 1.");
    require(numberOfNft <= getMaxAmountToMint(), "Minting as many NFTs is not permitted.");
    require(SafeMath.add(totalSold(), numberOfNft) <= SALE_NFT_SUPPLY, "Cannot mint as many NFTs as it would exceed the maximum supply.");
    require(SafeMath.mul(getPrice(), numberOfNft) <= msg.value, "Not enough Ether.");

    for (uint i = 0; i < numberOfNft; i++) {
      _safeMint(msg.sender, _generateSeed(false));
    }

    mintedNft[msg.sender] = true;
  }

  function contestBalanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "Balance query for the zero address.");

    uint index = contestShiftedIndexOf[owner];
    require(index > 0, "You are not signed up.");

    return contestTokens[index - 1].current();
  }

  function signUp() public {
    require(mintedNft[msg.sender], "Only NFT minters may participate.");
    require(contestShiftedIndexOf[msg.sender] == 0, "You are already signed in.");
    require(!contestSignUpEnded(), "Sign up period has ended.");
    require(contestParticipants.length < CONTEST_MAX_PARTICIPANTS, "There is already a maximum number of participants.");

    contestTokens.push(Counters.Counter(balanceOf(msg.sender)));
    contestShiftedIndexOf[msg.sender] = contestTokens.length;
    contestParticipants.push(msg.sender);
  }

  function getNumberOfParticipants() public view returns (uint256) {
    return contestParticipants.length;
  }

  function getPlaceOf(address owner) public view returns (uint _place, uint _howManyWithSamePlace) {
    uint ownerBalance = contestBalanceOf(owner);
    uint length = contestTokens.length;
    uint place = 0;
    uint lastMax = ALL_NFT_SUPPLY;

    for (uint i = 0; i < length; i++) {
      uint currentMax = 0;
      uint currentMaxDuplicates = 0;

      for (uint j = 0; j < length; j++) {
        uint currentValue = contestTokens[j].current();
        if (currentValue == currentMax) {
          currentMaxDuplicates++;
        }
        if (currentValue > currentMax && currentValue < lastMax) {
          currentMax = currentValue;
          currentMaxDuplicates = 0;
        }
      }

      place++;

      if (ownerBalance == currentMax) {
        return (place, currentMaxDuplicates + 1);
      }

      lastMax = currentMax;
      place += currentMaxDuplicates;
    }

    return (place, 0);
  }

  function claimReward() public {
    require(contestEnded(), "It is not permitted to claim the reward yet.");
    require(SafeMath.add(contestNftMinted.current(), 1) <= CONTEST_NFT_SUPPLY, "Cannot mint as many NFTs as it would exceed the maximum supply.");

    if (!rewardsReleased()) {
      (uint place, uint howManyOwners) = getPlaceOf(msg.sender);

      require(place <= CONTEST_NFT_SUPPLY, "You are not permitted to claim the reward.");
      require(!claimedReward[msg.sender], "You already claimed the reward.");

      bool isLastPlace = place + howManyOwners > CONTEST_NFT_SUPPLY;

      if (isLastPlace) {
        require(rewardsClaimedByLastPlaceOwners.current() <= CONTEST_NFT_SUPPLY - place, "Rewards for last qualified place are already claimed :c");
      }

      claimedReward[msg.sender] = true;
      if (isLastPlace) {
        rewardsClaimedByLastPlaceOwners.increment();
      }
    }

    _safeMint(msg.sender, _generateSeed(true));
    contestNftMinted.increment();
  }

  function withdraw() onlyOwner public {
    uint balance = address(this).balance;
    msg.sender.transfer(balance);
  }

  function setBaseURI(string memory baseURI) onlyOwner public {
    _setBaseURI(baseURI);
  }

  function _generateSeed(bool isReward) private view returns (uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(msg.sender, totalSupply(), block.timestamp)));
    seed = seed - seed % 10;
    seed += isReward ? 1 : 0;
    return seed;
  }

  function _beforeTokenTransfer(address from, address to, uint256) internal override {
    if (!contestEnded()) {
      uint fromShiftedIndex = contestShiftedIndexOf[from];
      uint toShiftedIndex = contestShiftedIndexOf[to];
      if (from != address(0) && fromShiftedIndex > 0) {
        contestTokens[fromShiftedIndex - 1].decrement();
      }
      if (to != address(0) && toShiftedIndex > 0) {
        contestTokens[toShiftedIndex - 1].increment();
      }
    }
  }

  function renounceOwnership() public view override onlyOwner {
    revert("Action not permitted.");
  }
  function transferOwnership(address) public view override onlyOwner {
    revert("Action not permitted.");
  }
}
