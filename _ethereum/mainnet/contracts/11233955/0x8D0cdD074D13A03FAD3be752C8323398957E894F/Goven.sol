pragma solidity ^0.6.6;

contract Goven {
    using SafeMath for uint;

    address public ballsToken;
    address public ballsReward;
    address public router;
    address public owner;
    
    uint public relayTime = 10;
    

    constructor (address _ballsToken,address _router,address _ballsReward) public {
        ballsToken = _ballsToken;
        router = _router;
        ballsReward = _ballsReward;
        owner = msg.sender;
    }
    
    mapping(uint => FunTime) public funMapTime;
    
    struct FunTime{
        uint startTime;
        bool changeState;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    function setRelayTime(uint _relayTime ) public onlyOwner {
        relayTime = _relayTime;  
    }
    
    function setGovenOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    function viewTimeLimit(uint _typeId) public view returns(uint) {
        if(funMapTime[_typeId].startTime > 0){
            return block.timestamp.sub(funMapTime[_typeId].startTime);
        }
    }
  
    function updateStateLimit(uint _typeId) internal returns(bool){
        if(!funMapTime[_typeId].changeState && funMapTime[_typeId].startTime == 0){
            funMapTime[_typeId].startTime = block.timestamp;
            funMapTime[_typeId].changeState=true;
            return false;
        }
        require(block.timestamp.sub(funMapTime[_typeId].startTime) > relayTime,' relay time limit ');
        funMapTime[_typeId].changeState = false;
        funMapTime[_typeId].startTime = 0;
        return true;
    }

    function addPool(uint256 _allocPoint, address _lpToken) public onlyOwner {
        if(!updateStateLimit(1)){
            return;
        }
        IBallsReward(ballsReward).add(_allocPoint,_lpToken);
    }
    
    function setPool(address _lpToken,uint _allocPoint) public onlyOwner {
        if(!updateStateLimit(2)){
            return;
        }
        IBallsReward(ballsReward).set(_lpToken,_allocPoint);
    }
    function setBallsRewardOwner(address _newBallsRewardOwner) public onlyOwner {
        if(!updateStateLimit(3)){
            return;
        }
        IBallsReward(ballsReward).setOwner(_newBallsRewardOwner);
    }
    function setBallsRewardDevAddr(address _newDevAddr) public onlyOwner {
        if(!updateStateLimit(4)){
            return;
        }
        IBallsReward(ballsReward).setDevAddr(_newDevAddr);
    }
    function setBallsRewardRouter(address _newRouter) public onlyOwner{
        if(!updateStateLimit(5)){
            return;
        }
        IBallsReward(ballsReward).setRouter(_newRouter);
    }
    function setBallsTokenNewOnwer(address _newBallsTokenOwner) public onlyOwner {
        if(!updateStateLimit(6)){
            return;
        }
        IBallsReward(ballsReward).setBallsTokenNewOnwer(_newBallsTokenOwner);
    }
    function setRouterOwner(address _newRouterOwner) public onlyOwner {
        if(!updateStateLimit(7)){
            return;
        }
        IRouter(router).setNewOwner(_newRouterOwner);
    }
    function setRouterRewardAddress(address _newRouterRewardAddress) public onlyOwner {
        if(!updateStateLimit(8)){
            return;
        }
        IRouter(router).setRewardAddress(_newRouterRewardAddress);
    }
    
}

library SafeMath {
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
}
interface IRouter{
    function setNewOwner(address) external;
    function setRewardAddress(address) external;
}

interface IBallsReward {
    function add(uint256 _allocPoint, address _lpToken) external;
    function set(address _pair, uint256 _allocPoint) external;
    function setOwner(address) external;
    function setDevAddr(address) external;
    function setBallsTokenNewOnwer(address) external;
    function setRouter(address _router) external;
}
interface IBallsToken {
    function transferOwnership(address) external;
}