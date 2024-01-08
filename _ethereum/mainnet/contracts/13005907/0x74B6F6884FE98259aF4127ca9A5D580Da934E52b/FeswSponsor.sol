// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

/**
 * @title FeswSponsor contract
 * @dev To raise sponsor and give away FESW
 */

contract FeswSponsor { 

    using SafeMath for uint256;

    // Public variables
    // FeSwap sponsor raising target: 1000 ETH
    uint256 public constant TARGET_RAISING_ETH = 1_000e18;    

    // FeSwap sponsor raising cap: 1001 ETH
    uint256 public constant MIN_GUARANTEE_ETH = 1e18;    

    // Initial FESW giveaway rate per ETH: 100K FESW/ETH
    uint256 public constant INITIAL_FESW_RATE_PER_ETH = 100_000;    

    // FESW giveaway change rate for total sponsored ETH, corresponding granulity is 0.05ETH
    uint256 public constant FESW_CHANGE_RATE_VERSUS_ETH = 20; 

    // FESW sponsor raising duration: 30 days 
    uint256 public constant SPONSOR_DURATION = 30 * 24 * 3600;     

    // contract of Feswap DAO Token
    address public FeswapToken;     

    // Feswap foundation address
    address public FeswapFund;     

    // Feswap Burner address
    address public FeswapBurner;     

    // Total received ETH
    uint256 public TotalETHReceived;   

    // Current giveaway rate
    uint256 public CurrentGiveRate;    

    // Sponsor start timestamp
    uint64 public SponsorStartTime;

    // Last block timestamp
    uint64 public LastBlockTime;

    // If sponsor raising finalized
    uint64 public SponsorFinalized;

    // Events for received sponsor
    event EvtSponsorReceived(address indexed from, address indexed to, uint256 ethValue);

    // Events for finalized sponsor
    event EvtSponsorFinalized(address indexed to, uint256 ethValue);
  
    /**
     * @dev Initializes the contract with fund and burner address
     */
    constructor (address feswapToken, address feswapFund, address feswapBurner, uint256 sponsorStartTime ) 
    {
        FeswapToken         = feswapToken;
        FeswapFund          = feswapFund; 
        FeswapBurner        = feswapBurner; 
        SponsorStartTime    = uint64(sponsorStartTime);
    }

    /**
     * @dev Receive the sponsorship
     * @param feswapReceiver The address receiving the giveaway FESW token
     */
    function Sponsor(address feswapReceiver) external payable returns (uint256 sponsorAccepted) {
        require(block.timestamp >= SponsorStartTime, 'FESW: SPONSOR NOT STARTED');
        require(block.timestamp < (SponsorStartTime + SPONSOR_DURATION), 'FESW: SPONSOR ENDED');
        require(TotalETHReceived < TARGET_RAISING_ETH, 'FESW: SPONSOR COMPLETED');

        // calculate the giveaway rate
        uint256 feswGiveRate;
        if(block.timestamp > LastBlockTime) {
            // granulity is 0.05 ETH
            feswGiveRate = INITIAL_FESW_RATE_PER_ETH - TotalETHReceived.mul(FESW_CHANGE_RATE_VERSUS_ETH).div(1e18);
            CurrentGiveRate = feswGiveRate;
            LastBlockTime = uint64(block.timestamp);
        } else {
            feswGiveRate = CurrentGiveRate;
        }

        // Maximum 1001 ETH accepted, extra ETH will be returned back
        sponsorAccepted = TARGET_RAISING_ETH - TotalETHReceived;
        if(sponsorAccepted < MIN_GUARANTEE_ETH){
            sponsorAccepted = MIN_GUARANTEE_ETH;
        }
        if (msg.value < sponsorAccepted){
            sponsorAccepted = msg.value;          
        }                                                        

        // Accumulate total ETH sponsored
        TotalETHReceived += sponsorAccepted;                                                              

        // FESW give away
        uint256 feswapGiveaway = sponsorAccepted.mul(feswGiveRate);
        TransferHelper.safeTransfer(FeswapToken, feswapReceiver, feswapGiveaway);
 
        // return back extra ETH
        if(msg.value > sponsorAccepted){
            TransferHelper.safeTransferETH(msg.sender, msg.value - sponsorAccepted);
        }    
        
        emit EvtSponsorReceived(msg.sender, feswapReceiver, sponsorAccepted);
    }

    /**
     * @dev Finalize Feswap sponsor raising
     */
    function finalizeSponsor() public {
        require(SponsorFinalized == 0, 'FESW: SPONSOR FINALIZED');
        require(msg.sender == FeswapFund, 'FESW: NOT ALLOWED');
        require( (block.timestamp >= (SponsorStartTime + SPONSOR_DURATION)) 
                    || (TotalETHReceived >= TARGET_RAISING_ETH), 'FESW: SPONSOR ONGOING');

        // If sponsor raising succeeded, burning left FESW
        address to = FeswapBurner;

        // If sponsor raising failed 
        if(TotalETHReceived < TARGET_RAISING_ETH) to = FeswapFund;

        // Claim or burn the left FESW
        uint256 feswLeft = IERC20(FeswapToken).balanceOf(address(this));
        TransferHelper.safeTransfer(FeswapToken, to, feswLeft);

        // Claim the raised sponsor
        TransferHelper.safeTransferETH(FeswapFund, address(this).balance );
        SponsorFinalized = 0xA5;

        emit EvtSponsorFinalized(FeswapFund, TotalETHReceived);
    }
}