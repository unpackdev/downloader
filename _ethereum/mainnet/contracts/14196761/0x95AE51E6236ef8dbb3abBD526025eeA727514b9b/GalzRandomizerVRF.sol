// SPDX-License-Identifier: MIT

/*
╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋╋╋┏┓
╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋╋╋╋┃┃
┏━━┳┓╋┏┫┗━┳━━┳━┳━━┳━━┫┃┏━━━┓
┃┏━┫┃╋┃┃┏┓┃┃━┫┏┫┏┓┃┏┓┃┃┣━━┃┃
┃┗━┫┗━┛┃┗┛┃┃━┫┃┃┗┛┃┏┓┃┗┫┃━━┫
┗━━┻━┓┏┻━━┻━━┻┛┗━┓┣┛┗┻━┻━━━┛
╋╋╋┏━┛┃╋╋╋╋╋╋╋╋┏━┛┃
╋╋╋┗━━┛╋╋╋╋╋╋╋╋┗━━┛
*/

// CyberGalz Legal Overview [https://cybergalznft.com/legaloverview]

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./VRFConsumerBase.sol";

contract GalzRandomizerVRF is VRFConsumerBase, Ownable {
  using SafeMath for uint256;

	bytes32 internal keyHash;

	uint256 internal fee;
  uint256 vrfvalue;

	uint256[] public randomResults; //keeps track of the random number from chainlink
  uint256[] public myGalzId; //galz shuffled with vrf
	uint256 public totalDraws = 0; //drawID is drawID-1!
	string[] public ipfsProof; //proof list where the list participants is
	mapping(bytes32 => uint256) public requestIdToDrawIndex;

	event IPFSProofAdded(string proof);
	event RandomRequested(bytes32 indexed requestId, address indexed roller);
	event RandomLanded(bytes32 indexed requestId, uint256 indexed result);

  //getRandomNumber()
  //setRandomNumber()
  //shuffle(9999)
  //getMyGalzId(id)

	constructor(
		address _vrfCoordinator,
		address _linkToken,
		bytes32 _keyHash
	) VRFConsumerBase(_vrfCoordinator, _linkToken) {
		keyHash = _keyHash;
		fee = 2000000000000000000;
	}

	//you start by calling this function and having in IPFS the list of participants
	function addContestData(string memory ipfsHash) external onlyOwner {
		ipfsProof.push(ipfsHash);
		emit IPFSProofAdded(ipfsHash);
	}

	/**
	 * Requests randomness
	 */
	function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
		require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in the contract");
		requestId = requestRandomness(keyHash, fee);
		emit RandomRequested(requestId, msg.sender);
		requestIdToDrawIndex[requestId] = totalDraws;
		vrfvalue = uint256(requestId);
	}

  // set random number from chainlink vrf
  function setRandomNumber() external onlyOwner returns (bytes32 requestId) {
		require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in the contract");
		requestId = requestRandomness(keyHash, fee);
		emit RandomRequested(requestId, msg.sender);
		requestIdToDrawIndex[requestId] = totalDraws;
		return requestId;
	}

	/**
	 * Callback function used by VRF Coordinator
	 */
	function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
		randomResults.push(randomness);
		totalDraws++;
		emit RandomLanded(requestId, randomness);
	}

  // shuffle galz's list with amount (ex.shuffle(9999))
  function shuffle(uint256 numberArr) public onlyOwner {
    for (uint256 i = 0; i < numberArr; i++) {
      uint256 n = i + vrfvalue % (numberArr - i) + 1;
      myGalzId[i] = n;
    }
  }

  // get my galz's id
  function getTokenId(uint256 _id) public view returns(uint256 result){
    return myGalzId[_id];
  }

	//------ other things --------
	function withdrawLink() external onlyOwner {
		LINK.transfer(owner(), LINK.balanceOf(address(this)));
	}
}