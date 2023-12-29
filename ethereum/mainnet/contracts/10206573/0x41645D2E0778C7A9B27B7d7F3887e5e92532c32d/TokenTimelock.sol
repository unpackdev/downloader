pragma solidity ^0.6.0;

contract Ownable {
    using SafeMath for *;
	address private _owner;
	address private nextOwner;

	constructor () internal {
		_owner = msg.sender;
	}

	modifier onlyOwner() {
		require(isOwner(), "Ownable: caller is not the owner");
		_;
	}

	function isOwner() public view returns (bool) {
		return msg.sender == _owner;
	}

	function approveNextOwner(address _nextOwner) external onlyOwner {
		require(_nextOwner != _owner, "Cannot approve current owner.");
		nextOwner = _nextOwner;
	}

	function acceptNextOwner() external {
		require(msg.sender == nextOwner, "Can only accept preapproved new owner.");
		_owner = nextOwner;
	}
}

contract TokenTimelock is Ownable{
    
    IERC20 private _token;

    address private _beneficiary;
    uint public publishTime;
    uint public transferWad;
    
     constructor (IERC20 token) public {
        _token = token;
    }
    
    bool load = true;
    
    function setConAddr(address beneficiary) external onlyOwner{
        require(load,"only once");
         _beneficiary = beneficiary;
         load = false;
    }
    
    function setToken(address token) external onlyOwner{
          _token = IERC20(token);
    }
    
    function conTransfer(address _addr,uint wad) external{
        require( msg.sender == _beneficiary,"invalid msg.sender");
        if(publishTime == 0){
            publishTime = now;
        }
        _token.transfer(_addr , wad);
    }
    
    function adminTransfer(uint wad) external onlyOwner{
        require(publishTime > 0);
        require(publishTime.add( 1 * 365 days) <= now,"TokenTimelock: current time is before release tim");
        if(publishTime.add( 2 * 365 days) <= now){
           require(transferWad.add(wad) <= 1000*10**10,"TokenTimelock: no tokens to release500");  
        }else if(publishTime.add( 1 * 365 days) <= now){
           require(transferWad.add(wad) <= 200*10**10,"TokenTimelock: no tokens to release200");  
        }
        _token.transfer(msg.sender , wad);
        transferWad = transferWad.add(wad);
    }
}

library SafeMath {

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "overflow");

		return c;
	}
}
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