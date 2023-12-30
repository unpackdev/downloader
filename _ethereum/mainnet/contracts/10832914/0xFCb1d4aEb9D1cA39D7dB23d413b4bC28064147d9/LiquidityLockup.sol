pragma solidity ^0.6.0;

interface IERC20Transfer {
    function transfer(address recipient, uint256 amount) external returns (bool);
}



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}




contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = 0x6166760a83bEF57958394ec2eEd00845b4Cf5a08;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract LiquidityLockup is Ownable {
    using SafeMath for uint256;
    
    uint256 public unlockTime = 1607558400;  // Thursday, 10-Dec-20 00:00:00 UTC

    constructor () public { }
    
    function withdraw(address _contract, address _recipient, uint256 _amount) external onlyOwner {
        require(now > unlockTime);
        IERC20Transfer(_contract).transfer(_recipient, _amount);
    }

    function extendLockTime(uint256 _time) external onlyOwner {
        unlockTime = unlockTime.add(_time);
    }
}