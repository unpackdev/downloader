pragma solidity ^0.8.0;

import "./ERC20Capped.sol";
import "./AccessControl.sol";
import "./ERC20Burnable.sol";

contract HmmCoin is ERC20Capped, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // @param initialSupply_ Initial supply of the contract that will be minted into owner's account
    // @param maxSupply_ Maximum possible tokens cap
    // @param owner Will be set as DEFAULT_ADMIN_ROLE, MINTER_ROLE and have the _initialSupply tokens
    constructor(string memory name_, string memory symbol_, address owner, uint256 initialSupply_, uint256 maxSupply_)
    ERC20(name_, symbol_) ERC20Capped(maxSupply_) {
        require(initialSupply_ <= maxSupply_, "HmmCoin: initial supply must be lower or equal max supply");
        require(owner != address(0), "HmmCoin: owner must be non-zero address");

        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);

        ERC20._mint(owner, initialSupply_);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "HmmCoin: must have minter role to mint");
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        ERC20Capped._mint(account, amount);
    }
}
