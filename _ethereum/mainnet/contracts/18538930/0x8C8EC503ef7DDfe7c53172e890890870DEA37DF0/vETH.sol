// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

import "./Address.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IWETH.sol";
import "./IvETH.sol";

/**
 * @title vETH
 * @author Riley - Two Brothers Crypto (riley@twobrotherscrypto.dev)
 * @notice Holds Ethereum on behalf of end users to be used in ToadSwap operations without subsequent approvals being required.
 * In essence, a privileged version of WETH9. Implements the WETH9 spec, but with extra functions.
 */
contract vETH is Ownable, IvETH {

    mapping(address => uint256) amounts;

    mapping(address => bool) fullApprovals;

    address public immutable WETH9;

    modifier onlyApproved {
        require(fullApprovals[msg.sender], "Not approved.");
        _;
    }

    constructor(address weth) {
        WETH9 = weth;
        
    }
    receive() external payable {
        // Attempt to reject contracts from sending ETH
        require(!Address.isContract(msg.sender), "Contracts cannot deposit to vETH via receive fallback.");
        amounts[msg.sender] += msg.value;
    }

    function balanceOf(address account) public view override returns (uint) {
        return amounts[account];
    }

    function deposit() external payable override {
        // Allow contracts to send ETH via this method, because if you're doing this you should know how to withdraw (and this technically fulfils the IWETH interface)
        amounts[msg.sender] += msg.value;
    }

    function withdraw(uint wad) public override {
        // Because of Solidity 0.8 SafeMath we can require then do an unchecked subtract
        require(amounts[msg.sender] >= wad, "Not enough balance to withdraw.");
        unchecked {
            amounts[msg.sender] -= wad;
        }
        // Use Address senders 
        Address.sendValue(payable(msg.sender), wad);
    }

    function convertFromWETH9(uint256 amount, address recipient) external override {
        bool resp = IERC20(WETH9).transferFrom(msg.sender, address(this), amount);
        require(resp, "Failed to transfer.");
        // Withdraw
        IWETH(WETH9).withdraw(amount);
        // Now add the correct amount to balance
        amounts[recipient] += amount;
    }

    function convertToWETH9(uint256 amount, address recipient) external override {
        // Subtract balance now
        require(amounts[msg.sender] >= amount, "Not enough balance to withdraw.");
        unchecked {
            amounts[msg.sender] -= amount;
        }
        // Deposit into WETH9
        IWETH(WETH9).deposit{value: amount}();
        // Send to recipient
        bool resp = IERC20(WETH9).transfer(recipient, amount);
        require(resp, "Failed to transfer.");
    }

    function addToFullApproval(address account) external override onlyOwner {
        fullApprovals[account] = true;
    }

    function removeFromFullApproval(address account) external override onlyOwner {
        fullApprovals[account] = false;
    }

    /**
     * Performs a WETH9->vETH conversion with pre-deposited WETH9
     * @param amount amount to convert 
     * @param recipient recipient to credit
     */
    function approvedConvertFromWETH9(uint256 amount, address recipient) external override onlyApproved {
        IERC20 w9 = IERC20(WETH9);
        require(w9.balanceOf(address(this)) >= amount, "Can't convert what we don't have.");
        IWETH(WETH9).withdraw(amount);
        amounts[recipient] += amount; 
    }
    /**
     * Performs a vETH->WETH9 conversion on behalf of a user. Approved contracts only.
     * @param user user to perform on behalf of
     * @param amount amount to convert
     * @param recipient recipient wallet to send to
     */
    function approvedConvertToWETH9(address user, uint256 amount, address recipient) external override onlyApproved {
        // Subtract balance now
        require(amounts[user] >= amount, "Not enough balance to withdraw.");
        unchecked {
            amounts[user] -= amount;
        }
        IWETH w9 = IWETH(WETH9);
        w9.deposit{value: amount}();
        bool resp = w9.transfer(recipient, amount);
        require(resp, "Failed to transfer.");

    }

    function approvedTransferFrom(address user, uint256 amount, address recipient) external override onlyApproved {
        require(amounts[user] >= amount, "Not enough balance to transfer.");
        unchecked {
            amounts[user] -= amount;
            amounts[recipient] += amount;
        }
    }

    function transfer(address to, uint value) public override {
        require(amounts[_msgSender()] >= value, "Not enough balance to transfer.");
        unchecked {
            amounts[_msgSender()] -= value;
            amounts[to] += value;
        }
    }

    /**
     * Performs a withdrawal on behalf of a user. Approved contracts only.
     * @param user user to perform on behalf of
     * @param amount amount to withdraw
     * @param recipient recipient wallet to send to
     */
    function approvedWithdraw(address user, uint256 amount, address recipient) external override onlyApproved {
         // Because of Solidity 0.8 SafeMath we can require then do an unchecked subtract
        require(amounts[user] >= amount, "Not enough balance to withdraw.");
        unchecked {
            amounts[user] -= amount;
        }
        // Use Address senders 
        Address.sendValue(payable(recipient), amount);
    }




}