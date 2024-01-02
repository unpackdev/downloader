// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;
pragma abicoder v2;

/**
* @dev Interface for chainlink price oracle 
*/
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

/**
* @dev Interface for Subscription contract.  Allows the contract to query the subscription
* status of an address
*/
interface ISUB{

  function isSubscriber(address _address) external view returns (bool);

}


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    
    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
   
    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
* @dev chainlink price oracle to return ETH/USD price data
*/
abstract contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

     /**
     * Network: mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256, uint80) {
        (
            uint80 roundID, 
            int price,
            /* uint startedAt */,
            /* uint timeStamp */,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        return (uint256(price), roundID);
    }

     /**
     * Returns historical price for a round id.
     * roundId is NOT incremental. Not all roundIds are valid.
     * You must know a valid roundId before consuming historical data.
     *
     * ROUNDID VALUES:
     *    InValid:      18446744073709562300
     *    Valid:        18446744073709562301
     *    
     * @dev A timestamp with zero value means the round is not complete and should not be used.
     */
    function getHistoricalPrice(uint80 roundId) public view returns (uint256) {
        (
            /* uint80 id */, 
            int price,
            /* uint startedAt */,
            uint timeStamp,
            /* uint80 answeredInRound */
        ) = priceFeed.getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return uint256(price);
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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

}



