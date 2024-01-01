// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Owned.sol";
import "./IBitcoin.sol";
import "./DropBox.sol";

contract WrappedBitcoin is ERC20 {
    // =============================================================
    //                           ERRORS
    // =============================================================

    error DropBoxNotCreated(address owner);
    error DropBoxAlreadyExists(address owner);
    error DropBoxInsufficientBalance(address owner);
    error OwnerInsufficientBalance(address owner);

    // =============================================================
    //                           EVENTS
    // =============================================================

    event DropBoxCreated(address indexed owner);
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @dev The address of the underlying token.
    address private constant _UNDERLYING = address(0x853737186cb24D4152f979B9152F652b67F7e9b7);

    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice The mapping of drop boxes.
    mapping(address => address) public dropBoxes;

    // =============================================================
    //                           CONSTRUCTOR
    // =============================================================

    constructor() ERC20("Wrapped Bitcoin", "WBTC", 8) {}

    // =============================================================
    //                           FUNCTIONS
    // =============================================================

    /// @notice Creates a drop box for the caller.
    function createDropBox() public {
        if (dropBoxes[msg.sender] != address(0)) revert DropBoxAlreadyExists(msg.sender);

        dropBoxes[msg.sender] = address(new DropBox(address(this)));

        emit DropBoxCreated(msg.sender);
    }

    /// @notice Deposits tokens into the wrapper.
    /// @param amount The amount of tokens to deposit.
    function deposit(uint256 amount) public {
        address dropBox = dropBoxes[msg.sender];

        if (dropBox == address(0)) revert DropBoxNotCreated(msg.sender);
        if (IBitcoin(_UNDERLYING).balanceOf(dropBox) < amount) revert DropBoxInsufficientBalance(msg.sender);

        _mint(msg.sender, amount);
        DropBox(dropBox).collect(amount, IBitcoin(_UNDERLYING));

        emit Deposit(msg.sender, amount);
    }

    /// @notice Withdraws tokens from the wrapper.
    /// @param amount The amount of tokens to withdraw.
    function withdraw(uint256 amount) public {
        if (balanceOf[msg.sender] < amount) revert OwnerInsufficientBalance(msg.sender);

        _burn(msg.sender, amount);
        IBitcoin(_UNDERLYING).transfer(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Returns the underlying token.
    function underlying() public pure returns (address) {
        return _UNDERLYING;
    }
}
