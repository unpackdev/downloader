pragma solidity 0.5.16;

contract Owned {

    address public owner;

    constructor(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'not owner');
        _;
    }

}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
contract IERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }



}

contract ESCROW is Owned {


    uint256 public lockingTimeToTrabsferTokens = 12960000;
    uint256 public contractDeploymentTime; 
    using SafeMath for uint256;

    IERC20 token;
    
    constructor(address _owner) public Owned(_owner) {

    contractDeploymentTime = now;

    }


 function transferAnyERC20Token(IERC20 token, uint tokens) public onlyOwner returns (bool success) {

        require(now > contractDeploymentTime.add(lockingTimeToTrabsferTokens), 'calling before 5 months');
        return token.transfer(owner, tokens);

    }
    
    
    
}