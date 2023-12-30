/**
*/

pragma solidity 0.5.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract Token{
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


/**
 * @title token token initial distribution
 *
 * @dev Distribute purchasers, airdrop, reserve, and founder tokens
 */
contract mybatch is Owned {
  using SafeMath for uint256;
  Token public token;
  
  event Airdropped(address _tokenContractAdd, address _recipient, uint256 _tokens);

  /**
    * @dev perform a transfer of allocations
    * @param _recipient is a list of recipients
    * @param _tokens is list of tokens to sent to recipients
    */
  function airdropTokens(address _tokenContractAdd, address[] memory _recipient, uint256[] memory _tokens) public onlyOwner{
    token = Token(_tokenContractAdd);
    for(uint256 i = 0; i< _recipient.length; i++)
    {
          require(token.transferFrom(msg.sender, _recipient[i], _tokens[i]));
          emit Airdropped(_tokenContractAdd, _recipient[i], _tokens[i]);
    }
  }
}