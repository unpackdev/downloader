// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";

contract rfwsteth is ERC20, AccessControl {

    using SafeERC20 for ERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    uint256 public totalTokensDeposited;
    ERC20 public entryAsset;
    address public treasury;

    constructor(string memory name, string memory symbol, ERC20 _entryAsset) ERC20(name, symbol) {
        _setupRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE); 
        entryAsset = _entryAsset;
        treasury = address(0xa7C212DA5881eA88c9472F83dB94049f95B5472F);
    }

    modifier sync() {
        if (entryAsset.balanceOf(address(this)) > totalTokensDeposited) {
            uint256 _surplus = entryAsset.balanceOf(address(this)) - totalTokensDeposited;
            entryAsset.transfer(treasury, _surplus);
            emit status(entryAsset, _surplus, totalTokensDeposited);
            totalTokensDeposited += _surplus;
        }
        _;        
    }

    function mint(uint256 amount, address recipient) external sync() {
        entryAsset.safeTransferFrom(msg.sender,address(this),amount);
        totalTokensDeposited += amount;
        _mint(recipient, amount);
    }

    function burn(uint256 amount) external onlyRole(ADMIN_ROLE) sync(){
        _burn(_msgSender(), amount);
        totalTokensDeposited -= amount;
        entryAsset.transfer(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyRole(ADMIN_ROLE)sync() {
        require(allowance(account, _msgSender()) - amount >= 0, "burn amount exceeds allowance");
        uint256 newAllowance = allowance(account, _msgSender());
        _approve(account, _msgSender(), newAllowance);
        _burn(account, amount);
        totalTokensDeposited -= amount;
        entryAsset.transfer(msg.sender, amount);
    }
    event status(ERC20 indexed token , uint256 indexed surpluss, uint256 indexed total);
}