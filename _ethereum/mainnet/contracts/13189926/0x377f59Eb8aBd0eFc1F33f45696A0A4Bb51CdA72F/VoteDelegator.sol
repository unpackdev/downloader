// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./YieldEscrow.sol";
import "./GovernanceToken.sol";

contract VoteDelegator {
    /// @notice Contract owner.
    address public owner;

    /// @notice Yield escrow contract address.
    address public yieldEscrow;

    /// @notice Governance token contract address.
    address public governanceToken;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @param _owner Owner account address.
     */
    function initialize(address _owner) external {
        require(yieldEscrow == address(0), "VoteDelegator::initialize: contract already initialized");
        yieldEscrow = msg.sender;
        address _governanceToken = YieldEscrow(yieldEscrow).governanceToken(); // gas optimisation
        governanceToken = _governanceToken;
        GovernanceToken(_governanceToken).delegate(_owner);
        owner = _owner;
    }

    /**
     * @notice Deposit governance token.
     * @param amount Deposit amount.
     */
    function deposit(uint256 amount) external onlyOwner {
        address account = owner;
        IERC20(governanceToken).transferFrom(account, address(this), amount);
        YieldEscrow(yieldEscrow).depositFromDelegator(account, amount);
    }

    /**
     * @notice Withdraw governance token.
     * @param amount Withdraw amount.
     */
    function withdraw(uint256 amount) external onlyOwner {
        address account = owner;
        YieldEscrow(yieldEscrow).withdrawFromDelegator(account, amount);
        IERC20(governanceToken).transfer(account, amount);
    }
}
