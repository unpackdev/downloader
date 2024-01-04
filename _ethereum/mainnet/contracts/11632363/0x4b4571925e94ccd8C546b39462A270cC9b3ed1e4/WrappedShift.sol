// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "./AccessControl.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Capped.sol";

contract WrappedShift is AccessControl, ERC20Capped, ERC20Pausable, ERC20Burnable {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant CAPPED_ROLE = keccak256("CAPPED_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bool public burningEnabled = false;

    /**
     * @dev Throws if burning is disabled set by the BURNER_ROLE.
     */
    modifier canBurn() {
        require(burningEnabled == true, "cannot burn tokens; burning disabled");
        _;
    }

    constructor (uint256 initialCap) public ERC20("Wrapped Shift", "wSHIFT") ERC20Capped(initialCap) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(CAPPED_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Updates the cap on the token's total supply.
     * - the caller must have the `CAPPED_ROLE`.
     * - the new cap must be greater than the previous
     */
    function setCap(uint256 _newCap) public {
        require(hasRole(CAPPED_ROLE, _msgSender()), "must have capped role to set cap");
        require(_newCap > cap(), "new cap must be > previous");
        _updateCap(_newCap);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev allows batch minting to support multible addresses & amounts
     * protected by the mint() method require statement
     */
    function multiMint(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "array lengths are not equal");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            mint(recipients[i], amounts[i]);
        }
    }

    /**
     * @dev Pauses all token transfers.
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to unpause");
        _unpause();
    }

    /**
     * @dev Enables burning of tokens
     * - the caller must have the `BURNER_ROLE`.
     */
    function enableBurn() public {
        require(hasRole(BURNER_ROLE, _msgSender()), "must have burner role to enable burn");
        burningEnabled = true;
    }

    /**
     * @dev Disables burning of tokens
     * - the caller must have the `BURNER_ROLE`.
     */
    function disableBurn() public {
        require(hasRole(BURNER_ROLE, _msgSender()), "must have burner role to disable burn");
        burningEnabled = false;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * Overidden from ERC20 contract
     * Changes:
     *     added modifier: canBurn
     */
    function _burn(address account, uint256 amount) internal override(ERC20) canBurn {
        super._burn(account, amount);
    }

    /**
     * @dev override _beforeTokenTransfer method in the hierachical chain: ERC20, ERC20Capped, ERC20Pausable
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Capped, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}