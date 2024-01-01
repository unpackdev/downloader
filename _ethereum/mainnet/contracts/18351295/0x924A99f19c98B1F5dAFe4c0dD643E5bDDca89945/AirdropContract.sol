// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
  //  * @dev Returns the token decimals.
  //  */
  function decimals() external view returns (uint8);

  // /**
  //  * @dev Returns the token symbol.
  //  */
  function symbol() external view returns (string memory);

  // /**
  // * @dev Returns the token name.
  // */
  function name() external view returns (string memory);

  /**
   
   */
 

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address payable) {
    return payable (msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


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
    // Solidity only automatically asserts when dividing by 0
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


contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
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
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * Available since v3.1.
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * Available since v3.1.
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * Available since v3.1.
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * Available since v3.1.
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract AirdropContract is Context  {
    address public owner; // Contract owner's address  it also collect the pickup fee
   uint256 public superAdminFee= 0.01 ether;
   
    struct AirdropDetails{
    // uint256 approvedToken; // Amount of tokens approved by the owner
    bool Anyone;// anyone claim on not
    // bool aridropCreated; // bool to check if the airdrop created
    uint256 FixedAmount;// if anyone is selected than this amount of token can be airdrop "AnyAmount"
    uint256 AlreadyClaimedAmount;
    uint256 PickUpFee;
    uint256 startTime;    // Presale start time (Unix timestamp)
    uint256  endTime;      // Presale end time (Unix timestamp)
    address airdropCreator;
}

    struct AirdropUser {
        uint256 amount; // for list of array address 
        bool claimed;
    }

   mapping (address=> mapping (address=>uint256) ) public claimedDataEachUser ;
    mapping (address => AirdropDetails) public AirDropDetailsMap; //erc20 contract address 

    mapping(address => mapping ( address => AirdropUser)) public specificUsers; // Mapping to store specific users and their claimable amounts


    

    constructor() {
        owner = msg.sender;
      
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this operation");
        _;
    }




    // Add specific users and their claimable amounts
    function addUserslist(address[] calldata users, uint256[] calldata amounts,address _tokenAddress ) external  {
    //  IERC20   token = IERC20(_tokenAddress); // Initialize with the ERC-20 token contract address

        require(users.length == amounts.length, "Arrays length mismatch");

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 amount = amounts[i];
            require(user != address(0), "Invalid user address");
            require(amount > 0, "Amount should be greater than 0");

            specificUsers[_tokenAddress][user] = AirdropUser(amount, false);
        }
    }


function AddcontractDetails  (address _tokenAddress,bool _Anyone,uint256 _FixedAmount,uint256 _PickUpFee ,uint256 _startTime,uint256 _endTime,address _airdropCreator)  payable  public  {

    require(msg.value ==superAdminFee ,"have to ppay the airdrop fee" );
    // IERC20   token = IERC20(_tokenAddress);

  AirDropDetailsMap[_tokenAddress].Anyone=_Anyone;

  AirDropDetailsMap[_tokenAddress].FixedAmount=_FixedAmount;

  AirDropDetailsMap[_tokenAddress].AlreadyClaimedAmount=0;

   AirDropDetailsMap[_tokenAddress].PickUpFee=_PickUpFee;

    AirDropDetailsMap[_tokenAddress].startTime=_startTime;

    AirDropDetailsMap[_tokenAddress].endTime=_endTime;

    //  AirDropDetailsMap[_tokenAddress].aridropCreated=true;

     AirDropDetailsMap[_tokenAddress].airdropCreator  =_airdropCreator;

}                                                   


    // Perform airdrop to a specific user list 
    function claim(address _tokenAddress) public payable  {
        IERC20   token = IERC20(_tokenAddress); // Initialize with the ERC-20 token contract address
         require(block.timestamp >= AirDropDetailsMap [_tokenAddress].startTime && block.timestamp <=  AirDropDetailsMap [_tokenAddress].endTime, "Presale is not open");
        //  require( AirDropDetailsMap[_tokenAddress].aridropCreated==false," airdrop already created");
        
        if (AirDropDetailsMap[_tokenAddress].PickUpFee != 0){

        require(msg.value>= AirDropDetailsMap[_tokenAddress].PickUpFee, "dono have engouh amount");
        payable(AirDropDetailsMap[_tokenAddress].airdropCreator).transfer(msg.value);

        }

        if (AirDropDetailsMap[_tokenAddress].Anyone==true){

       AirDropDetailsMap[_tokenAddress].AlreadyClaimedAmount+= AirDropDetailsMap[_tokenAddress].FixedAmount;
        claimedDataEachUser[_tokenAddress][msg.sender]=AirDropDetailsMap[_tokenAddress].FixedAmount;
        token.transferFrom(AirDropDetailsMap[_tokenAddress].airdropCreator,msg.sender, AirDropDetailsMap[_tokenAddress].FixedAmount);
        
      
            }
        else{

        AirdropUser storage user = specificUsers[_tokenAddress][msg.sender];
        require(user.amount > 0, "User not eligible for airdrop");
        require(!user.claimed, "User already claimed tokens");

        user.claimed = true;
           AirDropDetailsMap[_tokenAddress].AlreadyClaimedAmount+=user.amount;
        claimedDataEachUser[_tokenAddress][msg.sender]=user.amount;
        token.transferFrom(AirDropDetailsMap[_tokenAddress].airdropCreator,msg.sender, user.amount);
        }

    }

    function setOwner (address _newFeecollector) public onlyOwner {
        owner =_newFeecollector;
    }

    function setAdminFee (uint256 _newfee) public onlyOwner{
        superAdminFee= _newfee;
    }

 
    function withdrawFunds() external onlyOwner {
        address payable ownerPayable = payable(owner);
        ownerPayable.transfer(address(this).balance);
    }

    function withdrawUnsoldTokens(address _contractAddess) external onlyOwner {
        IERC20 token = IERC20(_contractAddess);
        require(
            token.transfer(owner, token.balanceOf(address(this))),
            "Token transfer failed"
        );
    }

}