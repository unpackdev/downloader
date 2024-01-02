/** 
   (                  )     (               (     
   )\     (   (    ( /( (   )\ )  (     (   )\ )  
 (((_)   ))\  )(   )\()))\ (()/(  )\   ))\ (()/(  
 )\___  /((_)(()\ (_))/((_) /(_))((_) /((_) ((_)) 
((/ __|(_))   ((_)| |_  (_)(_) _| (_)(_))   _| |  
 | (__ / -_) | '_||  _| | | |  _| | |/ -_)/ _` |  
  \___|\___| |_|   \__| |_| |_|   |_|\___|\__,_|

Web: https://certifiedprotocol.net/

TG: https://t.me/Certified_Portal

Twitter (X): https://twitter.com/certified__eth

**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CertifiedMsg {
    IERC20 private _CFDContract;
    address private _owner;
    
    mapping (address => uint128) public msgCount;    
    uint128 public freeMsgNum = 1;
    uint256 public msgCFDPrice = 10 * 10**9;

    event Message(address indexed from, address indexed to, string message);
    event Certify(address indexed from, address indexed to, string message);

    constructor() {
        _owner = msg.sender;
        _CFDContract = IERC20(address(0));
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function sendMessage(address to, string calldata message) external {
        if(msg.sender == _owner || _CFDContract == IERC20(address(0))){
            emit Message(msg.sender, to, message);
        }
        else{
            if(_CFDContract.balanceOf(msg.sender) < msgCFDPrice){
                require(msgCount[msg.sender] < freeMsgNum, "Free messages limit reached");
                msgCount[msg.sender]++;

                emit Message(msg.sender, to, message);
            }
            else{
                _CFDContract.transfer(_owner, msgCFDPrice);
                emit Message(msg.sender, to, message);
            }
        }
    }

    function certify(address to, string calldata message) external {
        emit Certify(msg.sender, to, message);
    }

    function setCFDAddress(address addr) external onlyOwner{
        _CFDContract = IERC20(addr);
    }

    function setFreeMsgNum(uint128 msgNum) external onlyOwner{
        freeMsgNum = msgNum;
    }

    function setMsgCFDPrice(uint256 price) external onlyOwner{
        msgCFDPrice = price;
    }
}