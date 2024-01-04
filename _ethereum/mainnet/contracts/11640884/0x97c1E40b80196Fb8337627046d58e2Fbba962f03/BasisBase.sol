pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./UseChiToken.sol";
import "./SafeOwnable.sol";
import "./UserInfo.sol";
import "./IBasisTreasury.sol";

interface IOperator{
     function operator() external returns (address); 
}
 //BAC--->BAB
contract BasisBase is SafeOwnable {
    using SafeMath for uint256;
 
    //constant
    uint256 constant PERCENT = 10000;
    uint256 constant HOUSE_RATE = 100; // 1% fee taken by the house
    //constant
    address public cash;
    address public bond;
    address public basisTreasury;
    address public rewardAddr; 
    address public robotCenter;
    //user
    address[] private users;
    mapping(address => uint256) private offers;
    //parmas
    uint256 public MIN_BALANCE = 1e18;
    //event
    event OnSetOffer(address indexed user, uint256 offer);  

    //if basis Treasury update
    function updateTreasury() external onlyOwner{  
        basisTreasury = IOperator(cash).operator();
    }

    //changeRewardAddr
    function setRewardAddr(address _addr) external onlyOwner{ 
        rewardAddr = _addr;
    }

    //setRobotCenter
    function setRobotCenter(address _bot) external onlyOwner{ 
        robotCenter = _bot;
    }

    modifier onlyBotCenter(){
        require(msg.sender == robotCenter,"!bot");
        _;
    }

    function isNewUser(address user) private returns(bool){
         for(uint256 i= 0; i < users.length; i++){
             if(user == users[i]){
                 return false;
             }
         }
         return true;
    }

    //setOffer
    function setOffer(uint256 _newOffer) external {
        require(_newOffer <= PERCENT, "Offer exceeds 100%.");
        require(_newOffer >= 200, "Minimum offer is 2%.");
        uint256 oldOffer = offers[msg.sender];
        if (_newOffer < oldOffer) { 
            uint256 nextEpochStartTIme = IBasisTreasury(basisTreasury).nextEpochPoint();
            uint256 timeUntilNextEpoch = nextEpochStartTIme.sub(block.timestamp);
            require(timeUntilNextEpoch > 15 minutes, "You cannot reduce your offer within 15 minutes of the next epoch");
        }        
        offers[msg.sender] = _newOffer; 
        //add new user to user list  
        if(isNewUser(msg.sender) == true){
            users.push(msg.sender);
        }        
        emit OnSetOffer(msg.sender, _newOffer);
    }

    //getOffer
    function getOffer(address _user) public view returns (uint256) {
        uint256 offer = offers[_user];
        return offer < 200 ? 200 : offer;
    }

    //thisBalance
    function thisBalance(address token) public view returns(uint256){
        return IERC20(token).balanceOf(address(this));
    }

    //private _getUserInfos
    function getUserInfos(address tokenIn) internal view returns (UserInfo[] memory) { 
        uint256 count  = users.length;
        UserInfo[] memory infos = new UserInfo[](count);
        for(uint256 i= 0; i < count; i++){
            address user = users[i];
            uint256 balance = IERC20(tokenIn).balanceOf(user);
            uint256 approved = IERC20(tokenIn).allowance(user,address(this));
            infos[i].user = user;
            infos[i].balance = balance;
            infos[i].approved = approved;
            infos[i].offer = offers[user];         
        } 
        return infos;
    }

} 