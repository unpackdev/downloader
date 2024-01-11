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
  bytes32 private solution4;
  bytes32 private solution5;
  uint private price = 0.01 ether;
  uint private seedPrice = 0.1 ether;
  bool private gameClosed = false;
  uint public numEntries = 0;
  address public winner;

  event Win(string message);
  event Loss(string message);

  mapping(address => uint) public participants;

  //deploy with solutions, set 3 day time limit [16 hours for testing]
  constructor(bytes32 _solution1, bytes32 _solution2, bytes32 _solution3, bytes32 _solution4, bytes32 _solution5) {
      solution1 = _solution1;
      solution2 = _solution2;
      solution3 = _solution3;
      solution4 = _solution4;
      solution5 = _solution5;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  //Accept 3 guesses + compare to solutions
  function entry(string memory answer1, string memory answer2, string memory answer3, string memory answer4, string memory answer5) external payable callerIsUser
  {
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
    bytes32 answer4Hash = sha256(abi.encodePacked((answer4)));
    bytes32 answer5Hash = sha256(abi.encodePacked((answer5)));

    if (answer1Hash == solution1 && answer2Hash == solution2 && answer3Hash == solution3 && answer4Hash == solution4 && answer5Hash == solution5) {
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

  //Seed prize pool initially
  function addInitialBalance() external payable {
    require(
        msg.value >= seedPrice,
        "initial seeding too low"
    );
  }

  //For testing
  function manualGameOpen() external onlyOwner {
    gameClosed = false;
  }
}
