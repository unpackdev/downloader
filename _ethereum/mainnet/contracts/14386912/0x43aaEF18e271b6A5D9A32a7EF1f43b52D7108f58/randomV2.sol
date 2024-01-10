// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./recovery.sol";
import "./IRNGrequestor.sol";




// subscription ID on Rinkeby = 634

contract RandomV2 is VRFConsumerBaseV2, Ownable {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // Rinkeby LINK token contract. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address link;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  //bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
  bytes32[] keys;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 2000000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  2;

  uint256[] public s_randomWords;
  bytes32   public s_requestId;


  constructor(uint64 subscriptionId, address _vrfCoordinator)  VRFConsumerBaseV2(_vrfCoordinator)  {
        uint256 id;
        assembly {
            id := chainid()
        }
        if (id == 4) {
            keys = [
              bytes32(0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc)
            ];
            require(_vrfCoordinator == 0x6168499c0cFfCaCD319c818142124B7A15E857ab,"Incorrect VRF Coordinator for Rinkeby");
            link           = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

        } else if (id == 1) {
            link           = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
            require(_vrfCoordinator == 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,"Incorrect VRF Coordinator for MAINNET");
            keys           = [
                bytes32(0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef),
                bytes32(0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92),
                bytes32(0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805)
            ];

        } else {
            require(false,"Invalid Chain");
        }
    
   
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);

    s_subscriptionId = subscriptionId;
  }

  function fulfillRandomWords(
    uint256 requestId, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
    bytes32 _requestId = bytes32(requestId);
    // - from V1
    uint256 _randomNumber = randomWords[0];
    responses[_requestId] = _randomNumber;
    responded[_requestId] = true;
    if (callbacks[_requestId]!= address(0)) {
        IRNGrequestor(callbacks[_requestId]).process(_randomNumber, _requestId);
    }
    emit RandomReceived(_requestId, _randomNumber);

  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords(uint32 numberOfWords, uint speed) external onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = _requestRandomWords(numberOfWords, speed);
  }

  function _requestRandomWords(uint32 numberOfWords, uint speed) internal returns (bytes32){
    require(speed < keys.length,"Invalid speed");
    bytes32 keyHash = keys[speed];
    return bytes32(COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numberOfWords
    ));
  }


  // from original random

    mapping(bytes32=>uint256)   public responses;
    mapping(bytes32=>bool)      public responded;
    mapping(bytes32=>address)   public callbacks;
    bytes32[]                   public requestIDs; 

  
    event Request(bytes32 RequestID);
    event RandomReceived(bytes32 requestId, uint256 randomNumber);
    event AuthChanged(address user,bool auth);
    event AdminChanged(address user,bool auth);


    mapping(address => bool)    authorised;
    mapping(address => bool)    admins;

    modifier onlyAuth {
        require(authorised[msg.sender],"Not Authorised");
        _;
    }
    modifier onlyAdmins {
        require(admins[msg.sender] || msg.sender == owner(),"Not an admin.");
        _;
    }

    function setAuth(address user, bool auth) public onlyAdmins {
        authorised[user] = auth;
        emit AuthChanged(user,auth);
    }

    function setAdmin(address user, bool auth) public onlyAdmins {
        admins[user] = auth;
        emit AdminChanged(user,auth);
    }



    function requestRandomNumber( ) public onlyAuth returns (bytes32) {
       bytes32 requestId = _requestRandomWords(1, 0);
       requestIDs.push(requestId);
       emit Request(requestId);
       return requestId;
    }

      function requestRandomNumberWithCallback( ) public onlyAuth returns (bytes32) {
       bytes32 requestId = _requestRandomWords(1, 0);
       requestIDs.push(requestId);
       callbacks[requestId] = msg.sender;
       emit Request(requestId);
       return requestId;
    }

    function isRequestComplete(bytes32 requestId) external view returns (bool isCompleted) {
        return responded[requestId];
    } 

    function randomNumber(bytes32 requestId) external view returns (uint256 randomNum) {
        require(this.isRequestComplete(requestId), "Not ready");
        return responses[requestId];
    }

 
}
