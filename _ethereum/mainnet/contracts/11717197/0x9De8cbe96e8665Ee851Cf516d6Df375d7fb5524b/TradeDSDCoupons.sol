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




interface UniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}




contract TradeDSDCoupons is ReentrancyGuard {


    using SafeMath
    for uint;

    IDSDS public DSDS = IDSDS(0x6Bf977ED1A09214E6209F4EA5f525261f1A2690a);



// Better pricefeed mechanism showing price in previous block with transaction activity on the uniswap pair 
// (cannot be exploited by borrowing - they would need to sell a huge amount of DSD to lower price temporarily and attempt to buy back before others do - see second check)
// Seller can now also set a minimum DSD price they would sell their coupons for

    address private factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private DSD = 0xBD2F0Cd039E0BFcf88901C98c0bFAc5ab27566e3;
    address private ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function getTokenReserves(address token1, address token2) public view returns (uint, uint) {
        address pair = UniswapV2Factory(factory).getPair(token1, token2);
        (uint reserve0, uint reserve1, ) = UniswapV2Pair(pair).getReserves();
        return (reserve0, reserve1);
    }





// new functions for pricefeed
    function DSDperUSDC() public view returns(uint) {
       (uint USDCtotal, uint DSDtotal) = getTokenReserves(USDC, DSD);
        return DSDtotal.div(USDCtotal).div(1e9);
    } //to 3 decimals

    function USDCperETH() public view returns(uint) {
       (uint USDCtotal, uint ETHtotal) = getTokenReserves(USDC, ETH);
       
       
        //get USDCperETH for each feed
        uint USDCETH = USDCtotal.mul(1e12).div(ETHtotal); uint unsafeUSDCETH = unsafeUSDCperETH();
        
        //ensures both ETH price feeds are within ~3% to ensure no price swings in either direction which could indicate attempted manipulation - we use the getReserves value if this passes
        uint checkforETHpricemove = USDCETH.mul(1000).div(unsafeUSDCETH);
        
        if (checkforETHpricemove < 1030 && checkforETHpricemove > 970) return USDCETH; else   return 0;
    } //zero decimals

    function DSDperETH() public view returns(uint) {
        
        //find both DSD rates and use lowest (i.e. the most expensive DSD - will produce lowest return of coupons and should fail minOutput if manipulation is present)
        uint DSDETH = DSDperUSDC().mul(USDCperETH()).div(1000);
        uint unsafeDSDETH = unsafeDSDperETH();
        if (unsafeDSDETH < DSDETH) DSDETH = unsafeDSDETH;
        
        return DSDETH;
    }


// old method of pricefeed (can be exploited but used as a second check on getReserves to detect recent price moves - will use the highest DSD price detected of the two methods and will not complete if ETH moved more then 3% either way)
// Remember buyer now has a minimum amount of tokens (using slippage control) to buy so will revert if DSD increases too much

    function unsafeDSDperUSDC() public view returns(uint) {
        return ERC20(0xBD2F0Cd039E0BFcf88901C98c0bFAc5ab27566e3).balanceOf(0x66e33d2605c5fB25eBb7cd7528E7997b0afA55E8).div(ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(0x66e33d2605c5fB25eBb7cd7528E7997b0afA55E8)).div(1e9);
    } //to 3 decimals

    function unsafeUSDCperETH() public view returns(uint) {
        return ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc).mul(1e12).div(ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc));
    } //zero decimals

    function unsafeDSDperETH() public view returns(uint) {
        return unsafeDSDperUSDC().mul(unsafeUSDCperETH()).div(1000);
    }



    address[] addressList; //each time an initial sellRate is set, address is added here (not public for slightly more privacy)
    mapping(address => uint) public sellRate;     //seller will need to set price in DSD for coupons they want to sell (all coupons they have are for sale so others need to be wrapped or transferred out to another address)
    mapping(address => string) public username;   //allows direct selling by username if username is set (buyer can be sent a link with username parameter in URL)
    mapping(address => uint) public minDSDprice;  //prevent a user's coupons from selling at too low a price if this is set by the seller (so they don't get less ETH than expected for a sale when DSD is overly low)
    
    
    mapping(address => uint256) public ETHbalances; // records amounts received from buyers (claim later to prevent gas limit problems)  

    function setRate(uint rate) external nonReentrant {
        uint numElements = addressList.length;
        uint i;
        if (sellRate[msg.sender] == 0 && rate > 10 && rate < 100) { //initial rate for an address
            sellRate[msg.sender] = rate;
            addressList.push(msg.sender);
            //set default username (for easy url linking)
            username[msg.sender] = address2ShortString(msg.sender);
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
                sellRate[msg.sender] = rate;
                if (numElements > 1) {
                    uint addressListLocation = 0;
                    for (i = numElements - 1; i > 0; i--) {
                        if (addressList[i] == msg.sender) {
                            addressListLocation = i;
                            break;
                        }
                    }
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




function address2ShortString(address _address) internal pure returns(string memory) {
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
        
        string memory couponList = "The following coupons are available to purchase directly with ETH at current DSD rates:";
    
        if (addressListLocation != 99999) {loopStart = addressListLocation; uint numAddresses = 1;}  else  {numAddresses = addressList.length; uint loopStart=0; }
        
        uint DSDepoch = currentEpoch();
        for (uint i = loopStart; i < (loopStart+numAddresses); i++) {
            //break out if over maxPrice
            if (sellRate[addressList[i]] > maxPrice) break;
            //first check if allowanceCoupons/sell is enabled in this addressToShow
            if (approvedToSell(addressList[i]) > 1) { //loop through current epoch minus 360 to present
                couponList = string(abi.encodePacked(couponList, '{', returnUsernamebyAddressLocation(i),'..  DSD/Coupon offer: 0.', uint2str(sellRate[addressList[i]]), ' }:'));
                for (uint ep = DSDepoch.sub(360); ep < DSDepoch; ep++) {
                    uint couponBalance = DSDS.balanceOfCoupons(addressList[i], ep);
                    if (couponBalance > 0) couponList = string(abi.encodePacked(couponList, '[', uint2str(ep), ': ', uint2str(couponBalance.div(1e18)), '] '));
                }

            }

        }

        return couponList;


    }
    


    function returnAddressLocationbyUsername(string usern) public view returns (uint){
        uint numAddresses = addressList.length;
        uint location = 0; string memory defaultAdd;
        bool addDefault = true; 
        if (bytes(usern).length==4 && bytes(usern)[0]=='0' && bytes(usern)[1]=='x') addDefault=false; // if username is default short address, don't add when searching
        for (uint i = 0; i < numAddresses-1; i++) { 
            if (addDefault) defaultAdd=address2ShortString(addressList[i]); else defaultAdd='';
            if (keccak256(bytes(username[addressList[i]]))==keccak256(bytes(string(abi.encodePacked(defaultAdd,usern))))) {location=i; break;}}
        
            
        return location; //will return cheapest coupon seller at location 0 if no match
    }


    function returnUsernamebyAddressLocation(uint addressLocation) public view returns (string){
         string memory usern=username[addressList[addressLocation]];
         if (bytes(usern).length>4) {  //remove first 4 characters since it is not the default username
                   bytes memory strBytes = bytes(string(usern));
                   uint endIndex=bytes(usern).length; uint startIndex=0;
                 bytes memory result = new bytes(endIndex-startIndex);
                 for( uint i = startIndex; i < endIndex; i++) {
                     result[i-startIndex] = strBytes[i];}
                      return string(result); 
         } else return usern;
    }
    
    function returnMinDSDpricebyAddressLocation(uint addressLocation) public view returns (uint){
        return minDSDprice[addressList[addressLocation]]; 
    }
    
    function returnAddressListLength() public view returns (uint){   //easier method of accessing length of non-public addressList 
        return addressList.length; 
    }



    function setUsername(string str) external {
       //check string is within reasonable character limit
       if (bytes(str).length>1 && bytes(str).length<32)
            username[msg.sender] =  string(abi.encodePacked(address2ShortString(msg.sender),str));   //all usernames have a small part of ETH address prepended to it to help prevent duplicates
   }
   
   
   function setminDSDprice(uint price) external {
       if (price<1000)  // min must be under $10  - very extreme case which is never likely to be reached
            minDSDprice[msg.sender] =  price;   
   }

    function buyCoupons(uint epoch, uint addressListLocation, string usern, uint minOutput) payable external nonReentrant {
        address buyFrom = addressList[addressListLocation];
        
        if (bytes(usern).length>1)  buyFrom = addressList[returnAddressLocationbyUsername(usern)];   //get location if username is specified
           
        
        uint buyRate = sellRate[buyFrom];
        
        uint refund;
        require(buyRate > 0, "Invalid address");
        require(approvedToSell(buyFrom) > 1, 'Sale not approved'); //require seller to have approved sale
        
        //function already checks both DSDperETH rates and uses lowest (i.e. the most expensive DSD - will produce lowest return of coupons and should fail minOutput if manipulation is present)
        uint DSDETH = DSDperETH();
        //function already checks both ETH rates and only returns non-zero if they are within ~3%
        uint USDCETH = USDCperETH();
        
        
        //ensure DSD price being used is above any minimum set by seller
        require (USDCETH.mul(100).div(DSDETH) >= minDSDprice[buyFrom], 'DSD price too low for seller');
        
        
        uint couponAmount = msg.value.mul(DSDETH).mul(1e2).div(buyRate);
        //ensures cost per coupon is as envisaged by buyer (according to set slippage rate) - output may still be lower if less coupons are available
        require(couponAmount.div(1e18)>minOutput  , 'Output too low');  
        
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
    
    function clearAddressList () public { //in rare cases where too many people are selling (too much gas to process normal searching/sorting) this function will clear the most expensive 50% of sellers
         if (msg.sender==0x79E77ED9D3125117003DD592E58109398488f4Ca) // only contract deployer
              addressList.length=addressList.length.mul(5).div(10);
    }
    
    function claimETH() external nonReentrant {
         uint claimFee=  ETHbalances[msg.sender].div(33)  ;   //small 3% claim fee eg. will get over 0.29 DSD if selling for 0.3 per coupon
         
        if (msg.sender.call.value(ETHbalances[msg.sender].sub(claimFee))())  {
            ETHbalances[msg.sender] = 0;
            ETHbalances[0x79E77ED9D3125117003DD592E58109398488f4Ca] += claimFee;
        }
    }




}