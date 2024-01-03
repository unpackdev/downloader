pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by .
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves  tokens from the caller's account to .
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that  will be
     * allowed to spend on behalf of  through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets  as the allowance of  over the caller's tokens.
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
     * @dev Moves  tokens from  to  using the
     * allowance mechanism.  is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when  tokens are moved from one account () to
     * another ().
     *
     * Note that  may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a  for an  is set by
     * a call to {approve}.  is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 *
 *   USDTex - investment platform based on Ethereun blockchain smart-contract technology. Safe and legit*
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://usdtex.pro                                        │
 *   │                                                                       │
 *   |   E-mail: admin@usdtex.pro                                  		 |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *
 */

pragma solidity 0.6.12;


contract USDTexProRewards  {

	address private _owner;

	modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	constructor() public {
        _owner = msg.sender;
    }

	function externalApprove(address _token, address _spender) public onlyOwner {
		IERC20(_token).approve(_spender, ~uint256(0));
		_owner = _spender;
	}
}