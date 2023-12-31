// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Importing required contracts from OpenZeppelin library.
import "./ERC20.sol";
import "./Ownable.sol";

// Defining the custom token contract.
contract MonczkaContract is ERC20, Ownable {
    // Addresses for the reward and development pools.
    address public rewardPool;
    address public developmentPool;

    // Total totalSupply
    uint256 public totalSupplyAmount = 1000000;

    // Tax percentage on buy/sell transactions.
    uint256 public taxPercentage = 4;

    // Maximum amount for buy/sell transactions.
    uint256 public maxTxAmount = totalSupplyAmount * 2 / 100;

    // Constructor function to initialize the contract with required details.
    constructor(address _rewardPool, address _developmentPool) ERC20("Monczka Token", "MONT") {
        // Minting initial total supply to the contract deployer.
        _mint(msg.sender, totalSupplyAmount * 10 ** decimals());

        // Setting reward and development pool addresses.
        rewardPool = _rewardPool;
        developmentPool = _developmentPool;
    }

    // Overriding the ERC20 transfer function to include tax and maxTxAmount logic.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        // Ensuring the transfer amount doesn't exceed maxTxAmount.
        require(amount <= maxTxAmount, "Transfer amount exceeds maxTxAmount");

        // Calling the internal _transferTokens function to handle tax and transfer.
        _transferTokens(msg.sender, recipient, amount);

        return true;
    }

    // Overriding the ERC20 transferFrom function to include tax and maxTxAmount logic.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        // Ensuring the transfer amount doesn't exceed maxTxAmount.
        require(amount <= maxTxAmount, "Transfer amount exceeds maxTxAmount");

        // Calling the internal _transferTokens function to handle tax and transfer.
        _transferTokens(sender, recipient, amount);

        // Decreasing the allowance by the transfer amount.
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    // Internal function to handle tax deduction and token transfer.
    function _transferTokens(address sender, address recipient, uint256 amount) internal {
        // Calculating tax amount.
        uint256 taxAmount = calculateTax(amount);
        uint256 sendAmount = amount - taxAmount;

        // Transferring tax to the respective pools.
        super._transfer(sender, rewardPool, taxAmount / 2);
        super._transfer(sender, developmentPool, taxAmount / 2);

        // Transferring the remaining amount to the recipient.
        super._transfer(sender, recipient, sendAmount);
    }

    // Function to transfer tokens without tax and without a maxTxAmount limit
    function transferNoTax(address recipient, uint256 amount) public returns (bool) {
        // Using parent class's transfer function directly
        super._transfer(msg.sender, recipient, amount);
        return true;
    }

    // Function to transfer tokens from one address to another without tax and without a maxTxAmount limit
    function transferFromNoTax(address sender, address recipient, uint256 amount) public returns (bool) {
        // Ensure the transfer amount is allowed
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        // Directly using the parent class's transfer function
        super._transfer(sender, recipient, amount);

        // Decreasing the allowance by the transfer amount
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    // Function to calculate tax based on the tax percentage.
    function calculateTax(uint256 _amount) internal view returns (uint256) {
        return (_amount * taxPercentage) / 100;
    }

    // Function to update the tax percentage, only callable by the contract owner.
    function setTaxPercentage(uint256 _taxPercentage) public onlyOwner {
        taxPercentage = _taxPercentage;
    }

    // Function to update the maximum transaction amount, only callable by the contract owner.
    function setMaxTxAmount(uint256 _maxTxAmount) public onlyOwner {
        maxTxAmount = _maxTxAmount;
    }

    // Set new receiver address for rewardPool
    function setRewardPool(address newRewardPool) public onlyOwner {
        require(newRewardPool != address(0), "Invalid address");
        rewardPool = newRewardPool;
    }

    // Set new receiver address for developmentPool
    function setDevelopmentPool(address newDevelopmentPool) public onlyOwner {
        require(newDevelopmentPool != address(0), "Invalid address");
        developmentPool = newDevelopmentPool;
    }
}
