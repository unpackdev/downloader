pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";

/*
 * @title Random Block Selector Contract
 * @notice This contract exists to fetch verified random numbers which are then passed into a
 * pre-shared off-chain script to map them too the pre-shared domain/use-case.
 */

contract RandomBlockSelector  is VRFConsumerBaseV2, Ownable {
    // Chainlink Parameters
    VRFCoordinatorV2Interface internal COORDINATOR;
    LinkTokenInterface internal LINKTOKEN;

    uint64 internal s_subscriptionId = 123; // mainnet
    address internal vrfCoordinator =
    0x271682DEB8C4E0901D1a1550aD2e64D568E69909;  // mainnet
    address internal link = 0x514910771AF9Ca656af840dff83E8264EcF986CA; // mainnet
    bytes32 internal keyHash =
    0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; // mainnet

//    uint64 internal s_subscriptionId = 4316; // rinkeby
//    address internal vrfCoordinator =
//    0x6168499c0cFfCaCD319c818142124B7A15E857ab; // rinkeby
//    bytes32 internal keyHash =
//    0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;  // rinkeby
//    address internal link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // rinkeby

    uint32 internal callbackGasLimit = 2000000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    string public initialPythonScriptSha256 = "57348aad1375fca6e8de1a99fd219396111b4d3b26f8ac8263335af8a12f8993";

    uint256[] public allRandomNumbers;
    mapping(uint => uint) public blockToRandomNumber;

    event RandomNumberGenerated(uint randomNumber, uint256 chainlinkRequestId);

    constructor(
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() public onlyOwner returns (uint256 requestID) {
        requestID = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    // callback function called by chainlink
    function fulfillRandomWords(uint256 requestID, uint256[] memory randomWords)
    internal
    override
    {
        require(blockToRandomNumber[block.number] == 0, "already fetched random for this block");
        blockToRandomNumber[block.number] = randomWords[0];
        emit RandomNumberGenerated(randomWords[0], requestID);
        allRandomNumbers.push(randomWords[0]);
    }
}
