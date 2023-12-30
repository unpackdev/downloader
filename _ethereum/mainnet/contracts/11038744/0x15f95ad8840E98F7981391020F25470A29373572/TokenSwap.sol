// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

/**
 * @title ERC20 interface
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function burn(uint256 amount) external view returns (uint256);
    function burnFrom(address account, uint256 amount) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title The TokenSwap contract.
 */
contract TokenSwap is Ownable {
    
    using SafeMath for uint;

    uint256 public startTime;
    uint256 public startPrice = 1000;

    uint256 public increasePercent = 5;
    uint256 public increaseInterval = 1 days;
    
    address BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    address tokenFrom;
    address tokenTo;

    constructor(address _tokenFrom, address _tokenTo) public {
        startTime = block.timestamp;
        tokenFrom = _tokenFrom;
        tokenTo = _tokenTo;
    }

    function swap(uint256 amountTokenFrom) public {
        require(amountTokenFrom >= 1000 ether, "Min amount: 1000");
        uint256 amountTokenTo = willReceive(amountTokenFrom);
        require(amountTokenTo <= IERC20(tokenTo).balanceOf(address(this)), "Insufficient tokens left");

        IERC20(tokenFrom).transferFrom(msg.sender, address(this), amountTokenFrom);

        IERC20(tokenTo).transfer(msg.sender, amountTokenTo);
    }

    function end() public onlyOwner {
        IERC20(tokenTo).transfer(BURN_ADDRESS, IERC20(tokenTo).balanceOf(address(this)));
        IERC20(tokenFrom).burn(IERC20(tokenFrom).balanceOf(address(this)));
    }

    function getBuyPrice() public view returns(uint256) {
        return startPrice.add(startPrice.mul(increasePercent).mul(block.timestamp.sub(startTime)).div(100).div(increaseInterval));
    }

    function willReceive(uint256 _amount) public view returns(uint256) {
        return _amount.div(getBuyPrice());
    }
}