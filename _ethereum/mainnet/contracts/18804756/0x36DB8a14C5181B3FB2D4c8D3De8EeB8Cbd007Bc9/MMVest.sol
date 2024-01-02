// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address) 
    {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) 
    {
        return msg.data;
    }
}



interface IERC20 
{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private 
    {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract  MMVest is Ownable 
{
    struct Vesting {
        address beneficiary;
        uint256 vestedAmount;
        uint256 releasePeriod;
        uint256 releaseAmountPerPeriod;
        uint256 lastRelease;
    }

    using SafeMath for uint256; 
    mapping(uint256 => Vesting) private _vestings;

    IERC20 lumiToken;
    uint256 public id;
    IERC20 public token;
    uint256 totalVestedAmount = 0;

    constructor(address _tokenAddress)
    {    
         id = 0;
         token = IERC20(_tokenAddress); 
    }


    function isBeneficiary(address addr) public view returns(uint256)
    {
        uint256 count = 0;
        for(uint256 i=0; i<id; i++)
        {
            if(addr==_vestings[i].beneficiary)
            {
                count++;
            }
        }
        return count;
    }


    event BeneficiaryAdded(uint256 id, address beneficiary, uint256 vestedAmount, uint256 releasePeriod, uint256 releaseAmountPerPeriod);
    function addBeneficiary(address beneficiary, uint256 vestedAmount, uint256 releasePeriod, uint256 releaseAmountPerPeriod) public onlyOwner 
    {
        require(beneficiary != address(0), "Cannot Vest for Zero Wallet");
        require(vestedAmount>0, "Total Amount Cannot be Zero");
        require(releasePeriod>0, "Release Period Cannot be Zero");
        require(releaseAmountPerPeriod>0, "Release Amount Per Period Cannot be Zero");
        totalVestedAmount = totalVestedAmount+vestedAmount;
        uint256 lastRelease = block.timestamp; 
        _vestings[id] = Vesting(beneficiary, vestedAmount, releasePeriod, releaseAmountPerPeriod, lastRelease);
        emit BeneficiaryAdded(id, beneficiary, vestedAmount, releasePeriod, releaseAmountPerPeriod);
        id++;
    }



    function getBeneficiaryDetail(uint256 _id) public view returns(Vesting memory)
    {
        return _vestings[_id];
    }


    function myVestingIds(address _address) public view returns(uint256[] memory)
    {
        uint256 count = isBeneficiary(_address);
        uint256[] memory ids = new uint256[](count);
        uint256 j = 0;
        for(uint256 i=0; i<id; i++)
        {
            if(_address==_vestings[i].beneficiary)
            {
                ids[j++] = i;
            }
        }
        return ids;
    }



    event VestingReleased(uint256 id, address beneficiary, uint256 amountReleased,  uint256 timestamp);
    function releaseVesting(uint256 _id) public  
    {   
        Vesting memory vesting = _vestings[_id];
        address beneficiary = vesting.beneficiary;
        require(msg.sender==beneficiary, "You are not beneficiary");
        uint256 span = block.timestamp-vesting.lastRelease;
        uint256 periods =  span/vesting.releasePeriod;
        uint256 amountToBeReleased = periods*vesting.releaseAmountPerPeriod;
        if(amountToBeReleased>vesting.vestedAmount)
        {   
            amountToBeReleased = vesting.vestedAmount;
        }
        require(amountToBeReleased>0, "You have not vested amount remaing");
        vesting.lastRelease = block.timestamp;
        vesting.vestedAmount = vesting.vestedAmount-amountToBeReleased;
        _vestings[_id] = vesting;
        token.transfer(beneficiary, amountToBeReleased);
        totalVestedAmount = totalVestedAmount-amountToBeReleased;
        emit VestingReleased(_id, beneficiary, amountToBeReleased,  block.timestamp);
        
    }
}