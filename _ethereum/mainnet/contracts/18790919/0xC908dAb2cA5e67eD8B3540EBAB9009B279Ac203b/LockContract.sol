pragma solidity =0.8.23;

interface IWOM {    
    function transfer(address recipient, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

abstract contract WMS { //Wom Management Standard

    address private _owner;

    event OwnershipTransfer(address indexed newOwner);

    receive() external payable {}

    constructor() {
        _owner = msg.sender;
    }

    //Modifiers ==========================================================================================================================================
    modifier Owner() {
        require(msg.sender == _owner, "OMS: NOT_OWNER");
        _;  
    }

    //Read functions =====================================================================================================================================
    function owner() public view returns (address) {
        return _owner;
    }
 
    //Write functions ====================================================================================================================================
    function setNewOwner(address user) public Owner {
        _owner = user;
        emit OwnershipTransfer(user);
    }

}

contract LockContract is WMS {
    IWOM private immutable WOM = IWOM(0xBd356a39BFf2cAda8E9248532DD879147221Cf76);

    mapping(uint16 /*Lock ID*/ => uint256) _releaseTime;
    mapping(uint16 /*Lock ID*/ => uint256) _lockAmount;

    constructor(address owner) public {
        setNewOwner(owner);
    }

    function getLockInfo(uint16 lockId) external view returns(uint256 releaseTime, uint256 lockAmount) {
        releaseTime = _releaseTime[lockId];
        lockAmount = _lockAmount[lockId];
    }

    function lock(uint16 lockId, uint256 amount, uint256 releaseDate) external Owner {
        require(lockId != 0, "Lock ID 0 is not allowed");
        require(_releaseTime[lockId] == 0, "Lock ID Already Used");
        require(WOM.transferFrom(msg.sender, address(this), amount), "Failed to transfer WOM");

        _releaseTime[lockId] = releaseDate;
        _lockAmount[lockId] = amount;
    }

    function unlock(uint16 lockId, address recipient, uint256 amount) external Owner {
        require(block.timestamp > _releaseTime[lockId], "Lock time hasn't been reached yet");
        require(_lockAmount[lockId] >= amount, "Insufficient lock amount");

        require(WOM.transfer(recipient, amount), "Failed to transfer WOM");

        _lockAmount[lockId] -= amount;
    }

}