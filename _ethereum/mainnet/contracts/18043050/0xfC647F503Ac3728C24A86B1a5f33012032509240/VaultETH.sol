// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Importing necessary contract from OpenZeppelin library
import "./Ownable.sol";

// This is a custom interface specific to USDT on ETH because it does not conform to the ERC20 standard (the function transferFrom does not return a Boolean).
interface IERC20 {
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
    function transfer(address to, uint256 amount) external;

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external;
}

/**
 * @title VaultETH
 * @dev This contract represents a vault on the Ethereum chain where users can deposit and withdraw
 * different types of tokens. The contract tracks the total deposits and individual token balances
 * for registered token types (USDT, USDC, and BUSD). The contract is controlled by an TimeLock contract
 *
 */
contract VaultETH is Ownable {
    struct Token {
        address token; // Address of the token contract
        uint256 totalDeposit; // Total amount of this token deposited
    }

    mapping(uint256 => Token) public tokenType;

    uint256 public totalDeposit;

    address payable public immutable receiver;

    address public immutable timeLock;

    uint256 public constant MAX_REGISTERED_TOKENS = 3;

    /**
     * @dev Modifier to ensure that only the timeLock contract can call certain functions.
     */
    modifier onlyTimelock() {
        require(msg.sender == timeLock, "Caller not TimeLock contract");
        _;
    }

    /**
     * @dev Event emitted when a deposit is made.
     * @param _caller The address of the depositor.
     * @param _amount The amount deposited.
     * @param _tokenType The type of token deposited (USDT, USDC, BUSD).
     * @param _date The timestamp of the deposit.
     */
    event Deposit(address indexed _caller, uint256 _amount, string _tokenType, uint256 _date);

    /**
     * @dev Constructor to initialize the VaultETH contract.
     * @param _token An array of addresses representing the token contracts for each registered token type.
     * @param _receiver The address that will receive withdrawal transfers.
     * @param _timeLock The address of the timeLock contract for managing the vault.
     */
    constructor(address[MAX_REGISTERED_TOKENS] memory _token, address payable _receiver, address _timeLock) {
        require(_receiver != address(0), "Zero address not allowed");
        receiver = _receiver;
        timeLock = _timeLock;
        for (uint i = 0; i < _token.length; i++) {
            tokenType[i].token = _token[i];
        }
    }

    /**
     * @dev Function to deposit funds of a specific token type.
     * @param _amount The amount of tokens to deposit.
     * @param _tokenType The type of token to deposit (0 for USDT, 1 for USDC, 2 for BUSD).
     */
    function deposit(uint256 _amount, uint256 _tokenType) public {
        require(_tokenType <= 2, "Invalid token type");
        string memory token = "";
        if (_tokenType == 0 || _tokenType == 1) {
            totalDeposit += _amount * 10 ** 12;
        } else {
            totalDeposit += _amount;
        }
        tokenType[_tokenType].totalDeposit += _amount;
        if (_tokenType == 0) {
            token = "USDT";
        } else if (_tokenType == 1) {
            token = "USDC";
        } else if (_tokenType == 2) {
            token = "BUSD";
        }
        IERC20(tokenType[_tokenType].token).transferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount, token, block.timestamp);
    }

    /**
     * @dev Function to withdraw funds from the vault (only callable by the timeLock contract).
     */
    function withdraw() public onlyTimelock {
        for (uint256 i = 0; i < MAX_REGISTERED_TOKENS; i++) {
            uint256 balance = IERC20(tokenType[i].token).balanceOf(address(this));
            if (balance > 0) {
                tokenType[i].totalDeposit -= balance;
                if (i == 0 || i == 1) {
                    totalDeposit -= balance * 1000000000000;
                } else {
                    totalDeposit -= balance;
                }
                IERC20(tokenType[i].token).transfer(receiver, balance);
            }
        }
    }
}
