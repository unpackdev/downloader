pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./IERC20.sol";
import "./Ownable.sol";

contract LockDGCL is Ownable {
    address ERC20Address;

    constructor(address erc20Addr) public {
        ERC20Address = erc20Addr;
    }

    struct LockInfo{
        uint Timestamp;
        address Receiver;
        uint256 Amount;
    }

    uint internal lockCounter = 0;
    uint internal stage = 0;

    mapping(uint => LockInfo) public unlockMapping; //uint is timestamp uin256 is amount


    function unlockToken() public  {
        require(stage <= 2, "Only 3 scheduled token unlock dates.");
        require(block.timestamp >= unlockMapping[stage].Timestamp , "Can't release until the token unlock date.");
        IERC20 erc20 = IERC20(ERC20Address);
        erc20.transfer(unlockMapping[stage].Receiver,unlockMapping[stage].Amount);
        stage+=1;
    }
    function setUnlockInfo(uint timestamp, uint256 amount, address receiver) onlyOwner public{
        require(lockCounter <= 2 , 'lockCounter must be lower than 2');
        unlockMapping[lockCounter].Timestamp = timestamp;
        unlockMapping[lockCounter].Receiver = receiver;
        unlockMapping[lockCounter].Amount = amount;
        lockCounter += 1;
    }

}
