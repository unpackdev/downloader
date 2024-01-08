// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "./ERC20.sol";
import "./Ownable.sol";

contract Controlled is Ownable{

    constructor() public {
       setExclude(msg.sender);
    }

    // Flag that determines if the token is transferable or not.
    bool public transferEnabled = true;

    // flag that makes locked address effect
    bool lockFlag=true;
    mapping(address => bool) public locked;
    mapping(address => uint) public lockedAmount;

    mapping(address => bool) public exclude;

    function enableTransfer(bool _enable) public onlyOwner{
        transferEnabled=_enable;
    }

    function disableLock(bool _enable) public onlyOwner returns (bool success){
        lockFlag=_enable;
        return true;
    }
    function addLock(address _addr, uint _amount) public onlyOwner returns (bool success){
        require(_addr!=msg.sender);
        locked[_addr]=true;
        lockedAmount[_addr] = _amount;
        return true;
    }

    function setExclude(address _addr) public onlyOwner returns (bool success){
        exclude[_addr]=true;
        return true;
    }

    function removeLock(address _addr) public onlyOwner returns (bool success){
        locked[_addr]=false;
        lockedAmount[_addr]=0;
        return true;
    }
  
}

contract PandaToken is ERC20,Controlled {

    constructor() ERC20("PANDA", "PANDA") Controlled() Ownable() public {
        _mint(msg.sender, 10000000000000000000000000000);
    }

    function transfer(address recipient, uint256 amount) public virtual override transferAllowed(msg.sender,amount) returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override transferAllowed(sender,amount) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    modifier transferAllowed(address sender, uint256 amount) {
        if (!exclude[sender]) {
            require(transferEnabled,'transfer enabled is false');
            if(lockFlag){
                require(!locked[sender] || super.balanceOf(sender).sub(amount) >= lockedAmount[sender],'sender is locked');
            }
        }
        
        _;
    }
}