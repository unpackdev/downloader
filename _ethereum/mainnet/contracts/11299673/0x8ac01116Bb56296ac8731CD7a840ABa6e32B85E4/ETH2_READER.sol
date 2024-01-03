pragma solidity ^0.5.16;

interface ISTAKE {
    function stakeOf(address account) external view returns (uint);
    function totalStake() external view returns (uint);
}
interface IPROFIESTAKE {
    function pureStakeOf(address account) external view returns (uint);
    function totalStake() external view returns (uint);
}

interface IPOWER {
    function powerOf(address account) external view returns (uint);
    function currentUserCount() external view returns (uint32);
    function userList(uint32 i) external view returns (address);
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ETH2_READER is Ownable{
    IPROFIESTAKE public fixedStakeContract;
    ISTAKE public floatStakeContract;
    IPOWER public powerContract;

    function setFixed(IPROFIESTAKE _target)onlyOwner public {
        fixedStakeContract = _target;
    }

    function setFloat(ISTAKE _target)onlyOwner public {
        floatStakeContract = _target;
    }

    function setPower(IPOWER _target)onlyOwner public {
        powerContract = _target;
    }

    function powerOf(address _addr) public view returns (uint) {
        uint sum = 0;
        uint p = powerContract.powerOf(_addr);
        sum = sum + fixedStakeContract.pureStakeOf(_addr) * 1000 / 1 ether;
        sum = sum + floatStakeContract.stakeOf(_addr) * 100 / 1 ether;
        sum = sum * (10+p)/10;
        return sum;
    }

    function totalPower() public view returns (uint) {
        uint sum = 0;
        sum = sum + fixedStakeContract.totalStake() * 1000 / 1 ether;
        sum = sum + floatStakeContract.totalStake() *100 / 1 ether;

        uint count = powerContract.currentUserCount();
        for(uint32 i = 0;i<count;i++){
            address addr = powerContract.userList(i);
            uint p = powerContract.powerOf(addr);
            uint pSum = fixedStakeContract.pureStakeOf(addr) * 1000 / 1 ether;
            pSum = pSum + floatStakeContract.stakeOf(addr) * 100 / 1 ether;
            sum = sum + pSum * p /10;
        }
        return sum;
    }

}