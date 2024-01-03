pragma solidity ^0.6.0;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

contract Bog is Context {
    address internal _liqLpStakerContract;

    constructor (address liqLpStakerContract) internal {
       _liqLpStakerContract = liqLpStakerContract;
    }
    
    modifier onlyLiqLpStaker() {
        require(_msgSender() == _liqLpStakerContract, "RewardOwner: caller is not the LiqLpStaker contract");
        _;
    }
}

abstract contract FogContract {
    function balanceOf(address account) external view virtual returns (uint256);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
}


contract FoggyBog is Bog {
    using SafeMath for uint256;

    FogContract private _fogContract;     // Fog contract
    

    constructor (FogContract fogContract, address liqLpStakerContract) Bog(liqLpStakerContract) public {
        _fogContract = fogContract;
       
    }
    
    function LiqLpStakerContract() external view returns (address) {
        return _liqLpStakerContract;
    }
    
    function getFogBalance() external view returns (uint256) {
        return _fogContract.balanceOf(address(this));
    }
    
    function giveFogReward(address recipient, uint256 amount) external onlyLiqLpStaker returns (bool) {
        return _fogContract.transfer(recipient, amount);
    }
    
}