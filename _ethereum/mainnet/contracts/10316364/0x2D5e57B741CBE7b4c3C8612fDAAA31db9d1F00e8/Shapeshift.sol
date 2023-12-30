
// File: browser/common/IERC20.sol

// SPDX-License-Identifier: MIT

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
// File: browser/ShapeshiftVault.sol

/**
 *Submitted for verification at Etherscan.io on 2020-06-22
*/


pragma solidity ^0.6.0;

    
contract Shapeshift {
    address private owner;
    bytes32 private vaulthash;
    uint256 private unlockDate;
    event Initialized(uint256 _unlockDate);
    constructor() public {
        owner = msg.sender;
        unlockDate = now + 3 days;
        emit Initialized(unlockDate);
    }
    modifier onlyOwner(){
        require(owner == msg.sender,'unauthorized');
        _;
    }
    function setVault(bytes32 _hash) public onlyOwner {
        vaulthash = _hash;
    } 
    function message() public pure returns( string memory) {
        return "contact me on email@cryptoguard.pw to retrieve";
    }
    function message2() public pure returns( string memory) {
        return "i send an email to security@shapeshift.io but got no response";
    }
    function message3() public pure returns( string memory) {
        return "for safekeeping till time expires";
    }
    function withdraw(address payable _to) public onlyOwner{
        require(unlockDate < now);
        _to.transfer(address(this).balance);
    }
    function withdrawTokens(address _to, IERC20 _token) public onlyOwner{
        require(unlockDate < now);
        _token.transfer(_to, _token.balanceOf(address(this)));
    }
    function getHashOf(string memory _string) public pure returns(bytes32) {
        return keccak256(abi.encode(_string));
    }
    function retrieve(string memory password, address payable _to) public {
        bytes32 hash = keccak256(abi.encode(password));
        require(hash == vaulthash);
        _to.transfer(address(this).balance);
    }
    function retrieveTokens(string memory password, address _to, address _token) public {
        bytes32 hash = keccak256(abi.encode(password));
        require(hash == vaulthash);
        IERC20 token = IERC20(_token);
        uint256 amt = token.balanceOf(address(this));
        token.transfer(_to, amt);
    }
    
}