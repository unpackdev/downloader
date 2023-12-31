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

// File: contracts/BridgeSenderReceiver.sol


// OpenZeppelin Contracts (last updated v4.9.0) (finance/VestingWallet.sol)

pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;


contract BridgeSenderReceiver {
	using SafeMath for uint256;

    address public admin;
    address public token;

    //Deposit
    struct Deposit {
        uint256 depositAmount;
        address depositor;
    }

    //deposits
    Deposit[] public deposits;

    //nonce
    uint256 public nonce;

    modifier onlyAdmin {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor(address _token) {
        admin = msg.sender;
        token = _token;
    }

    function deposit(uint256 _amount) public {
        //deposit tokens
        IERC20(token).transferFrom(msg.sender, address(this), _amount);

        //log deposits
        deposits.push(Deposit(_amount, msg.sender));
    }

    function getBatch(uint256 _start) external view returns (Deposit[] memory) {
        //batch size
        uint256 size = deposits.length.sub(_start);     //e.g. 5

        //result
        Deposit[] memory result = new Deposit[](size);  //e.g. An (empty) Deposit[] with a length of 5

        //build result array
        uint256 d = _start;

        for (uint256 i = 0; i < result.length; i++) {
            result[i] = deposits[d];
            d++;
        }

        return result;
    }

    function resolve(Deposit[] calldata batch) external onlyAdmin {
        for (uint256 i = 0; i < batch.length; i++) {
            //params
            address _to     = batch[i].depositor;
            uint256 _amount = batch[i].depositAmount;
            
            //resolve
            IERC20(token).transfer(_to, _amount);
            nonce++;
        }
    }







    //admin functions (onlyAdmin)

    function withdraw(uint256 _amount) external onlyAdmin {
        IERC20(token).transfer(admin, _amount);
    }

    function setAdmin(address _to) external onlyAdmin {
        admin = _to;
    }

    //contract state (readonly)

    function balance() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
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