pragma solidity >=0.6.10;


// 
/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// 
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// 
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

contract CardDistributor is ERC165 {
    using SafeMath for uint;
    bytes4 private constant TRANSFER_FROM_SELECTOR_721 = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant TRANSFER_FROM_SELECTOR_1155 = bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256,uint256,bytes)')));

    bytes4 private constant TRANSFER_SELECTOR_20 = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant TRANSFER_FROM_SELECTOR_20 = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant BALANCE_OF_SELECTOR_20 = bytes4(keccak256(bytes('balanceOf(address)')));

    address public owner;

    struct CardInfo {
        uint256 price; // Card price over ymem
        uint256 amount;
        uint256 nftType; // It's 721 or 1155
    }

    mapping(address=>mapping(uint256=>CardInfo)) public cards;

    address public acceptToken;
    bool public claimable;

    event ClaimNFT(address indexed staker, address indexed nftAddress, uint256 indexed nftId, uint256 price);
    event AddCard(address _nftAddr, uint256 _nftId, uint256 _nftType, uint256 _amount, uint256 _price);
    event WithdrawCard(address _nftAddr, uint256 _nftType, uint256 _amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyClaimable() {
        require(claimable, "Not claimable");
        _;
    }

    constructor (address _acceptTokenAddress) public {
        owner = msg.sender;
        acceptToken = _acceptTokenAddress;
        _registerInterface(CardDistributor.onERC721Received.selector);
        _registerInterface(CardDistributor.onERC1155Received.selector);
        _registerInterface(CardDistributor.onERC1155BatchReceived.selector);
    }

    //////////////////////////
    /// Operation functions
    //////////////////////////
    function changeOwner(address newOwner) public onlyOwner() {
        require(newOwner != address(0), "Owner address invalid");
        owner = newOwner;
    }

    function startClaim() public onlyOwner() {
        claimable = true;
    }

    function stopClaim() public onlyOwner() {
        claimable = false;
    }

    // Add card info
    function addCard(address _nftAddr, uint256 _nftId, uint256 _nftType, uint256 _amount, uint256 _price) public onlyOwner() {
        require((_nftType == 721 || _nftType == 1155), "Card type must be 721 or 1155");

        CardInfo storage card = cards[_nftAddr][_nftId];

        require(card.nftType == 0 || (card.nftType != 0 && card.nftType == _nftType) , "Wrong NFT type");

        card.nftType = _nftType;
        if (_nftType == 721) {
            card.amount = 1;
        } else {
            card.amount = card.amount.add(_amount);
        }
        card.price = _price;

        emit AddCard(_nftAddr, _nftId, _nftType, _amount, _price);
    }

    // Send card back to owner
    function withdrawCard(address _nftAddr, uint256 _nftId) public onlyOwner() {
        CardInfo storage c = cards[_nftAddr][_nftId];
        uint256 amount = c.amount;
        c.amount = 0;

        require(c.nftType != 0, "Card does not exist");
        require(amount > 0 , "Card insufficient");

        _transferNft(_nftAddr, _nftId, c.nftType, msg.sender, amount);

        emit WithdrawCard(_nftAddr, _nftId, amount);
    }

    function resetCard(address _nftAddr, uint256 _nftId) public onlyOwner() {
        delete cards[_nftAddr][_nftId];
    }

    // Transfer all token to owner
    function withdrawToken() public onlyOwner() returns (uint256) {
        (bool success, bytes memory data) = acceptToken.call(abi.encodeWithSelector(BALANCE_OF_SELECTOR_20, address(this)));
        require(success, "Can not get balance");

        uint256 amount = abi.decode(data, (uint256));

        _safeTransferERC20(acceptToken, msg.sender, amount);
        return amount;
    }

    //////////////////////////////
    // Public functions
    /////////////////////////////
    function claimNft(address _nftAddress, uint256 _nftId) onlyClaimable public {
        // Check nft info
        CardInfo storage card = cards[_nftAddress][_nftId];
        require(card.amount > 0, "No card");

        // Reduce nft
        card.amount = card.amount.sub(1);

        // Transfer token to this contract
        _safeTransferFromERC20(acceptToken, msg.sender, address(this), card.price);

        // Transfer nft token
        _transferNft(_nftAddress, _nftId, card.nftType, msg.sender, 1);

        emit ClaimNFT(msg.sender, _nftAddress, _nftId, card.price);
    }

    //////////////////////////////
    // Utility functions
    /////////////////////////////
    function _transferNft(address _nftAddress, uint256 _nftId, uint256 _nftType, address _receiver,  uint256 _amount) internal {
        // 721 function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
        // 1155   function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
        if (_nftType == 721) {
            _transfer721(_nftAddress, _nftId, _receiver);
        } else if(_nftType == 1155) {
            _transfer1155(_nftAddress, _nftId, _receiver, _amount);
        } else {
            revert();
        }
    }

    function _transfer721(address _nftAddress, uint256 _nftId, address _receiver) internal {
        (bool success,) = _nftAddress.call(abi.encodeWithSelector(TRANSFER_FROM_SELECTOR_721, address(this), _receiver, _nftId));
        require(success, 'TRANSFER_721_FAILED');
    }

    function _transfer1155(address _nftAddress, uint256 _nftId, address _receiver, uint256 _amount) internal {
        (bool success,) = _nftAddress.call(abi.encodeWithSelector(TRANSFER_FROM_SELECTOR_1155, address(this), _receiver, _nftId, _amount, ""));
        require(success, 'TRANSFER_1155_FAILED');
    }


    function _safeTransferERC20(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR_20, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function _safeTransferFromERC20(address token, address from, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_FROM_SELECTOR_20, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');
    }

    //////////////////////////////
    // Implement onReceived function to receive NFT
    /////////////////////////////

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return CardDistributor.onERC721Received.selector;
    }

     function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns(bytes4) {
        return CardDistributor.onERC1155Received.selector;
    }

     function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns(bytes4) {
        return CardDistributor.onERC1155BatchReceived.selector;
    }

}