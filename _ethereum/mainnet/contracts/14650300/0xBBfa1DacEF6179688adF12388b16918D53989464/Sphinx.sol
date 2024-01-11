// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";

 
// User submits 3 riddles, first person to get them all right wins.
// All verification is done on chain
// Keeps track of number of entries [total and per user]
// Closes 3 days/72hrs after deployment [see timestamp logic]
// Full balance will be withdrawn and 69% sent to the winner
contract Sphinx is Ownable {

  bytes32 private solution1;
  bytes32 private solution2;
  bytes32 private solution3;
  uint private price = 0.01 ether;
  bool private gameClosed = false;
  uint public numEntries = 0;
  uint public timestamp;
  address public winner;

  event Win(string message);
  event Loss(string message);

  mapping(address => uint) public participants;

  //deploy with solutions, set 3 day time limit [16 hours for testing]
  constructor(bytes32 _solution1, bytes32 _solution2, bytes32 _solution3) {
      solution1 = _solution1;
      solution2 = _solution2;
      solution3 = _solution3;
      timestamp = block.timestamp + 262800;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  //Accept 3 guesses + compare to solutions
  function entry(string memory answer1, string memory answer2, string memory answer3) external payable callerIsUser
  {
    require (
        block.timestamp < timestamp, 
        "the game has closed"
    );

    require(
        gameClosed == false,
        "the game has closed"
    );

    require(
        msg.value >= price,
        "entry cost too low"
    );

    bytes32 answer1Hash = sha256(abi.encodePacked((answer1)));
    bytes32 answer2Hash = sha256(abi.encodePacked((answer2)));
    bytes32 answer3Hash = sha256(abi.encodePacked((answer3)));

    if (answer1Hash == solution1 && answer2Hash == solution2 && answer3Hash == solution3) {
        gameClosed = true;
        numEntries++;
        participants[msg.sender] = participants[msg.sender] + 1;
        winner = msg.sender;
        emit Win("Win");
    }
    else {
        numEntries++;
        participants[msg.sender] = participants[msg.sender] + 1;
        emit Loss("Loss");
    }
  }

  //String comparison 
  function compareStrings (bytes32 a, bytes32 b) public pure returns (bool) {
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  //Withdraw entire balance
  function withdrawAll() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  //For testing
  function manualGameOpen() external onlyOwner {
    gameClosed = false;
  }
}
