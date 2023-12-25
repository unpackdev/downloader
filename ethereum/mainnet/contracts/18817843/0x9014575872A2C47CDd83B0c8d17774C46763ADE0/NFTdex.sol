// File: contracts/Ivivi.sol



pragma solidity ^0.8;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface Ivivi  {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    /**
    * @dev check the balance of the inscription
    */

    function tokenIdBalance(uint tokenId) external view returns(uint);
    /**
    * @dev approve tokenid inscription balance to the spender
    */

    function approveTokenIdToken(uint tokenId,address spender) external ;

    /**
    * @dev approve tokenid inscription balance to the spender by amount
    */
    function approvedByallowance(address spender,uint tokenId,uint amount) external ;
    /**
    * @dev check approve tokenid inscription balance to the spender by amount
    */  
    function tokenApprovedByallowance(address owner,address spender,uint tokenId,uint amount) external view returns(uint);
    /**
    * @dev revoke tokenid inscription balance to the spender
    */

    function revokeApproveTokenIdToken(uint tokenId,address spender) external ;

    /**
    * @dev transfer from fromTokenId to toTokenId by amount
    */

    function transferFromBalanceAmount(uint fromTokenId,uint toTokenId,uint amount) external ;

    /**
    * @dev transfer from fromTokenId to toTokenId by amount by owner
    */

    function transferBalanceAmount(uint fromTokenId,uint toTokenId,uint amount) external ;

    //function inscribe(uint _amount) external ;

    //call the inscription name
    
    function name() external view returns (string memory);
    /**
    * @dev locking the inscription amount
    */
    function lock(uint tokenId) external ;
    /**
    * @dev unlocked the inscription amount
    */

    function unLock(uint tokenId) external ;

    /**
    * @dev transfer tokenIdbalanceamount from fromId to toId by amount
    */

    function transferFromBalanceAmountByAllowance(uint fromTokenId,uint toTokenId,uint amount) external ;



    


}
// File: @openzeppelin/contracts@4.9.0/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts@4.9.0/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts@4.9.0/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/mpve.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;






contract NFTdex is IERC721Receiver,Ownable {

    event List(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price,
        uint pricePerToken
    );
    event Purchase(
        address indexed buyer,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price,
        uint pricePerToken
    );
    event Revoke(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId
    );
    event Update(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 newPrice,
        uint pricePerToken
    );
    event Points(
        address indexed buyer,
        uint indexed points
    );

    struct Order {
        address owner;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Order)) public nftList;
    mapping (address =>uint) public points;
    uint public totalPoints;

    constructor()  {}

    fallback() external payable {}
    receive() external payable { }

    uint FEE;
    address payable FUCKER;

    function setFee(uint _fee) public onlyOwner{
        FEE = _fee;
    }


    function setFUCKER(address payable _FUCKER)public onlyOwner{
        FUCKER = _FUCKER;
    }

    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        Ivivi _nft = Ivivi(_nftAddr); 

        require(_price > 0); 
        require( _nft.tokenIdBalance(_tokenId) > 0,"amount is 0");

        Order storage _order = nftList[_nftAddr][_tokenId]; 
        _order.owner = msg.sender;
        _order.price = _price;
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit List(msg.sender, _nftAddr, _tokenId, _price,_price/_nft.tokenIdBalance(_tokenId));
    }

    function purchase(address _nftAddr, uint256 _tokenId) public payable {
        Order storage _order = nftList[_nftAddr][_tokenId]; 
        require(_order.price > 0, "Invalid Price"); 
        require(msg.value >= _order.price, "Increase price"); 
        Ivivi _nft = Ivivi(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); 

        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        uint fee = _order.price * FEE/10000;
        FUCKER.transfer(fee);
        payable(_order.owner).transfer(_order.price - fee);
        payable(msg.sender).transfer(msg.value - _order.price);
        if(fee > 0){

            points[msg.sender] += fee;
            totalPoints += fee;
        }

        delete nftList[_nftAddr][_tokenId]; 

        emit Points(msg.sender, points[msg.sender]);
        emit Purchase(msg.sender, _nftAddr, _tokenId, _order.price,_order.price/_nft.tokenIdBalance(_tokenId));
    }

    function revoke(address _nftAddr, uint256 _tokenId) public {
        Order storage _order = nftList[_nftAddr][_tokenId]; 
        require(_order.owner == msg.sender, "Not Owner"); 
        Ivivi _nft = Ivivi(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); 

        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete nftList[_nftAddr][_tokenId]; 

        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    function update(
        address _nftAddr,
        uint256 _tokenId,
        uint256 _newPrice
    ) public {
        require(_newPrice > 0, "Invalid Price"); 
        Order storage _order = nftList[_nftAddr][_tokenId]; 
        require(_order.owner == msg.sender, "Not Owner"); 
        Ivivi _nft = Ivivi(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); 

        _order.price = _newPrice;

        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice,_newPrice/_nft.tokenIdBalance(_tokenId));
    }


    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function withdrawETH() public onlyOwner{
        address payable user = payable(msg.sender);
        user.transfer((address(this)).balance);
    }

    function withdrawETHwithAmount(uint amount) public onlyOwner{
        address payable user = payable(msg.sender);
        user.transfer(amount);
    }

}