// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Question.sol

pragma solidity >=0.6.0;


contract Question {

    using SafeMath for uint256;

    uint256 public qnonce;
    mapping(uint256=>bytes32)public qhash;
    mapping(uint256 =>bytes32)public ahash;
    
    mapping(uint256 =>address) public questioner; 
    mapping(uint256 => uint256) public atoq; 
    mapping(uint256 => uint256)public qtoq;
    mapping(address =>uint256) public reward;
    mapping(uint256 => uint256) public likes;
    
    
    function aandq(uint256 qNonce_,bytes32 a_,bytes32 q_) external payable {
        require(msg.value == 1e17," != 1e17");
        require(qNonce_ <= qnonce && qNonce_ > 0,"err");
        require(msg.sender != questioner[qNonce_],"cannot answer your own question");
        require(!isContract(msg.sender), "must be a normal address");
        
        qnonce++;
        qhash[qnonce] = q_;
        ahash[qnonce-1] = a_;
        uint256 _v;
        uint256 _i = qnonce;

        questioner[qnonce] = msg.sender;
        atoq[qnonce-1]=qNonce_;
        qtoq[qnonce] = qNonce_;
        
        for(uint256 i=0;i<15;i++){
            if(qtoq[_i] !=1){
                reward[questioner[qtoq[_i]]] = reward[questioner[qtoq[_i]]].add(msg.value.div(2**(i+1)));
                _v = _v.add(msg.value.div(2**(i+1)));
                emit Reward(i,msg.value.div(2**(i+1)),questioner[qtoq[_i]]);
                _i = qtoq[_i];
            }else{
                break;
            }
        }

        reward[questioner[1]] = reward[questioner[1]].add(msg.value.sub(_v));
        emit AskAndAnswer(msg.sender,qnonce,qNonce_,q_,a_);
    }


    function firstQ(bytes32 q_) external {
        require(qnonce == 0,"had");
        qnonce++;
        qhash[qnonce] = q_;
        questioner[qnonce] = msg.sender;
        emit AskAndAnswer(msg.sender,qnonce,0,q_,0);
    }

    function like(uint256 nonce_) external {
        likes[nonce_] = likes[nonce_]+1;
        emit Like(msg.sender,nonce_);
    }

    function claim() external {
        require(reward[msg.sender] > 0,"zero");
        uint256 v = reward[msg.sender];
        reward[msg.sender] =0;
        msg.sender.transfer(v);
        emit Claim(msg.sender,v);
    }

    function isContract(address addr_) private view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(addr_)}
        return size > 0;
    }


    event AskAndAnswer(address indexed questioner,uint256 qnonce,uint256 atoq,bytes32 q,bytes32 a);
    event Claim(address indexed user,uint256 amount);
    event Like(address indexed user,uint256 anonce);
    event Reward(uint256 i,uint256 amount,address user);
}