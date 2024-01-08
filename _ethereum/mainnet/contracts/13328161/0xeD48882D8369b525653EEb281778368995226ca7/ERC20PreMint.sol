pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./ERC20Pausable.sol";

/**
 * @title Token that can be pre-minted.
 * @dev Token is started in paused mode. Minting can be done until the contract is unpaused.
 **/
contract ERC20PreMint is ERC20, ERC20Pausable {

    bool private _minted;

    constructor() internal {
        _minted = false;
        pause();
    }

    /**
     * @return true if the tokens are pre-minted, false otherwise.
     */
    function minted() public view returns(bool) {
        return _minted;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotMinted() {
        require(!_minted);
        _;
    }

    /**
     * @dev Pre-mint tokens
     */
    function mint(address account, uint256 value) public onlyPauser whenNotMinted {
        _mint(account, value);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     * @dev when initially unpaused, the token can no longer be pre-minted.
     */
    function unpause() public onlyPauser whenPaused {
        _minted = true;
        super.unpause();
    }
}
