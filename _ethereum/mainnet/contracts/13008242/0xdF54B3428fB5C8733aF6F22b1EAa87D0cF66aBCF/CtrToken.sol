// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract CtrToken is Ownable, ERC20Burnable {
    uint256 public constant MAX_TOTAL_SUPPLY = 150 * 10**(6 + 18);
    mapping(address => bool) adminList;

    constructor(address wallet) Ownable() ERC20("Creator Chain","CTR") {
        _mint(wallet, MAX_TOTAL_SUPPLY);
        adminList[wallet] = true;
        transferOwnership(wallet);
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmins() {
        require(adminList[msg.sender], "Only Admins");
        _;
    }

    /**
     * @dev Set `account` as admin of contract
     */
    function setAdmin(address account, bool value) external onlyOwner {
        adminList[account] = value;
    }

    /**
     * @dev Check `account` is in `adminList` or not
     */
    function isAdmin(address account) public view returns (bool) {
        return adminList[account];
    }

    /**
     * @dev Creates amount tokens and assigns them to account, increasing
     * the total supply.
     *
     * Requirements
     *
     * - account cannot be the zero address.
     */
    function mint(address account, uint256 amount) external onlyAdmins {
        require((ERC20.totalSupply() + amount) <= MAX_TOTAL_SUPPLY, "ERC20: mint amount exceeds MAX_TOTAL_SUPPLY");
        _mint(account, amount);
    }
}
