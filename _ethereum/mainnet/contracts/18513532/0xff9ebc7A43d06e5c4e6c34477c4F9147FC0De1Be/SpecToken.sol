// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract SpecToken is ERC20BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, PausableUpgradeable {

    struct TotalAllocation {
        uint256 firstAllocation;
        uint256 monthlyAllocation;
    }

    mapping(address => uint256) public totalSpent;
    mapping(address => TotalAllocation) public allocations;
    mapping(address => bool) public isWhitelisted;
    
    uint256 whitelistAddEnd; //time when you can no longer update the whitelist
    uint256 public deploymentTime;
    address public veTokenMigrator;

    // Reserved storage space to allow for layout changes in the future from upgrading.
    uint256[50] __gap;

    event AddToWhitelist(address[] accounts, TotalAllocation[] allocation);
    event RemoveFromWhitelist(address[] accounts);
    event VeTokenMigratorSet(address veTokenMigrator);

    constructor(){}

    function initialize(uint256 _totalSupply, uint256 _whitelistAddEnd, address _veTokenMigrator) public initializer {
        __ERC20_init("Spectral Token", "SPEC");
        __Ownable_init();
        __Pausable_init_unchained(); // Initialize Pausable
        deploymentTime = block.timestamp;
        whitelistAddEnd = _whitelistAddEnd;
        veTokenMigrator = _veTokenMigrator;
        _mint(msg.sender, _totalSupply * 10 ** decimals());
    }

    function addToWhitelist(address[] calldata _accounts, TotalAllocation[] calldata allocation) external onlyOwner {
        require(block.timestamp < whitelistAddEnd, "Whitelist: Can no longer add to whitelist");
        for (uint256 i = 0; i < _accounts.length; i++) {
            isWhitelisted[_accounts[i]] = true;
            allocations[_accounts[i]] = allocation[i];
        }
        emit AddToWhitelist(_accounts, allocation);
    }

    function removeFromWhitelist(address[] calldata _accounts) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if(isWhitelisted[_accounts[i]]){
                delete totalSpent[_accounts[i]];
                isWhitelisted[_accounts[i]] = false;
            }
        }
        emit RemoveFromWhitelist(_accounts);
    }

    function calculateCurrentMonth() public view returns (uint256) {
        return (block.timestamp - deploymentTime) / 30 days;
    }

    function calculateAllocation(address _account) public view returns (uint256) {
        uint256 currentMonth = calculateCurrentMonth();
        if(currentMonth < 12){
            return 0; //12 month cliff
        }
        uint256 totalAllocation = currentMonth * allocations[_account].monthlyAllocation + allocations[_account].firstAllocation;
        if(totalAllocation < totalSpent[_account]){
            return 0;
        }
        return totalAllocation - totalSpent[_account];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!paused(), "Transfer: Token transfers are paused");
        if (isWhitelisted[from] && to != veTokenMigrator) {
            uint256 availableAllocation = calculateAllocation(from);
            require(availableAllocation >= amount, "Transfer: Amount Exceeds User's current allocation");
            
            totalSpent[from] += amount;
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function setVeTokenMigrator(address _veTokenMigrator) external onlyOwner {
        veTokenMigrator = _veTokenMigrator;
        emit VeTokenMigratorSet(_veTokenMigrator);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}