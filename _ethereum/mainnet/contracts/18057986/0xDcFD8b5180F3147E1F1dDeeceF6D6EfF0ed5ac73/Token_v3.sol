// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

/**
 * @title Merkury.IT
 * @dev A standard ERC20 token contract with additional functionalities.
 * Uses OpenZeppelin's libraries for safer address handling, arithmetic operations, and secure ERC20 token transfers.
 */

// Import necessary OpenZeppelin contracts for token implementation
import "./ERC20Burnable.sol";							// Extension to add burning functionality to ERC20
import "./Pausable.sol";												// Contract that allows pausing and unpausing token transfers
import "./Ownable.sol";												// Contract that defines an owner with exclusive access rights
import "./SafeMath.sol";											// Utility library to perform arithmetic operations safely
import "./SafeERC20.sol";									// Utility library to safely handle ERC20 token transfers

/**
 * @dev The contract Merkury_IT is created by inheriting from multiple OpenZeppelin contracts.
 * The base contract ERC20 defines the standard functionality of an ERC20 token.
 * The contract ERC20Burnable provides additional functionality to burn tokens.
 * The contract Pausable allows the contract owner to pause and unpause token transfers.
 * The contract Ownable ensures that the contract has an exclusive owner with certain access rights.
 * The Address and SafeMath libraries are used to enhance address and arithmetic operations safety.
 * The SafeERC20 library is used to securely handle ERC20 token transfers.
 */
contract Merkury_IT is ERC20Burnable, Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    /**
     * @dev The constructor initializes the ERC20 token with the name "Merkury.IT" and symbol "MEK".
     * It also mints 500,000,000 tokens and assigns them to the contract itself (this contract's address).
     */
    constructor() ERC20("Merkury.IT", "MEK") {
        address tokenContractAddress = address(this);
        _mint(tokenContractAddress, 500000000 * 10 ** decimals());
    }

    /**
     * @dev Allows the contract owner to mint new tokens and assign them to the specified address.
     * @param to The address to which the minted tokens will be assigned.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Allows the contract owner to pause all token transfers.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Allows the contract owner to unpause token transfers.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Hook that is called before any token transfer, except for minting and burning.
     * It checks if the token transfers are allowed when the contract is not paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Fallback function to receive Ethereum (ETH) when someone sends it directly to the contract's address.
     * @notice The contract must not be in a paused state for the deposit to be successful.
     */
    receive() external payable whenNotPaused {
        emit EtherDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Function to deposit Ethereum (ETH) of sender into the contract.
     */
    function depositEther() external payable whenNotPaused {
        require(msg.value > 0, "Invalid amount");
		require(msg.value <= msg.sender.balance, "Insufficient Ethereum balance");
        emit EtherDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Function to deposit ERC20 tokens of sender into the contract. 
     * @param tokenAddress The address of the ERC20 token to deposit.
     * @param amount The amount of tokens to deposit.
	 * @notice Before calling this function, the sender must approve this contract to spend the specified amount of tokens.
     */
    function depositToken(address tokenAddress, uint256 amount) external whenNotPaused {
		require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Invalid amount");
        IERC20 token = IERC20(tokenAddress);
		uint256 balanceBefore = token.balanceOf(msg.sender);
		require(balanceBefore >= amount, "Insufficient token balance");
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit TokenDeposited(msg.sender, tokenAddress, amount);		
    }

    /**
     * @dev Function that allows the contract owner to transfer Ethereum (ETH) to a specified address.
     * @param to The address to which Ethereum will be transferred.
     * @param amount The amount of Ethereum to transfer.
     */
    function transferEther(address payable to, uint256 amount) external onlyOwner whenNotPaused {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(address(this).balance >= amount, "Insufficient contract balance");
        Address.sendValue(to, amount);																//  Use of safeTransferETH
        emit EtherTransferred(to, amount);
    }

    /**
     * @dev Function that allows the contract owner to transfer ERC20 tokens to a specified address.
     * @param tokenAddress The address of the ERC20 token to transfer.
     * @param to The address to which ERC20 tokens will be transferred.
     * @param amount The amount of ERC20 tokens to transfer.
     */
    function transferToken(address to, address tokenAddress, uint256 amount) external onlyOwner whenNotPaused {
        require(tokenAddress != address(0), "Invalid token address");
        require(to != address(0), "Invalid address");
		require(amount > 0, "Invalid amount");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
        token.safeTransfer(to, amount);																// Use SafeERC20 for token transfer
        emit TokenTransferred(to, tokenAddress, amount);
    }

    /**
     * @dev Function to withdraw Ethereum (ETH) from the contract balance, that can be called only by the contract owner.
     * @param amount The amount of Ethereum to withdraw.
     */
    function withdrawEther(uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Invalid amount");
		require(address(this).balance >= amount, "Insufficient contract balance");
        address payable ownerAddress = payable(msg.sender);
        ownerAddress.sendValue(amount);
        emit EtherWithdrawn(ownerAddress, amount);
    }

    /**
     * @dev Function to withdraw ERC20 tokens from the contract, that can be called only by the contract owner.
     * @param tokenAddress The address of the ERC20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawToken(address tokenAddress, uint256 amount) external onlyOwner whenNotPaused {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Invalid amount");
		IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Insufficient token balance");
        token.safeTransfer(msg.sender, amount);
        emit TokenWithdrawn(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Function to get the total balance of Ethereum (ETH) held by the contract.
     * @return The total balance of Ethereum held by the contract in wei.
     */
    function balanceEther() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Function to get the total balance of ERC20 tokens held by the contract.
     * @param tokenAddress The address of the ERC20 token to check the balance of.
     * @return The total balance of ERC20 tokens held by the contract.
     */
    function balanceToken(address tokenAddress) external view returns (uint256) {
        require(tokenAddress != address(0), "Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

    /**
     * @dev Event emitted when Ethereum (ETH) is deposited into the contract.
     * @param sender The address from which the Ethereum was deposited.
     * @param amount The amount of Ethereum that was deposited.
     */
    event EtherDeposited(address indexed sender, uint256 amount);

    /**
     * @dev Event emitted when tokens are deposited into the contract.
     * @param sender The address from which the tokens was deposited.
     * @param token The address of the ERC20 token that was deposited.
     * @param amount The amount of tokens that were deposited.
     */
    event TokenDeposited(address indexed sender, address indexed token, uint256 amount);

    /**
     * @dev Event emitted when Ethereum (ETH) is transferred from the contract to a specified address.
     * @param to The address to which Ethereum was transferred.
     * @param amount The amount of Ethereum that was transferred.
     */
    event EtherTransferred(address indexed to, uint256 amount);

    /**
     * @dev Event emitted when tokens are transferred from the contract to a specified address.
     * @param to The address to which tokens were transferred.
     * @param token The address of the ERC20 token that was transferred.
     * @param amount The amount of tokens that were transferred.
     */
    event TokenTransferred(address indexed to, address indexed token, uint256 amount);

    /**
     * @dev Event emitted when Ethereum (ETH) is withdrawn from the contract.
     * @param receiver The address to which Ethereum was withdrawn.
     * @param amount The amount of Ethereum that was withdrawn.
     */
    event EtherWithdrawn(address indexed receiver, uint256 amount);

    /**
     * @dev Event emitted when tokens are withdrawn from the contract.
     * @param receiver The address to which tokens were withdrawn.
     * @param token The address of the ERC20 token that was withdrawn.
     * @param amount The amount of tokens that were withdrawn.
     */
    event TokenWithdrawn(address indexed receiver, address indexed token, uint256 amount);

}
