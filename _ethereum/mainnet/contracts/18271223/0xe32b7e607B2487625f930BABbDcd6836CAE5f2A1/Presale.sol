// SPDX-License-Identifier: MIT

// File: node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/Presale.sol


// OpenZeppelin Contracts (last updated v4.9.0) (finance/VestingWallet.sol)

pragma solidity >=0.4.22 <0.9.0;


contract Presale {
	using SafeMath for uint256;

    address public admin;
    address public token;
    uint256 public tokenPrice = 0.000001 ether;

    modifier onlyAdmin {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor(address _token) {
        admin = msg.sender;
        token = _token;
    }

    function buyTokens() external payable {
        uint256 amount = toTokens(msg.value);
        require(amount <= inventory(), "No inventory");
        IERC20(token).transfer(msg.sender, amount);
    }

    function toTokens(uint256 _amountEther) public view returns (uint256) {
        return _amountEther.div(tokenPrice).mul(10**18);
    }

    function toEther(uint256 _amountToken) public view returns (uint256) {
        return _amountToken.mul(tokenPrice).div(10**18);
    }

    function inventory() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function proceeds() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawToken(uint256 _amount) external onlyAdmin {
        IERC20(token).transfer(admin, _amount);
    }

    function withdrawEther(uint256 _amount) external onlyAdmin {
        payable(admin).transfer(_amount);
    }

    function setAdmin(address _to) external onlyAdmin {
        admin = _to;
    }

    function setPrice(uint256 _to) external onlyAdmin {
        tokenPrice = _to;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}