/**
* @dev AtomicSwap contract allows users to create many to many NFT swaps between two parties
* in a single atomic transaction. The contract supports the NFT ERC721 and ERC1155 standards 
* as well as the ability to send Ethereum as part of the contract. 
* NEFSTER.COM
*/
contract AtomicSwap is Ownable, Pausable, PriceConsumerV3 {

    using SafeMath for uint;

    // Swap Status
    enum swapStatus { New, Opened, Closed, Cancelled }
    enum contractType { ERC721, ERC1155 }

    struct atomicSwapContract {
        address payable addressOne;
        uint256 valueOne;
        address payable addressTwo;
        uint256 valueTwo;
        bytes nonce;
        affiliateStruct affiliateOne;
        affiliateStruct affiliateTwo;
        nftStruct nftsOne;
        nftStruct nftsTwo;
    }

    struct nftStruct {
        address[] contractAddress;
        uint256[] tokenId; 
        uint256[] amount;
        bytes[] data;
        contractType[] typeOf;
    }

    struct affiliateStruct {
        bytes32 code;
        address payable affiliateAddress;
        uint256 percent;
    }

    mapping(address => uint256) public affiliateBalanceNEF; // track the balance
    mapping(address => uint256) public rewardsBalanceNEF; // track the NEF rewards
    mapping(bytes32 => swapStatus) public swapContract;  // track the contract status
    mapping(bytes32 => uint256) public _feePaid; // track the swap fee paid

    uint256 public _ethFee;
    uint256 public _usdFee;
    uint256 public _pendingFee;
    uint256 public _feeBalance;
    uint256 public _commission;
    uint256 public _commissionMultiplier;
    uint256 public _commissionBalance;
    uint256 public _rewards;
    uint256 public _rewardsMultiplier;
    uint256 public _rewardsBalance;
    bool public _chainLink;
   
    address public _subscribeContract;
    address payable public _nefster;

    address private constant NEF_TOKEN = 0xDa6593dBF7604744972B1B6C6124cB6981b3c833; 
    IERC20 public immutable nefToken;

    event paymentReceived(address indexed payer, uint256 value);
    event swapCreated(bytes32 contractId);
    event swapClosed(bytes32 contractId);
    event swapCanceled(bytes32 contractId);
    event feeTransfer(uint256 amount);
    event commissionEarned(address indexed user, uint256 amount);
    event commissionWithdrawn(address indexed user, uint256 amount);
    event rewardEarned(address indexed user, uint256 amount);
    event rewardWithdrawn(address indexed user, uint256 amount);
    event nefWithdrawn(address indexed user, uint256 amount);

    string public constant name = "AtomicSwap";
    string public constant version = "1.0";
    string public constant codename = "NEFSTER";

    constructor()  {
        // 2x the NEF rewards for subscribers
        setRewardsMultiplier(2);
        setCommissionMultiplier(2);
        setChainLink(false);
        setEthFee(0);
        setUsdFee(0);
        setNefster(payable(0x1720530C97a0A40Bf9aA66BE3F2A7A38E45C195C));
        setSubContract(0x52F8463Db64Db12F1EDF84fdA8f85523A994a686);
        setRewardsNEF(100000000000000000000); // 100 NEF
        setCommissionNEF(100000000000000000000); // 100 NEF

        nefToken = IERC20(NEF_TOKEN);

    }
 
    receive() external payable { 
        _feeBalance = _feeBalance.add(msg.value);
        emit paymentReceived(msg.sender, msg.value);
    }

    /** 
    * @dev Create the atomic swap contract & return the contractId
    */
    function createAtomicSwap(atomicSwapContract memory _contract) payable public whenNotPaused returns(bytes32) {
        uint256 swapFee =  getSwapFee();
        require(msg.value >= _contract.valueOne.add(swapFee), "not enough eth sent");
        require(msg.sender == _contract.addressOne, "invalid nft holder address");
        // pending fee is refundable if the contract is cancelled
        _pendingFee = _pendingFee.add(swapFee);
        // get a new contract id 
        bytes32 _contractId = getContractId(_contract);
        // swap fee paid for this contract
        _feePaid[_contractId] = swapFee;
        // make sure this contract is new
        require(swapContract[_contractId] == swapStatus.New, "contract already exists");
        swapContract[_contractId] = swapStatus.Opened;
        emit swapCreated(_contractId);
        return _contractId;
    }

    /**
    * @dev internal function to calculate contract hash. Returns unique id per contract 
    */
    function getContractId(atomicSwapContract memory _contract) internal pure returns(bytes32) {
        return keccak256(abi.encode(_contract));
    }

    /**
    * @dev Close the atomic swap contract
    */
    function closeAtomicSwap(atomicSwapContract memory _contract, bytes32 _contractId) payable public whenNotPaused {
        uint256 swapFee = getSwapFee();
        require(msg.value >= _contract.valueTwo.add(swapFee), "not enough eth sent");
        require(_contractId == getContractId(_contract), "invalid contract hash");
        require(msg.sender == _contract.addressTwo, "invalid nft holder address");
        require(swapContract[_contractId] == swapStatus.Opened, "contract not open");
        
        // move the pending fee to contract fee balance
        _pendingFee = _pendingFee.sub(_feePaid[_contractId]);
        // check to see if we have subscriber affilates 
        bool subscriberOne = isSubscriber(_contract.addressOne);
        bool subscriberTwo = isSubscriber(_contract.addressTwo);
        // check for affiliates
        if (_contract.affiliateOne.code != 0 
            && _contract.affiliateOne.affiliateAddress != address(0) 
            && _contract.affiliateOne.percent > 0
            && swapFee > 0){
                // add the commission to the affiliateOne address
                uint256 commisionOne = subscriberOne ? _commission.mul(_commissionMultiplier) : _commission;
                affiliateBalanceNEF[_contract.affiliateOne.affiliateAddress] = affiliateBalanceNEF[_contract.affiliateOne.affiliateAddress].add(commisionOne);
                _commissionBalance = _commissionBalance.add(commisionOne);
                emit commissionEarned(_contract.affiliateOne.affiliateAddress, commisionOne);    
        }

        if (_contract.affiliateTwo.code != 0 
            && _contract.affiliateTwo.affiliateAddress != address(0) 
            && _contract.affiliateTwo.percent > 0
            && swapFee > 0){
                // add the commission to the affiliateTwo address
                uint256 commisionTwo = subscriberTwo ? _commission.mul(_commissionMultiplier) : _commission;
                affiliateBalanceNEF[_contract.affiliateTwo.affiliateAddress] = affiliateBalanceNEF[_contract.affiliateTwo.affiliateAddress].add(commisionTwo);
                _commissionBalance = _commissionBalance.add(commisionTwo);
                emit commissionEarned(_contract.affiliateTwo.affiliateAddress, commisionTwo);    
        }

        // The remaining swap fee goes to the house
        _feeBalance = _feeBalance.add(swapFee.add(_feePaid[_contractId])); 
            
        // do the eth transfers
        if (_contract.valueOne > 0) {
            _contract.addressTwo.transfer(_contract.valueOne);
        }
        if (_contract.valueTwo > 0) {
            _contract.addressOne.transfer(_contract.valueTwo);
        }
        // do the nft transfers 
        for(uint i=0; i < _contract.nftsTwo.contractAddress.length; i++) {
            if (_contract.nftsTwo.typeOf[i] == contractType.ERC721)
                IERC721(_contract.nftsTwo.contractAddress[i])
                .safeTransferFrom(_contract.addressTwo, 
                                  _contract.addressOne, 
                                  _contract.nftsTwo.tokenId[i],
                                  _contract.nftsTwo.data[i]);
            else
                IERC1155(_contract.nftsTwo.contractAddress[i])
                .safeTransferFrom(_contract.addressTwo, 
                                  _contract.addressOne, 
                                  _contract.nftsTwo.tokenId[i],
                                  _contract.nftsTwo.amount[i],
                                  _contract.nftsTwo.data[i]);
        }
        for(uint i=0; i < _contract.nftsOne.contractAddress.length; i++) {
             if (_contract.nftsOne.typeOf[i] == contractType.ERC721)
                IERC721(_contract.nftsOne.contractAddress[i])
                .safeTransferFrom(_contract.addressOne, 
                                  _contract.addressTwo, 
                                  _contract.nftsOne.tokenId[i],
                                  _contract.nftsOne.data[i]);
            else
                IERC1155(_contract.nftsOne.contractAddress[i])
                .safeTransferFrom(_contract.addressOne, 
                                  _contract.addressTwo, 
                                  _contract.nftsOne.tokenId[i],
                                  _contract.nftsOne.amount[i],
                                  _contract.nftsOne.data[i]);
        }
        swapContract[_contractId] = swapStatus.Closed;
        emit swapClosed(_contractId);

        // NEF token rewards for addressOne
        uint256 rewardOne = subscriberOne ? _rewards.mul(_rewardsMultiplier) : _rewards;
        rewardsBalanceNEF[_contract.addressOne] = rewardsBalanceNEF[_contract.addressOne].add(rewardOne);
        emit rewardEarned(_contract.addressOne, rewardOne);
        // NEF token rewards for addressTwo
        uint256 rewardTwo = subscriberTwo ? _rewards.mul(_rewardsMultiplier) : _rewards;
        rewardsBalanceNEF[_contract.addressTwo] = rewardsBalanceNEF[_contract.addressTwo].add(rewardTwo);
        emit rewardEarned(_contract.addressTwo, rewardTwo);
        // update the rewards balance
        _rewardsBalance = _rewardsBalance.add(rewardOne).add(rewardTwo);
    }

    /**
     * @dev Cancel the atomic swap contract
     */ 
    function cancelAtomicSwap(bytes32 _contractId, atomicSwapContract memory _contract) public {
        require(_contractId == getContractId(_contract), "invalid contract hash");
        require(msg.sender == _contract.addressOne, "not swap creator");
        require(swapContract[_contractId] == swapStatus.Opened, "contract not open");
        // cancel the contract
        swapContract[_contractId] = swapStatus.Cancelled;
        // refund the fee paid 
        _pendingFee = _pendingFee.sub(_feePaid[_contractId]);
        // refund any crypto to swap creator - addressOne
        if(_contract.valueOne > 0){
            _contract.addressOne.transfer(_contract.valueOne.add(_feePaid[_contractId]));
        }
        // refund the swap free
        if (_feePaid[_contractId] > 0){
            _contract.addressOne.transfer(_feePaid[_contractId]);
        }
        emit swapCanceled(_contractId); 
    }

    /**
     * @dev Set the nefster address for fee payouts 
     */
    function setNefster(address payable _address) public onlyOwner {
      require(_address != address(0), "zero address");
      _nefster = _address;
    }

    /**
     * @dev Set the swap fee rate in wei
     */
    function setEthFee(uint256 _fee) public onlyOwner {
      _ethFee = _fee;
    }

    /**
     * @dev Set the swap fee rate in usd
     */
    function setUsdFee(uint256 _fee) public onlyOwner {
      _usdFee = _fee;
    }

      /**
     * @dev Set the chainLink flag
     */
    function setChainLink(bool _value) public onlyOwner {
      _chainLink = _value;
    }

    /**
    * @dev set the external subscription contract address and vendorId
    */
    function setSubContract(address _address) public onlyOwner {
        _subscribeContract = _address;
    }

    /**
    * @dev checks the external _subscribeContract to see if the address is a subscriber
    */
    function isSubscriber(address _address) public view returns (bool) {
        // create interface to subscribe contract
        ISUB SubContract = ISUB(_subscribeContract);
        // try-catch will return false on any error condition
        try SubContract.isSubscriber(_address) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }


    /**
    * @dev get the swap fee rate. calls external subscribe contract method isSubscriber
    * The swap fee for subscribers is zero.  For non-subscribers, return the _usdFee in ETH using the chainLink
    * price oracle when the _chainLink flag is true and _ethPrice when false;
    */
    function getSwapFee() public view returns (uint256) {
        if (isSubscriber(msg.sender)){
            return 0;
        }
        if (_chainLink && _usdFee > 0){
            (, uint80 _roundId) = getLatestPrice();
            return getUsdFee(_roundId);
        }
        // fallback to eth fee
        return _ethFee;
    }

    /**
     * @dev returns the _usdFee in ETH 
     * calls chainlink price oracle 
     * @param _roundID  the roundID value returned from Chainlink getHistoricalPrice
     * @return uint256 
     */
    function getUsdFee(uint80 _roundID) public view returns (uint256) {
      // get eth price from chainlink oracle 
      uint256 price = getHistoricalPrice(_roundID);
      return (1 ether / price.div(100000000)).mul(_usdFee);
    }


    /**
     * @dev Admin function to widthdraw ETH fees collected 
     */
    function transferFees(uint256 _amount) public returns(uint256) {
        require(msg.sender == _nefster, "only nefster can do this");
        require(_amount <= _feeBalance, "amount not available");
        _feeBalance = _feeBalance.sub(_amount);
        _nefster.transfer(_amount);
        emit feeTransfer(_amount);
        return _amount;
    }

    /**
     * @dev Admin function to widthdraw NEF tokens
     */
    function withdrawNEF(uint256 _amount) public onlyOwner {
        require(_amount <= getBalanceNEF(), "invalid amount");
        nefToken.transfer(msg.sender, _amount);
        emit nefWithdrawn(msg.sender, _amount);
    }

    /**
    * @dev returns the amount of NEF token currently held in the contract
    */
    function getBalanceNEF() public view returns (uint256) {
        return nefToken.balanceOf(address(this));
    }

    /**
    * @dev sets the current  affiliate commission amount in NEF
    */
    function setCommissionNEF(uint256 amount) public onlyOwner {
        _commission = amount;
    }

    /**
    * @dev sets the NEF commission multiplier for subscribers
    */
    function setCommissionMultiplier(uint256 amount) public onlyOwner {
        _commissionMultiplier = amount;
    }

    /**
    * @dev sets the current rewards  amount in NEF
    */
    function setRewardsNEF(uint256 amount) public onlyOwner {
        _rewards = amount;
    }

    /**
    * @dev sets the NEF rewards multiplier for subscribers
    */
    function setRewardsMultiplier(uint256 amount) public onlyOwner {
        _rewardsMultiplier = amount;
    }

   /**
    * @dev Allows users to withdraw all their NEF tokens
    */
    function withdrawAllNEF() public {
        uint256 total = rewardsBalanceNEF[msg.sender].add(affiliateBalanceNEF[msg.sender]);
        require(total > 0, "No NEF rewards to withdraw");
        require(nefToken.balanceOf(address(this)) >= total, "Not enough NEF tokens in contract");
        emit rewardWithdrawn(msg.sender, rewardsBalanceNEF[msg.sender]);
        emit commissionWithdrawn(msg.sender, affiliateBalanceNEF[msg.sender]);
        // Reset the balances to 0
        rewardsBalanceNEF[msg.sender] = 0;
        affiliateBalanceNEF[msg.sender] = 0;
        // transfer the NEF tokens
        nefToken.transfer(msg.sender, total);
    }

    /** 
     * @dev pause the contract
     */
    function pause(bool val) public onlyOwner {
        if (val) _pause();  else  _unpause();
    }

}