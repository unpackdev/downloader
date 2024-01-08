//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.7;
import "./BaseAggregator.sol";

/// @title Rainbow swap aggregator contract
contract RainbowRouter is BaseAggregator {
    address public owner;

    constructor() {
        owner = msg.sender;
        status = 1;
    }

    /// @dev modifier that ensures only the owner is allowed to call a specific method
    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// @param newOwner address of the new owner
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ZERO_ADDRESS");
        owner = newOwner;
    }

    /// @dev method to withdraw ERC20 tokens (from the fees)
    /// @param token address of the token to withdraw
    /// @param to address that's receiving the tokens
    /// @param amount amount of tokens to withdraw
    function withdrawTokenFees(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        TransferHelper.safeTransfer(token, to, amount);
    }

    /// @dev method to withdraw ETH (from the fees)
    /// @param to address that's receiving the ETH
    /// @param amount amount of ETH to withdraw
    function withdrawEthFees(address to, uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(to, amount);
    }

    /// @dev method to approve other ERC20s
    // This is useful so we can manually preapprove top pairs
    // making future swaps consume less gas
    /// @param token address of the token to approve
    /// @param spender address that will be approved to spend the tokens
    /// @param amount allowance amount
    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external onlyOwner {
        TransferHelper.safeApprove(token, spender, amount);
    }

    receive() external payable {}
}
