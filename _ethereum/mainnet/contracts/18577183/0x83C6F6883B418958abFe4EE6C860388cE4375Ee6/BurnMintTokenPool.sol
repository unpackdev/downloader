// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IBurnMintERC20.sol";

/// @notice This pool mints and burns a 3rd-party token.
/// @dev The only way to change whitelisted caller (bridge) is to deploy a new pool.
/// If that is expected, please make sure the token's burner/minter roles are adjustable.
contract BurnMintTokenPool {
    IBurnMintERC20 public immutable token;
    address public immutable bridge;

    error Unauthorized(address);

    event Burned(address indexed sender, uint256 amount);
    event Minted(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    modifier onlyBridge() {
        if (msg.sender != bridge) revert Unauthorized(bridge);
        _;
    }

    constructor(
        IBurnMintERC20 _token,
        address _bridge
    ) {
        token = _token;
        bridge = _bridge;
    }

    /// @notice Burn the token in the pool
    /// @param amount Amount to burn
    function lockOrBurn(
        uint256 amount
    ) external onlyBridge {
        token.burn(amount);
        emit Burned(msg.sender, amount);
    }

    /// @notice Mint tokens from the pool to the recipient
    /// @param receiver Recipient address
    /// @param amount Amount to mint
    function releaseOrMint(
        address receiver,
        uint256 amount
    ) external onlyBridge {
        token.mint(receiver, amount);
        emit Minted(msg.sender, receiver, amount);
    }
}
