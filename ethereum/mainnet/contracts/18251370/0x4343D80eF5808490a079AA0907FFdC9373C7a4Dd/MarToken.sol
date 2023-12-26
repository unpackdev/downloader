// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC20Permit.sol";

contract MarToken is ERC20, Ownable, ERC20Permit {
    using SafeERC20 for IERC20;

    uint8 private _decimals;

    event Burn(address indexed from, uint256 value);
    event BulkTransferCompleted(
        address indexed token,
        address indexed sender,
        uint256 totalAmount
    );
    event TokensRecovered(
        address indexed tokenAddress,
        address indexed recipient,
        uint256 amount
    );

    // The constructor initializes the contract with necessary parameters.
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 decimalUnits,
        uint256 initialAmount,
        address custodianAddress
    ) ERC20(tokenName, tokenSymbol) ERC20Permit(tokenName) {
        _decimals = decimalUnits;
        /*
            _mint is an internal function within ERC20.sol, 
            invoked solely at this point and not intended
            for any future calls.
        */
        _mint(custodianAddress, initialAmount * 10 ** uint256(decimalUnits));
    }

    // Retrieves the decimal units of the token.
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // Retrieves the address of the current contract owner.
    function getOwner() external view returns (address) {
        return owner();
    }

    // Allows the token holder to burn a specified amount of their tokens, removing them from circulation.
    function burn(uint256 amount) public returns (bool) {
        require(
            amount <= balanceOf(msg.sender),
            "ERC20: burn amount exceeds balance"
        );

        _burn(msg.sender, amount);

        emit Burn(msg.sender, amount);

        return true;
    }

    /**
     * @dev Transfers tokens in bulk by aggregating them in the contract first.
     * Ensures atomicity of the bulk transfer.
     *
     * Requirements:
     *
     * - The number of recipients must be the same as the number of amounts.
     * - The caller must have a balance that is greater or equal to the sum of all amounts.
     * - Each recipient address must be non-zero.
     *
     * Emits a {BulkTransferCompleted} event upon successful transfer.
     *
     * @param recipients List of addresses to which the tokens will be transferred.
     * @param amounts List of amounts to transfer to respective recipients.
     */
    function bulkTransfer(
        address[] memory recipients,
        uint256[] memory amounts
    ) public {
        require(
            recipients.length == amounts.length,
            "The number of recipients should be equal to the number of amounts"
        );
        IERC20 token = IERC20(address(this));

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(
            token.balanceOf(msg.sender) >= totalAmount,
            "Insufficient balance for bulk transfer"
        );

        require(
            token.allowance(msg.sender, address(this)) >= totalAmount,
            "Contract not approved for the total transfer amount"
        );

        token.safeTransferFrom(msg.sender, address(this), totalAmount);

        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                recipients[i] != address(0),
                "Recipient address cannot be zero"
            );
            token.safeTransfer(recipients[i], amounts[i]);
        }

        emit BulkTransferCompleted(address(token), msg.sender, totalAmount);
    }

    // Receives ether sent to the contract.
    receive() external payable {
        revert("Contract cannot accept Ether");
    }

    // Allows the contract owner to recover tokens other than MAR tokens accidentally sent to the contract.
    function recoverTokens(
        address tokenAddress,
        address recipient
    ) external onlyOwner {
        require(tokenAddress != address(this), "Cannot recover MarToken");
        require(recipient != address(0), "Cannot send to zero address");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to recover");
        token.safeTransfer(recipient, balance);

        emit TokensRecovered(tokenAddress, recipient, balance);
    }
}
