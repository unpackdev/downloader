pragma solidity ^0.6.0;

// SPDX-License-Identifier: UNLICENSED
// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
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

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

contract PreSale is Owned {
    
    using SafeMath for uint256;

    uint256 saleStartDate = 1611327600; // 22 January 2021, 3 pm GMT
    uint256 saleEndDate = 1612069200; // 31 January 2021, 5 am GMT
    uint256 tokenRatePerEth = 3200; // 3200 tokens per ether
    uint256 public totalInvestments;
    
    uint256 HARD_CAP = 600 ether;
    address beneficiaryAddress1 = 0x1Ed589022D5A8d090638f6E1492769855c5dC4f0;
    address beneficiaryAddress2 = 0x64E620Bb431c15CaAfCC3c60F606dA7Ef929d166;
    
    struct Investor{
        uint256 investment;
        uint256 tokens;
    }
    mapping(address => Investor) public investor;

    modifier isHardCapReached{
        require(totalInvestments.add(msg.value) <= HARD_CAP, "Exceeding the hard cap");
        _;
    }
    
    constructor() public {
        owner = 0xbB2935C4AcBb6B0C7a93c45890557CF1DdfE6908;
    }
    
    receive() external payable{
        Invest();
    }
    
    function Invest() public payable isHardCapReached{
        require( now > saleStartDate && now < saleEndDate , "Sale is closed");
        uint256 tokens = getTokenAmount(msg.value);
        investor[msg.sender].investment += msg.value;
        investor[msg.sender].tokens += tokens;
        totalInvestments += msg.value;
        uint256 eachBeneficiaryAmount = (msg.value).div(2);
        payable(beneficiaryAddress1).transfer(eachBeneficiaryAmount);
        payable(beneficiaryAddress2).transfer(eachBeneficiaryAmount);
    }

    function getTokenAmount(uint256 amount) internal view returns(uint256){
        return amount * tokenRatePerEth;
    }
}