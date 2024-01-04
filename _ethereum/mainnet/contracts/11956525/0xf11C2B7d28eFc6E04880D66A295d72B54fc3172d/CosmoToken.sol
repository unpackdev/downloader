// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./AccessControl.sol";
import "./CosmoTokenERC20.sol";

/**
 * CosmoToken Contract
 * https://CosmoFund.space/
 * @dev {ERC20} token, including:
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a minting to
 *  - a minting to fond
 *  - project URL
 */
contract CosmoToken is CosmoTokenERC20, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address private _fond;


    constructor() public CosmoTokenERC20("Cosmo Token", "COSMO") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setURL("https://CosmoFund.space/");
    }

    function fond() public view returns (address) {
        return _fond;
    }

    function mint(address to, uint256 amount) public onlyMinter returns (bool) {
        _mint(to, amount);
        return true;
    }

    function mintToFond(uint256 amount) public onlyMinter returns (bool) {
        _mint(_fond, amount);
        return true;
    }

    function setFond(address account) public onlyAdmin {
        require(account != address(0), "CosmoToken: new fond is the zero address");
        _fond = account;
    }

    function addMinter(address account) public onlyAdmin {
        _setupRole(MINTER_ROLE, account);
    }

    function delMinter(address account) public {
        revokeRole(MINTER_ROLE,  account);
    }

    function setURL(string memory newUrl) public onlyAdmin {
        _setURL(newUrl);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "AccessControl: must have admin role");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "AccessControl: must have minter role");
        _;
    }
}
