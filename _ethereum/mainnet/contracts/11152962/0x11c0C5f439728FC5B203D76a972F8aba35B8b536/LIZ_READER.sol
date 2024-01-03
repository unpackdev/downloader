pragma solidity ^0.5.16;

interface ISTAKE {
    function stakeOf(address account) external view returns (uint);
    function totalStake() external view returns (uint);
}

interface IVIP {
    function powerStakeOf(address account) external view returns (uint);
    function totalPowerStake() external view returns (uint);
    function currentUserCount() external view returns (uint32);
    function userList(uint32 i) external view returns (address);
    function vipPower(address account) external view returns (uint);
}

interface IOVIP {
    function vipPowerMap(address account) external view returns (uint);
    function vipBuyPool() external view returns (uint);
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

contract LIZ_READER is Ownable{
    ISTAKE public stakeContract;
    IVIP public vipContract;
    IOVIP public oldVipContract;

    uint constant private vipExtraStakeRate = 10 ether;

    function setStakeContract(ISTAKE _target)onlyOwner public {
        stakeContract = _target;
    }

    function setVipContract(IVIP _target)onlyOwner public {
        vipContract = _target;
    }

    function setOldVipContract(IOVIP _target)onlyOwner public {
        oldVipContract = _target;
    }

    function powerOf(address _addr) public view returns (uint) {
        uint power  = vipContract.vipPower(_addr);
        return stakeContract.stakeOf(_addr) + vipContract.powerStakeOf(_addr) + stakeContract.stakeOf(_addr)*power/10;
    }


    function totalPower() public view returns (uint) {
        return stakeContract.totalStake() + vipContract.totalPowerStake() + vipExtStakes();

    }

    function vipExtStakes() public view returns (uint) {
        uint vipAdd = 0;
        for(uint32 i = 0;i<=vipContract.currentUserCount();i++){
            address addr  = vipContract.userList(i);
            uint power  = vipContract.vipPower(addr);
            vipAdd = vipAdd + stakeContract.stakeOf(addr)*power/10;
        }
        return vipAdd;
    }
    // not used
    function vipStakes() public view returns (uint) {
        uint vipAdd = 0;
        for(uint8 i = 0;i<=vipContract.currentUserCount();i++){
            address addr  = vipContract.userList(i);
            vipAdd = vipAdd + stakeContract.stakeOf(addr);
        }
        return vipAdd;
    }



    function powerOfT(address _addr) public view returns (uint) {
        return stakeContract.stakeOf(_addr) + vipContract.powerStakeOf(_addr) + oldVipContract.vipPowerMap(_addr)*vipExtraStakeRate;
    }


    function totalPowerT() public view returns (uint) {
        return stakeContract.totalStake() + vipContract.totalPowerStake() + oldVipContract.vipBuyPool()*10;

    }

}