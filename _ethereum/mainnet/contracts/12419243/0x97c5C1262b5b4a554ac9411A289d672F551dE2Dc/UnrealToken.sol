pragma solidity 0.6.2;

import "./ERC20.sol";
import "./Ownable.sol";

import "./ERC20Permit.sol";

/**
 * @title UnrealToken
 * @dev Unreal ERC20 Token
 */
contract UnrealToken is ERC20Permit, Ownable {
    constructor(uint256 totalSupply) public ERC20("Unreal Governance Token", "UGT") {
        _mint(msg.sender, totalSupply);
    }

    /**
     * @notice Function to rescue funds
     * Owner is assumed to be governance or UGT trusted party to helping users
     * Funtion cen be disabled by destroying ownership via `renounceOwnership` function
     * @param token Address of token to be rescued
     * @param destination User address
     * @param amount Amount of tokens
     */
    function rescueTokens(
        address token,
        address destination,
        uint256 amount
    ) external onlyOwner {
        require(token != destination, "Invalid address");
        require(ERC20(token).transfer(destination, amount), "Retrieve failed");
    }
}
