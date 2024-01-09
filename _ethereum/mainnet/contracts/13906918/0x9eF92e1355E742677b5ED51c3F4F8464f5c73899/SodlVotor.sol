pragma solidity ^0.8.4;

//SPDX-License-Identifier: Unlicense

import "./ECDSA.sol";
import "./SignatureChecker.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./SODLDAO.sol";

contract SodlVotor is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  address public immutable token;
  address public teamShareAddress;
  EnumerableSet.AddressSet private listedTokens;
  EnumerableSet.AddressSet private votingTokens;
  mapping(string => uint256) private txHashVotedMap;
  mapping(address => uint256) private tokenVotedCountMap;
  mapping(address => uint256) private tokenSodlAmountMap;

  event Voted(
    address account,
    uint256 sodlAmount,
    address tokenAddress,
    uint256 tokenAmount,
    string txHash
  );

  event TokenListed(address tokenAddress, uint256 tokenSODLAmount);

  constructor(
    address token_,
    address teamShareAddress_,
    address[] memory listedTokens_
  ) {
    token = token_;
    teamShareAddress = teamShareAddress_;
    for (uint256 index = 0; index < listedTokens_.length; index++) {
      listedTokens.add(listedTokens_[index]);
    }
  }

  function updateTeamShareAddress(address newAddress) public onlyOwner {
    teamShareAddress = newAddress;
  }

  using ECDSA for bytes32;

  function tokenSodlAmount(address tokenAddress) public view returns (uint256) {
    return tokenSodlAmountMap[tokenAddress];
  }

  function tokenVotedCount(address tokenAddress) public view returns (uint256) {
    return tokenVotedCountMap[tokenAddress];
  }

  function getVotingTokens() public view returns (address[] memory) {
    return votingTokens.values();
  }

  function getListedTokens() public view returns (address[] memory) {
    return listedTokens.values();
  }

  function isVoted(string memory txHash) public view returns (bool) {
    return txHashVotedMap[txHash] != 0;
  }

  function vote(
    string memory txHash,
    address[] memory tokenAddresses,
    uint256[] memory tokenAmounts,
    uint256 sodlAmount,
    uint256 blockNumber,
    bytes memory signature
  ) public {
    require(sodlAmount > 0, "Invalid SODL amount");
    uint256 balance = SODLDAO(token).balanceOf(msg.sender);
    require(balance > sodlAmount, "Insufficient balance");
    require(txHashVotedMap[txHash] == 0, "Tx voted already");
    require(block.number < blockNumber, "Invalid blockNumber");
    require(
      tokenAddresses.length == tokenAmounts.length,
      "Invalid token amount"
    );
    require(tokenAddresses.length > 0, "Invalid address amount");

    // check if vote token is already supported
    for (uint256 i = 0; i < tokenAddresses.length; i++) {
      require(
        !listedTokens.contains(tokenAddresses[i]),
        "Token already supported"
      );
    }

    bytes32 message = keccak256(
      abi.encodePacked(
        txHash,
        tokenAddresses,
        tokenAmounts,
        sodlAmount,
        blockNumber,
        msg.sender
      )
    );

    address signer = message.toEthSignedMessageHash().recover(signature);
    require(signer == owner(), "Invalid signature");

    require(
      SODLDAO(token).transferFrom(msg.sender, address(this), sodlAmount),
      "Transfer failed"
    );

    txHashVotedMap[txHash] = txHashVotedMap[txHash] + sodlAmount;

    // update token voted count
    for (uint256 i = 0; i < tokenAddresses.length; i++) {
      tokenVotedCountMap[tokenAddresses[i]] =
        tokenVotedCountMap[tokenAddresses[i]] +
        tokenAmounts[i];

      tokenSodlAmountMap[tokenAddresses[i]] =
        tokenSodlAmountMap[tokenAddresses[i]] +
        sodlAmount;

      if (!votingTokens.contains(tokenAddresses[i])) {
        votingTokens.add(tokenAddresses[i]);
      }

      emit Voted(
        msg.sender,
        sodlAmount,
        tokenAddresses[i],
        tokenAmounts[i],
        txHash
      );
    }
  }

  // the top.1 token to listedTokens
  // remove it from votingTokens
  // transfer it's voting $SODL to owner
  function triggerVoteTarget() public onlyOwner {
    uint256 maxAmount = 0;
    address maxTokenAddress;
    address[] memory votingTokenAddresses = votingTokens.values();

    require(votingTokenAddresses.length > 0, "No token to be listed");

    for (uint256 index = 0; index < votingTokenAddresses.length; index++) {
      if (tokenSodlAmountMap[votingTokenAddresses[index]] > maxAmount) {
        maxAmount = tokenSodlAmountMap[votingTokenAddresses[index]];
        maxTokenAddress = votingTokenAddresses[index];
      }
    }

    require(maxAmount > 0, "No token to be listed");

    SODLDAO(token).transfer(teamShareAddress, maxAmount);
    votingTokens.remove(maxTokenAddress);
    listedTokens.add(maxTokenAddress);
    emit TokenListed(maxTokenAddress, maxAmount);
  }
}
