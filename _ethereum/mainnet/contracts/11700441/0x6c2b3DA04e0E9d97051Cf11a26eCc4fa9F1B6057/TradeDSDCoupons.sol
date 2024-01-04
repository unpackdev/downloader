pragma solidity ^ 0.4 .26;

contract ERC20 {
    function transfer(address receiver, uint amount) public;

    function balanceOf(address tokenOwner) public constant returns(uint balance);
}



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
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
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
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}




interface IDSDS {
    function epoch() external view returns(uint256);

    function transferCoupons(address sender, address recipient, uint256 epoch, uint256 amount) external;

    function balanceOfCoupons(address account, uint256 epoch) external view returns(uint256);

    function allowanceCoupons(address owner, address spender) external view returns(uint256); //check address has enabled selling (>1)
}

contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract TradeDSDCoupons is ReentrancyGuard {


    using SafeMath
    for uint;

    IDSDS public DSDS = IDSDS(0x6Bf977ED1A09214E6209F4EA5f525261f1A2690a);




    function DSDperUSDC() public view returns(uint) {
        return ERC20(0xBD2F0Cd039E0BFcf88901C98c0bFAc5ab27566e3).balanceOf(0x66e33d2605c5fB25eBb7cd7528E7997b0afA55E8).div(ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(0x66e33d2605c5fB25eBb7cd7528E7997b0afA55E8)).div(1e9);
    } //to 3 decimals

    function USDCperETH() public view returns(uint) {
        return ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc).mul(1e12).div(ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc));
    } //zero decimals

    function DSDperETH() public view returns(uint) {
        return DSDperUSDC().mul(USDCperETH()).div(1000);
    }



    address[] addressList; //each time an initial sellRate is set, address is added here
    mapping(address => uint) public sellRate;
    mapping(address => uint256) public ETHbalances; // records amounts invested  

    function setRate(uint rate) external nonReentrant {
        uint numElements = addressList.length;
        uint i;
        if (sellRate[msg.sender] == 0 && rate > 10 && rate < 100) { //initial rate for an address
            sellRate[msg.sender] = rate;
            addressList.push(msg.sender);
            numElements = addressList.length;
            //sort addressList in ascending rate order
            if (numElements > 1)
                for (i = numElements - 1; i > 0; i--) {
                    if (sellRate[addressList[i]] < sellRate[addressList[i - 1]]) {
                        addressList[i] = addressList[i - 1];
                        addressList[i - 1] = msg.sender;
                    } else break;
                }
        } else
            //update previous rate
            if (rate > 10 && rate < 100) {
                uint previousRate = sellRate[msg.sender];
                uint addressListLocation = 0;
                if (numElements > 1) {
                    for (i = numElements - 1; i > 0; i--) {
                        if (addressList[i] == msg.sender) {
                            addressListLocation = i;
                            break;
                        }
                    }
                    sellRate[msg.sender] = rate;
                    //sort addressList in ascending rate order  - case where previous rate was higher so shift down
                    if (previousRate > rate) {
                        for (i = addressListLocation; i > 0; i--) {
                            if (sellRate[addressList[i]] < sellRate[addressList[i - 1]]) {
                                addressList[i] = addressList[i - 1];
                                addressList[i - 1] = msg.sender;
                            } else break;
                        }
                    } else if (addressListLocation + 1 < numElements) //shift the other way
                    {
                        for (i = addressListLocation; i < numElements - 1; i++) {
                            if (sellRate[addressList[i]] > sellRate[addressList[i + 1]]) {
                                addressList[i] = addressList[i + 1];
                                addressList[i + 1] = msg.sender;
                            } else break;
                        }
                    }
                }

            }

    }



    function uint2str(uint i) internal pure returns(string) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }




function address2ShortString(address _address) public pure returns(string memory) {
       bytes32 _bytes = bytes32(uint256(_address));
       bytes memory HEX = "0123456789abcdef";
       bytes memory _string = new bytes(42);
       _string[0] = '0';
       _string[1] = 'x';
       for(uint i = 0; i < 20; i++) {
           _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
           _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
       }

       bytes memory strBytes = bytes(string(_string));
       uint endIndex=4; uint startIndex=0;
       bytes memory result = new bytes(endIndex-startIndex);
       for(i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];}
       
       return string(result);
       
    }


    function showAvailableCoupons(uint maxPrice, uint addressListLocation) public view returns(string memory) { // 99999 location to show all addresses
        address addressToShow; uint numAddresses = 1;
        string memory couponList = "The following coupons are available to purchase directly with ETH at current DSD rates:";
        if (addressListLocation != 99999) {
            addressToShow = addressList[addressListLocation];
        } else {
            addressToShow = addressList[0];
            numAddresses = addressList.length;
        }
        uint DSDepoch = currentEpoch();
        for (uint i = 0; i < numAddresses; i++) {
            //break out if over maxPrice
            if (sellRate[addressToShow] > maxPrice) break;
            //first check if allowanceCoupons/sell is enabled in this addressToShow
            if (approvedToSell(addressToShow) > 1) { //loop through current epoch minus 360 to present
                couponList = string(abi.encodePacked(couponList, '{', address2ShortString(addressToShow),'..  DSD/Coupon offer: 0.', uint2str(sellRate[addressToShow]), ' }:'));
                for (uint ep = DSDepoch.sub(360); ep < DSDepoch; ep++) {
                    uint couponBalance = DSDS.balanceOfCoupons(addressToShow, ep);
                    if (couponBalance > 0) couponList = string(abi.encodePacked(couponList, '[', uint2str(ep), ': ', uint2str(couponBalance.div(1e18)), '] '));
                }

            }



            if (i + 1 < numAddresses) addressToShow = addressList[i + 1];
        }

        return couponList;


    }




    function buyCoupons(uint epoch, uint addressListLocation) payable external nonReentrant {
        uint buyRate = sellRate[addressList[addressListLocation]];
        address buyFrom = addressList[addressListLocation];
        uint refund;
        require(buyRate > 0, "Invalid address");
        require(approvedToSell(buyFrom) > 1, 'Sale not approved'); //require seller to have approved sale
        uint DSDETH = DSDperETH();
        uint couponAmount = msg.value.mul(DSDETH).mul(1e2).div(buyRate);
        uint couponBalance = DSDS.balanceOfCoupons(buyFrom, epoch);
        if (couponAmount > couponBalance) {refund = (couponAmount - couponBalance).mul(buyRate).div(DSDETH).div(1e2); couponAmount = couponBalance;} 
        if (refund > msg.value) refund = msg.value;

        ETHbalances[msg.sender] += refund;
        ETHbalances[buyFrom] += msg.value.sub(refund);
        DSDS.transferCoupons(buyFrom, msg.sender, epoch, couponAmount);

    }
    


    function approvedToSell(address addressToCheck) public view returns (uint) {
        return DSDS.allowanceCoupons(addressToCheck, address(this));  // anything over 1 means approved
    }
    
     
    function currentEpoch() public view returns (uint) {
        return DSDS.epoch();
    }

    function claimETH() external nonReentrant {
         uint claimFee=  ETHbalances[msg.sender].div(33)  ;   //small 3% claim fee eg. will get over 0.29 DSD if selling for 0.3 per coupon
         
        if (msg.sender.call.value(ETHbalances[msg.sender].sub(claimFee))())  {
            ETHbalances[msg.sender] = 0;
            ETHbalances[0x79E77ED9D3125117003DD592E58109398488f4Ca] += claimFee;
        }
    }




}