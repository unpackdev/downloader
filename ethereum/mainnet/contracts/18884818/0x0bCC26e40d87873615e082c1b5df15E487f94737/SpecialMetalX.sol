// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC20.sol";
import "./Ownable.sol";

/**
 * @author BLOCKCHAINX
 * @title SpecialMetalX
 * @dev SMETX is an ERC-20 token contract with additional functionality.
 *
 * This contract represents the SpecialMetalX token (SMETX) and includes features such as token creation,
 * burning, transfers, allowances, and custodian control. It also integrates with the Ownable contract
 * and the IERC20 interface.
 */
contract SpecialMetalX is IERC20, Ownable {
    // State Variables
    string public name = "SpecialMetalX"; // Token name
    string public symbol = "SMETX"; // Token symbol
    uint8 public decimals = 18; // Number of decimal places
    uint256 private _totalSupply; // Total supply of tokens
    address public custodian = 0x66E2BB05bF2D74A4765E3fD54469F320b8DDA7a2; // Custodian address

    // Events
    event UpdateCustodian(address indexed custodian); // Event for update custodian address
    event WithdrawToken(address token, address to, uint256 amount); // Event for Withdraw token from contract
    event WithdrawNative(uint256 amount); // Event for native (ETH) withdrawal

    // Balances and allowances mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev Constructor to initialize the SpecialMetalX contract.
     *
     * Initializes the token contract with the specified initial supply, multiplying it by 10^decimals
     * to set the total supply. The total supply is assigned to the contract deployer (msg.sender).
     *
     * @param initialSupply The initial supply of tokens (in the smallest unit, accounting for decimals).
     *
     * Effects:
     * - Sets the total supply of tokens based on the provided initial supply.
     * - Assigns the total supply to the contract deployer's balance.
     * - Emits a `Transfer` event to log the tokens sent from the zero address to the contract deployer.
     */
    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply * 10 ** uint256(decimals);
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
     * @dev Get the total supply of tokens.
     *
     * This function returns the total supply of tokens in circulation.
     *
     * @return The total supply of tokens as a uint256 value.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Get the token balance of a specific account.
     *
     * This function returns the token balance of a specified account.
     *
     * @param account The address of the account for which to retrieve the balance.
     * @return The token balance of the specified account as a uint256 value.
     */
    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Transfer tokens to a specified address.
     *
     * This function allows the sender to transfer tokens to a specified recipient.
     *
     * @param to The recipient's address.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating whether the transfer was successful (true) or not (false).
     */

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Get the allowance for a spender to spend tokens on behalf of an owner.
     *
     * This function returns the allowance that has been approved by the owner for the spender
     * to spend tokens on their behalf.
     *
     * @param owner The address of the token owner.
     * @param spender The address of the spender.
     * @return The allowance for the specified spender as a uint256 value.
     */
    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Approve a spender to spend tokens on behalf of the sender.
     *
     * This function allows the sender to approve a specified address (spender) to spend a
     * specified amount of tokens on their behalf.
     *
     * @param spender The address to which approval is granted.
     * @param amount The amount of tokens to approve for spending.
     * @return A boolean indicating whether the approval was successful (true) or not (false).
     */
    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another using an allowance.
     *
     * This function allows a designated sender to transfer tokens from one address (`from`)
     * to another address (`to`) on behalf of the sender, as long as the allowance is sufficient.
     *
     * @param from The address from which tokens are transferred.
     * @param to The address to which tokens are transferred.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating whether the transfer was successful (true) or not (false).
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        _transfer(from, to, amount);
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(from, msg.sender, currentAllowance - amount);
        return true;
    }

    /**
     * @dev Increase the allowance for a spender.
     *
     * This function allows the sender to increase the allowance for a specified address (spender)
     * by a specified amount (addedValue).
     *
     * @param spender The address for which to increase the allowance.
     * @param addedValue The additional amount to add to the current allowance.
     * @return A boolean indicating whether the increase was successful (true) or not (false).
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Decrease the allowance for a spender.
     *
     * This function allows the sender to decrease the allowance for a specified address (spender)
     * by a specified amount (subtractedValue).
     *
     * @param spender The address for which to decrease the allowance.
     * @param subtractedValue The amount to subtract from the current allowance.
     * @return A boolean indicating whether the decrease was successful (true) or not (false).
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    /**
     * @dev Mints a specific amount of tokens and assigns them to an account.
     *
     * Creates new tokens by increasing the total token supply and adding the specified
     * amount to the balance of the designated account.
     *
     * @param account The address to which the minted tokens will be assigned.
     * @param amount The amount of tokens to mint.
     *
     * Requirements:
     * - Only the custodian address can mint tokens.
     * - The target account address must not be the zero address.
     *
     * Emits a `Transfer` event indicating the tokens minted to the target account.
     */
    function mint(address account, uint256 amount) external {
        require(msg.sender == custodian, "Only custodian can mint tokens");
        require(account != address(0), "Mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys a specific amount of tokens from the sender's balance.
     *
     * Burns tokens by deducting the specified amount from the sender's balance and
     * reducing the total token supply.
     *
     * @param amount The amount of tokens to burn.
     *
     * Requirements:
     * - The sender must have a balance of at least `amount`.
     * - Tokens once burnt are irrecoverably removed from circulation.
     *
     * Emits a `Transfer` event indicating the tokens burned.
     */
    function burn(uint256 amount) external {
        require(_balances[msg.sender] >= amount, "Burn amount exceeds balance");

        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev Internal function for transferring tokens from one address to another.
     *
     * Handles the transfer of tokens from one address (`from`) to another address (`to`),
     * updating the respective balances accordingly.
     *
     * @param from The sender's address.
     * @param to The recipient's address.
     * @param amount The amount of tokens to transfer.
     *
     * Requirements:
     * - Neither the `from` nor the `to` address can be the zero address.
     * - The `from` address must have a balance greater than or equal to the transfer amount.
     *
     * Effects:
     * - Deducts the transferred amount from the sender's balance.
     * - Updates the recipient's balance with the transferred amount.
     * - Emits a `Transfer` event to log the token transfer.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _balances[from] >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        // Deduct the transferred amount from the `from` balance.
        _balances[from] -= amount;

        // Update the balance of the `to` address with the final `amount`.
        _balances[to] += amount;

        // Emit a `Transfer` event to log the final token transfer.
        emit Transfer(from, to, amount);
    }

    /**
     * @dev Internal function to approve spending on behalf of an owner.
     *
     * This internal function allows an owner to approve another address (spender) to spend
     * a specified amount of tokens on their behalf. It checks that neither the owner nor the
     * spender addresses are the zero address and updates the allowances accordingly.
     *
     * @param owner The address that owns the tokens.
     * @param spender The address to which approval is granted.
     * @param amount The amount of tokens to approve for spending.
     *
     * Requirements:
     * - Neither the owner nor the spender address can be the zero address.
     *
     * Emits an `Approval` event to signal the approval of the spending allowance.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function updateCustodian(address _custodian) external onlyOwner {
        require(_custodian != address(0), "Address cant be zero address");
        custodian = _custodian;
        emit UpdateCustodian(_custodian);
    }

    /**
     * @dev Allows the owner to withdraw native cryptocurrency (e.g., ETH) from this contract.
     */
    function withdrawNative() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Allows the owner to withdraw ERC-20 tokens from this contract.
     * @param _tokenContract The address of the ERC-20 token contract.
     * @param _amount The amount of tokens to withdraw.
     * @notice The '_tokenContract' address should not be the zero address.
     */
    function withdrawToken(
        address _tokenContract,
        uint256 _amount
    ) external onlyOwner {
        require(_tokenContract != address(0), "Address cant be zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
        emit WithdrawToken(_tokenContract, msg.sender, _amount);
    }

    /**
     * @dev Fallback function to accept native currency (Ether).
     *
     * This function allows the contract to receive native currency (Ether) sent to it.
     * It's typically used for depositing Ether into the contract.
     *
     * Effects:
     * - Receives native currency (Ether) and stores it in the contract balance.
     * - No explicit actions are performed in this function.
     */
    receive() external payable {}
}
