pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol"; 


import "./IRNG.sol";
import "./IRNGrequestor.sol";
import "./recovery.sol";


contract random is VRFConsumerBase, Ownable, recovery  {
    

    mapping(bytes32=>uint256)   public responses;
    mapping(bytes32=>bool)      public responded;
    mapping(bytes32=>address)   public callbacks;
    bytes32[]                   public requestIDs; 

    bytes32                     public keyHash;
    uint256                     public fee;

    mapping(address => bool)    authorised;
    mapping(address => bool)    admins;

    modifier onlyAuth {
        require(authorised[msg.sender],"Not Authorised");
        _;
    }
    modifier onlyAdmins {
        require(admins[msg.sender],"Not an admin.");
        _;
    }

    event Request(bytes32 RequestID);
    event RandomReceived(bytes32 requestId, uint256 randomNumber);
    event AuthChanged(address user,bool auth);
    event AdminChanged(address user,bool auth);

    constructor(address VRFCoordinator, address LinkToken,address _owner)
       VRFConsumerBase(VRFCoordinator, LinkToken)
    {
        uint256 id;
        assembly {
            id := chainid()
        }
        if (id == 4) {
            keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
            fee = 1e17; // 0.1 LINK
        } else if (id == 1) {
            keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
            fee = 2e18;
        } else {
            require(false,"Invalid Chain");
        }
        authorised[_owner] =true;
        authorised[msg.sender] =true;
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
       require(
           LINK.balanceOf(address(this)) >= fee,
           "Not enough LINK - fill contract with faucet"
       );
       bytes32 requestId = requestRandomness(keyHash, fee);
       requestIDs.push(requestId);
       emit Request(requestId);
       return requestId;
    }

    function requestRandomNumberWithCallback( ) public onlyAuth returns (bytes32) {
       require(
           LINK.balanceOf(address(this)) >= fee,
           "Not enough LINK - fill contract with faucet"
       );
       bytes32 requestId = requestRandomness(keyHash, fee);
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


    function fulfillRandomness(bytes32 requestId, uint256 _randomNumber)
       internal
       override
    {
        responses[requestId] = _randomNumber;
        responded[requestId] = true;
        if (callbacks[requestId]!= address(0)) {
            IRNGrequestor(callbacks[requestId]).process(_randomNumber, requestId);
        }
        emit RandomReceived(requestId, _randomNumber);
    }

}