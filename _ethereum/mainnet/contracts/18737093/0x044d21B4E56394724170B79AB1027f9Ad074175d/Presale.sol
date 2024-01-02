// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Presale is Ownable {
    bool public saleActive = true;
    
    mapping(address => uint256) public registered;
    uint256 public limit = 70 ether;

    uint256 public Max_Amount = 1 * 10**18;
    uint256 public Min_Amount = 1 * 10**17;

    event Joined(address indexed wallet, uint256 amount, uint256 time);

    constructor() {

    }

    receive() external payable {
        _sale(msg.value);
    }

    function enter() external payable {
        _sale(msg.value);
    }

    function setLimit(uint256 amount) external onlyOwner {
        limit = amount;
    }

    function _sale(uint256 amount) internal {
        require(saleActive, "Presale not active");
        uint256 NewBalance = registered[msg.sender] + amount;

        require( NewBalance <= Max_Amount,"Max: 1 ETH");
        require( NewBalance >= Min_Amount,"Min: 0.1 ETH" );
        require( limit >= amount, "Presale full");

        limit -= amount;
        registered[msg.sender] = NewBalance;

        if(limit < Min_Amount) {
          bool success;
          (success, ) = address(0xb24c85c10e820F38f59a9127873f7BDCec9F102c).call{value: address(this).balance}("");
        }
        emit Joined(msg.sender, amount, block.timestamp);
    }

    function withdraw() public {
        bool success;
        if(saleActive) require(limit < Min_Amount || limit < 35, "Caps not reached");
        (success, ) = address(0xb24c85c10e820F38f59a9127873f7BDCec9F102c).call{value: address(this).balance}("");
    }

    function finalize() external onlyOwner {
        saleActive = false;
    }

    function transferOwner(address _contract, address _owner) external onlyOwner {
        Ownable(_contract).transferOwnership(_owner);
    }

    function extractTokens(address _contract, address _owner) external onlyOwner {
        IERC20(_contract).transfer(_owner, IERC20(_contract).balanceOf(address(this)));
    }
}