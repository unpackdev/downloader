// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: swapRouter.sol


pragma solidity 0.8.2;

contract SwapRouterContract {
    /// @dev OneInch Router Config
    address public oneInchRouter;

    /// @dev Lets a contract admin set the URI for the contract-level metadata.
    function setRouter(address _newRouter) public {
        oneInchRouter = _newRouter;
    }
    /*
    @notice Runs a swap from 1inch Aggregator and then perform a cross-chain swap
    @param _calldata it is provided by the Swap API as an API input from 1inch in the form of bytes
    */
    function _trade(address _fromToken, bytes memory _calldata, uint256 _amount) public {
        IERC20(_fromToken).transferFrom(msg.sender, address(this), _amount);
       
        IERC20(_fromToken).approve(oneInchRouter, _amount);
        (bool success, ) = address(oneInchRouter).call(_calldata);

        if (!success) {
            revert('SWAP_FAILED');
        }
    }
    /// @dev this function use to withdraw tokens that send to the contract mistakenly
    /// @param _token : Token address that is required to withdraw from contract.
    /// @param _amount : How much tokens need to withdraw.
    function emergencyWithdraw(IERC20 _token, uint256 _amount)
        external
        
    {
        IERC20(_token).transfer(msg.sender, _amount);
    }
    }