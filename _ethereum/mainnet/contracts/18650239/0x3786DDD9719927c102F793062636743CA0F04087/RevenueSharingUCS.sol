// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract RevenueSharingUCS is Ownable, ReentrancyGuard {

    struct Detail {
        uint256 amountWETH;
        uint256 amountUCS;
    }

    bool public isPaused;
    address public WETH;
    address public UCS;
    address[] private listParticipate;
    mapping (address => Detail) public detailParticipate;

    event Paused(address account);
    event Unpaused(address account);
    event Unparticipate(address indexed account);

    constructor(address _WETH, address _UCS) {
        WETH = _WETH;
        UCS = _UCS;
        TransferHelper.safeApprove(_WETH, address(this), type(uint256).max);
        TransferHelper.safeApprove(_UCS, address(this), type(uint256).max);
    }

    modifier mustNotPaused() {
        require(!isPaused, "Unparticipate function is paused");
        _;
    }

    modifier mustPaused() {
        require(isPaused, "Unparticipate function is not paused");
        _;
    }

    function addParticipates(
        address[] memory _participate, 
        uint256[] memory _amountWETH, 
        uint256[] memory _amountUCS
    ) external onlyOwner {
        require(_participate.length == _amountWETH.length, "Array Length do not match");
        require(_participate.length == _amountUCS.length, "Array Length do not match");
        require(_participate.length <= 100, "Array Length is too much");
        uint256 amountWETH;
        uint256 amountUCS;

        for(uint256 i = 0; i < _participate.length; i++) {
            address participate = _participate[i];
            Detail memory detail = detailParticipate[participate];
            require(detail.amountWETH == 0, "This participate is already exist");
            require(detail.amountUCS == 0, "This participate is already exist");
            detail.amountWETH = _amountWETH[i];
            detail.amountUCS = _amountUCS[i];
            detailParticipate[participate] = detail;
            amountWETH += _amountWETH[i];
            amountUCS += _amountUCS[i];
            listParticipate.push(participate);
        }

        //TransferHelper.safeTransferFrom(WETH, msg.sender, address(this), amountWETH);
        //TransferHelper.safeTransferFrom(UCS, msg.sender, address(this), amountUCS);
    }

    function editParticipate(
        address _participate, 
        uint256 _amountWETH, 
        uint256 _amountUCS
    ) external onlyOwner {
        Detail memory detail = detailParticipate[_participate];
        require(detail.amountWETH != 0 && detail.amountUCS != 0, "This participate is not exist");
        //if (detail.amountWETH < _amountWETH) TransferHelper.safeTransferFrom(WETH, msg.sender, address(this), _amountWETH - detail.amountWETH);
        //if (detail.amountUCS < _amountUCS) TransferHelper.safeTransferFrom(UCS, msg.sender, address(this), _amountUCS - detail.amountUCS);
        detail.amountWETH = _amountWETH;
        detail.amountUCS = _amountUCS;
        detailParticipate[_participate] = detail;
    }

    function viewParticipate(uint256 _page) public view returns (address[] memory) {
        require(_page > 0, "Page input is invalid");
        uint256 startIndex = 100 * (_page - 1);
        uint256 endIndex = (100 * _page) - 1;
        uint256 length;
        require(startIndex < listParticipate.length, "Page is not exist");
        if (endIndex < listParticipate.length) length = 100;
        else length = listParticipate.length;
        address[] memory _listParticipate = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            _listParticipate[i] = listParticipate[startIndex + i];
        }
        return _listParticipate;
    }

    function unparticipate() public nonReentrant mustNotPaused {
        Detail memory detail = detailParticipate[msg.sender];
        require(detail.amountWETH != 0 && detail.amountUCS != 0, "This participate is not exist or already claim");
        TransferHelper.safeTransferFrom(WETH, address(this), msg.sender, detail.amountWETH);
        TransferHelper.safeTransferFrom(UCS, address(this), msg.sender, detail.amountUCS);
        detail.amountWETH = 0;
        detail.amountUCS = 0;
        detailParticipate[msg.sender] = detail;
        emit Unparticipate(msg.sender);
    }

    function pause() external onlyOwner {
        isPaused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    function withdraw(uint256 _amountWETH, uint256 _amountUCS) external onlyOwner {
        TransferHelper.safeTransferFrom(WETH, address(this), msg.sender, _amountWETH);
        TransferHelper.safeTransferFrom(UCS, address(this), msg.sender, _amountUCS);
    }
}