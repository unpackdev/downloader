/**
 *Submitted for verification at Etherscan.io on 2020-09-28
*/

/**
 *Submitted for verification at Etherscan.io on 2018-09-01
*/

pragma solidity 0.5.8; 

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.



contract DistibutionContract3 is Pausable {
    using SafeMath for uint256;

    uint256 constant public decimals = 1 ether;
    address[] public tokenOwners ; /* Tracks distributions mapping (iterable) */
    uint256 public TGEDate = 0; /* Date From where the distribution starts (TGE) */
    uint256 constant public month = 30 days;
    uint256 constant public year = 365 days;
    uint256 public lastDateDistribution = 0;
  
    
    mapping(address => DistributionStep[]) public distributions; /* Distribution object */
    
    ERC20 public erc20;

    struct DistributionStep {
        uint256 amountAllocated;
        uint256 currentAllocated;
        uint256 unlockDay;
        uint256 amountSent;
    }

    constructor() public{
        
        setInitialDistribution(0x2D69BAB9738b05048be16DE3E5E0A945b8EeEf3a, 100000, 1*month);
        setInitialDistribution(0x2D69BAB9738b05048be16DE3E5E0A945b8EeEf3a, 100000, 2*month);
        setInitialDistribution(0x2D69BAB9738b05048be16DE3E5E0A945b8EeEf3a, 100000, 3*month);

        setInitialDistribution(0x01f5547A0651927A363B5c5da0319754B03fFAbD, 100000, 1*month);
        setInitialDistribution(0x01f5547A0651927A363B5c5da0319754B03fFAbD, 100000, 2*month);
        setInitialDistribution(0x01f5547A0651927A363B5c5da0319754B03fFAbD, 100000, 3*month);

        setInitialDistribution(0x468cB54a3821d8b0129C42Ea6ADf12748d97fD98, 100000, 1*month);
        setInitialDistribution(0x468cB54a3821d8b0129C42Ea6ADf12748d97fD98, 100000, 2*month);
        setInitialDistribution(0x468cB54a3821d8b0129C42Ea6ADf12748d97fD98, 100000, 3*month);

        setInitialDistribution(0xB67aB5249429fb9Eaa6360D208C807d8cD1F9A62, 100000, 1*month);
        setInitialDistribution(0xB67aB5249429fb9Eaa6360D208C807d8cD1F9A62, 100000, 2*month);
        setInitialDistribution(0xB67aB5249429fb9Eaa6360D208C807d8cD1F9A62, 100000, 3*month);

        setInitialDistribution(0x4aE0C5D59a627d7A56943bC842826ed4ce3Ec759, 100000, 1*month);
        setInitialDistribution(0x4aE0C5D59a627d7A56943bC842826ed4ce3Ec759, 100000, 2*month);
        setInitialDistribution(0x4aE0C5D59a627d7A56943bC842826ed4ce3Ec759, 100000, 3*month);

        setInitialDistribution(0x6c8E15EC8e35b6ffb246d60AbcA2Ba81d4e247F4, 120000, 1*month);
        setInitialDistribution(0x6c8E15EC8e35b6ffb246d60AbcA2Ba81d4e247F4, 120000, 2*month);
        setInitialDistribution(0x6c8E15EC8e35b6ffb246d60AbcA2Ba81d4e247F4, 120000, 3*month);

        setInitialDistribution(0x89CE23FfC0b0c8E59A49135bb66C4F484Eca97Cc, 120000, 1*month);
        setInitialDistribution(0x89CE23FfC0b0c8E59A49135bb66C4F484Eca97Cc, 120000, 2*month);
        setInitialDistribution(0x89CE23FfC0b0c8E59A49135bb66C4F484Eca97Cc, 120000, 3*month);

        setInitialDistribution(0x860AD5284eeD848967D34f8B30257cc9c5218F4A, 150000, 1*month);
        setInitialDistribution(0x860AD5284eeD848967D34f8B30257cc9c5218F4A, 150000, 2*month);
        setInitialDistribution(0x860AD5284eeD848967D34f8B30257cc9c5218F4A, 150000, 3*month);

        setInitialDistribution(0x3c87E00da8551C73032496Aa60D9BD980510CBAF, 150000, 1*month);
        setInitialDistribution(0x3c87E00da8551C73032496Aa60D9BD980510CBAF, 150000, 2*month);
        setInitialDistribution(0x3c87E00da8551C73032496Aa60D9BD980510CBAF, 150000, 3*month);

        setInitialDistribution(0x5FaE8f9C15eCDd8698297964b17766B763747cE3, 150000, 1*month);
        setInitialDistribution(0x5FaE8f9C15eCDd8698297964b17766B763747cE3, 150000, 2*month);
        setInitialDistribution(0x5FaE8f9C15eCDd8698297964b17766B763747cE3, 150000, 3*month);

        setInitialDistribution(0x6dbF65020E3aF3293e46C49591670f4BAdE9BbcF, 150000, 1*month);
        setInitialDistribution(0x6dbF65020E3aF3293e46C49591670f4BAdE9BbcF, 150000, 2*month);
        setInitialDistribution(0x6dbF65020E3aF3293e46C49591670f4BAdE9BbcF, 150000, 3*month);

        setInitialDistribution(0xc977082e11874a324737ad4273101F07BeD73AC0, 150000, 1*month);
        setInitialDistribution(0xc977082e11874a324737ad4273101F07BeD73AC0, 150000, 2*month);
        setInitialDistribution(0xc977082e11874a324737ad4273101F07BeD73AC0, 150000, 3*month);

        setInitialDistribution(0x9fd50776F133751E8Ae6abE1Be124638Bb917E05, 180000, 1*month);
        setInitialDistribution(0x9fd50776F133751E8Ae6abE1Be124638Bb917E05, 180000, 2*month);
        setInitialDistribution(0x9fd50776F133751E8Ae6abE1Be124638Bb917E05, 180000, 3*month);

        setInitialDistribution(0xc2f2BAF3E68309A85220129412270f9170920dca, 200000, 1*month);
        setInitialDistribution(0xc2f2BAF3E68309A85220129412270f9170920dca, 200000, 2*month);
        setInitialDistribution(0xc2f2BAF3E68309A85220129412270f9170920dca, 200000, 3*month);

        setInitialDistribution(0xf3b387cd539F8D9666817994d058e218E711Cb85, 220000, 1*month);
        setInitialDistribution(0xf3b387cd539F8D9666817994d058e218E711Cb85, 220000, 2*month);
        setInitialDistribution(0xf3b387cd539F8D9666817994d058e218E711Cb85, 220000, 3*month);

        setInitialDistribution(0x9aE61a0c8E345D5b10BE835060433ce95175c9Cb, 230000, 1*month);
        setInitialDistribution(0x9aE61a0c8E345D5b10BE835060433ce95175c9Cb, 230000, 2*month);
        setInitialDistribution(0x9aE61a0c8E345D5b10BE835060433ce95175c9Cb, 230000, 3*month);

        setInitialDistribution(0xA53c1ddC63D9f33994C4A2189EB4F92E36694C5c, 300000, 1*month);
        setInitialDistribution(0xA53c1ddC63D9f33994C4A2189EB4F92E36694C5c, 300000, 2*month);
        setInitialDistribution(0xA53c1ddC63D9f33994C4A2189EB4F92E36694C5c, 300000, 3*month);

        setInitialDistribution(0xb66aCf3F7f93FFF60fE33C14B8CA70c328f3748A, 300000, 1*month);
        setInitialDistribution(0xb66aCf3F7f93FFF60fE33C14B8CA70c328f3748A, 300000, 2*month);
        setInitialDistribution(0xb66aCf3F7f93FFF60fE33C14B8CA70c328f3748A, 300000, 3*month);

        setInitialDistribution(0x17ec047622C000Df03599026A3B39871EC9384DB, 200000, 1*month);
        setInitialDistribution(0x17ec047622C000Df03599026A3B39871EC9384DB, 200000, 2*month);
        setInitialDistribution(0x17ec047622C000Df03599026A3B39871EC9384DB, 200000, 3*month);

        setInitialDistribution(0x8974DFfF914d7De19321342Fd4F611BEeBf02cC3, 200000, 1*month);
        setInitialDistribution(0x8974DFfF914d7De19321342Fd4F611BEeBf02cC3, 200000, 2*month);
        setInitialDistribution(0x8974DFfF914d7De19321342Fd4F611BEeBf02cC3, 200000, 3*month);

        setInitialDistribution(0x12d79502a9015C940043Fd770BE6136947D78238, 150000, 1*month);
        setInitialDistribution(0x12d79502a9015C940043Fd770BE6136947D78238, 150000, 2*month);
        setInitialDistribution(0x12d79502a9015C940043Fd770BE6136947D78238, 150000, 3*month);


    }

    function setTokenAddress(address _tokenAddress) external onlyOwner whenNotPaused  {
        erc20 = ERC20(_tokenAddress);
    }
    
    function safeGuardAllTokens(address _address) external onlyOwner whenPaused  { /* In case of needed urgency for the sake of contract bug */
        require(erc20.transfer(_address, erc20.balanceOf(address(this))));
    }

    function setTGEDate(uint256 _time) external onlyOwner whenNotPaused  {
        TGEDate = _time;
    }

    /**
    *   Should allow any address to trigger it, but since the calls are atomic it should do only once per day
     */

    function triggerTokenSend() external whenNotPaused  {
        /* Require TGE Date already been set */
        require(TGEDate != 0, "TGE date not set yet");
        /* TGE has not started */
        require(block.timestamp > TGEDate, "TGE still hasn´t started");
        /* Test that the call be only done once per day */
        require(block.timestamp.sub(lastDateDistribution) > 1 days, "Can only be called once a day");
        lastDateDistribution = block.timestamp;
        /* Go thru all tokenOwners */
        for(uint i = 0; i < tokenOwners.length; i++) {
            /* Get Address Distribution */
            DistributionStep[] memory d = distributions[tokenOwners[i]];
            /* Go thru all distributions array */
            for(uint j = 0; j < d.length; j++){
                if( (block.timestamp.sub(TGEDate) > d[j].unlockDay) /* Verify if unlockDay has passed */
                    && (d[j].currentAllocated > 0) /* Verify if currentAllocated > 0, so that address has tokens to be sent still */
                ){
                    uint256 sendingAmount;
                    sendingAmount = d[j].currentAllocated;
                    distributions[tokenOwners[i]][j].currentAllocated = distributions[tokenOwners[i]][j].currentAllocated.sub(sendingAmount);
                    distributions[tokenOwners[i]][j].amountSent = distributions[tokenOwners[i]][j].amountSent.add(sendingAmount);
                    require(erc20.transfer(tokenOwners[i], sendingAmount));
                }
            }
        }   
    }

    function setInitialDistribution(address _address, uint256 _tokenAmount, uint256 _unlockDays) internal onlyOwner whenNotPaused {
        /* Add tokenOwner to Eachable Mapping */
        bool isAddressPresent = false;

        /* Verify if tokenOwner was already added */
        for(uint i = 0; i < tokenOwners.length; i++) {
            if(tokenOwners[i] == _address){
                isAddressPresent = true;
            }
        }
        /* Create DistributionStep Object */
        DistributionStep memory distributionStep = DistributionStep(_tokenAmount * decimals, _tokenAmount * decimals, _unlockDays, 0);
        /* Attach */
        distributions[_address].push(distributionStep);

        /* If Address not present in array of iterable token owners */
        if(!isAddressPresent){
            tokenOwners.push(_address);
        }

    }
}