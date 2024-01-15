// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: research@pitch.foundation

import "./Ownable.sol";
import "./ERC20.sol";

contract Pitch is ERC20, Ownable {
    
    constructor() ERC20("Pitch Token", "PITCH") {}

    /**
     * @notice Mints new PITCH token to address.
     * @param _to Address to send newly minted PITCH.
     * @param _amount Amount of PITCH to mint.
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}