// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";


contract EggToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 internal constant CONTRACT_MANAGER_ = keccak256 ("CONTRACT_MANAGER_");

    constructor() ERC20("EggToken", "EGG") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_MANAGER_, msg.sender);
    }

    address public stakingContract;

    function setStakingContract(address _stakingContractAddress) public {
        require(hasRole(CONTRACT_MANAGER_, msg.sender) == true, "You are not a Contract Manager or above");
        stakingContract = _stakingContractAddress;
        _grantRole(CONTRACT_MANAGER_, _stakingContractAddress); //allows staking contract to call mint function
    }


    function pause() public onlyRole(CONTRACT_MANAGER_) {
        _pause();
    }

    function unpause() public onlyRole(CONTRACT_MANAGER_) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(CONTRACT_MANAGER_) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}