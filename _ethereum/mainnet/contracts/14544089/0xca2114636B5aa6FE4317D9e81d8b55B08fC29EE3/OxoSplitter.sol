// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "./Oxo.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

    /// @title 0x0.art NFT tokens owners royalities pool
    /// @author MV
    /// @notice Payments splitter contract. Get balance, release, release ERC-20 functions.

contract OxoSplitter is Context {
    Oxo oxoContract;

    event PaymentReleased(uint256 tokenId, address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, uint256 tokenId, address account, uint256 amount);


    uint256 private _totalShares;
    uint256 private _totalReleased;
    bool public canSetNftContract;
    address public nftContractAddress;


    mapping(uint256 => uint256) private _released;
    mapping(IERC20 => uint256) public _erc20TotalReleased;
    mapping(IERC20 => mapping(uint256 => uint256)) private _erc20Released;

    /// @notice set total tokens(shares) number and tokens contract address
    constructor(){
        _totalShares = 10000;
        canSetNftContract = true;
        
    }

    /// @notice The Ether received will be logged with {PaymentReceived} event.
    receive() external payable virtual {

    }

    /// @notice Getter for the total shares for all NFT tokens owners.
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

     /// @notice Getter for the total amount of Ether already released.
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }


    /// @notice Getter for the total amount of `token` already released. `token` should be the address of an IERC20 contract.
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /// @notice Getter for the amount of Ether already released to a NFT token owner.
    /// @param _tokenId Id of NFT token.
    function released(uint256 _tokenId) public view returns (uint256) {
        return _released[_tokenId];
    }

    /// @notice Getter for the amount of `token` tokens already released to a NFT token owner `token` should be the address of an IERC20 contract.
    /// @param token ERC20 token address.
    /// @param _tokenId Id of NFT token.
    function released(IERC20 token, uint256 _tokenId) public view returns (uint256) {
        return _erc20Released[token][_tokenId];
    }

    /// @notice Get balance by NFT token id.
    /// @param _tokenId Id of NFT token.
    function getBalance(uint256 _tokenId) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return totalReceived / _totalShares - released(_tokenId);
    }

    /// @notice Get balance of ERC20 by NFT token id.
    /// @param token ERC20 token address.
    /// @param _tokenId Id of NFT token.
     function getBalance(IERC20 token, uint256 _tokenId) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return totalReceived / _totalShares - released(token, _tokenId);
    }

    
    /// @notice Triggers a transfer to NFT token owner the amount of Ether they are owed, according to their percentage and their previous withdrawals.
    /// @notice Caller must be NFT owner.
    /// @param _tokenId Id of NFT token.
    function release(uint256 _tokenId) public virtual {
        
        require(oxoContract.ownerOf(_tokenId) == msg.sender, "The caller is not NFT token owner!");

        address account = payable(msg.sender);

        uint256 totalReceived = address(this).balance + totalReleased();

        uint256 payment = _pendingPayment(totalReceived, released(_tokenId));

        require(payment != 0, "account is not due payment");

        _released[_tokenId] += payment;
        _totalReleased += payment;

        Address.sendValue(payable(account), payment);
        emit PaymentReleased(_tokenId, account, payment);
    }

    /// @notice Triggers a transfer to NFT token owner the amount of ERC20 tokens they are owed, according to their percentage and their previous withdrawals.
    /// @notice Caller must be NFT owner.
    /// @param _tokenId Id of NFT token.
    function release(IERC20 token, uint256 _tokenId) public virtual {
        require(oxoContract.ownerOf(_tokenId) == msg.sender, "The caller is not NFT token owner!");

        address account = payable(msg.sender);

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(totalReceived, released(token, _tokenId));

        require(payment != 0, "account is not due payment");

        _erc20Released[token][_tokenId] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, _tokenId, account, payment);
    }

    function _pendingPayment(
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return totalReceived / _totalShares - alreadyReleased;
    }

    /// @notice Setter for NFT contract address
    function setNftContract(address _address) external{
        require(canSetNftContract, "Contract address could be set once!");
        oxoContract = Oxo(_address);
        nftContractAddress = _address;
        canSetNftContract = false;
    }
}