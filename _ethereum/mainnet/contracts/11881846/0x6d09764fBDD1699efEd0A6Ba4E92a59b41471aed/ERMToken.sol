// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./Context.sol";

contract ERMToken is Context, Ownable, ERC20Pausable{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

constructor(uint256 initialSupply,string memory name_, string memory symbol_, uint8 decimal_) 
public 
ERC20(name_, symbol_)
Ownable() {
        _setupDecimals(decimal_);
        _mint(msg.sender, initialSupply * (10** uint256(decimal_)));
    }

    /**
     * @dev Pauses all token transfers.
     */
    function pause() public onlyOwner virtual {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() public onlyOwner virtual {
        _unpause();
    }

}
