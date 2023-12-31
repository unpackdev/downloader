// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

/** INTERFACES */

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IAddressRegistry {
    function getDistributorContractAddress() external view returns (address);
    function getHandlerAddress() external view returns (address);
}

/** CONTRACT */

contract Treasury {

    /** GLOBAL PARAMS */

    address public addressRegistryAddress;
    IAddressRegistry addressRegistry;

    constructor(address addressRegistryAddress_) {
        _setAddressRegistry(addressRegistryAddress_);
    }

    /** MODIFIER */

    modifier canRequest() {
        require(msg.sender == addressRegistry.getDistributorContractAddress() || msg.sender == addressRegistry.getHandlerAddress(), "Only distributor or handler");
        _;
    }

    /** VIEW */

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getERC20Balance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /** AUTHORIZED */

    function sendETH(address _recipient, uint256 _amount) external canRequest {
        require((address(this)).balance >= _amount, "Insufficient balance");
        payable(_recipient).transfer(_amount);
    }

    function sendAllETH(address _recipient) external canRequest {
        payable(_recipient).transfer(getBalance());
    }

    function sendERC20(address _recipient, uint256 _amount, address _token) external canRequest {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Insufficient token balance");
        IERC20(_token).transfer(_recipient, _amount);
    }

    function sendAllERC20(address _recipient, address _token) external canRequest {
        IERC20(_token).transfer(_recipient, getERC20Balance(_token));
    }

    function updateAddressRegistry(address _registry) external {
        require(msg.sender == addressRegistry.getHandlerAddress(), "Only Handler");
        _setAddressRegistry(_registry);
    }

    /** INTERNAL */

    function _setAddressRegistry(address _registry) internal {
        addressRegistryAddress = _registry;
        addressRegistry = IAddressRegistry(addressRegistryAddress);
    }

    // Make contract able to recive ETH;
    receive() external payable {}

    fallback() external payable {}

    // Good luck!

}