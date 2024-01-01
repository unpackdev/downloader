// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CerealTokenMigrator {
    address public immutable DRM_TOKEN_ADDRESS;
    address public immutable CEP_TOKEN_ADDRESS;
    address public treasury;
    address public owner;
    
    bool public halted;

    event TreasuryChanged(address indexed previousTreasury, address indexed newTreasury);
    event ContractHalted(address indexed halter);
    event ContractUnhalted(address indexed halter);
    event TokensMigrated(address indexed to, uint256 amountSwapped);

    
    error CEREALTokenMigrator_ImproperlyInitialized();
    error CEREALTokenMigrator_InvalidTreasury(address treasury);
    error CEREALTokenMigrator_OnlyOwner(address caller);
    error CEREALTokenMigrator_OnlyWhenNotHalted();
    error CEREALTokenMigrator_ZeroSwap();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        if (msg.sender != owner) revert CEREALTokenMigrator_OnlyOwner(msg.sender);
        _;
    }

    modifier onlyWhenNotHalted() {
        if (halted) revert CEREALTokenMigrator_OnlyWhenNotHalted();
        _;
    }

    constructor(address _drmTokenAddress, address _cepTokenAddress, address _treasury) {
        if (_drmTokenAddress == address(0) || _cepTokenAddress == address(0) ) {
            revert CEREALTokenMigrator_ImproperlyInitialized();
        }

        owner = msg.sender;
        halted = true;

        DRM_TOKEN_ADDRESS = _drmTokenAddress;
        CEP_TOKEN_ADDRESS = _cepTokenAddress;

        treasury = _treasury;
    }
    
    /* ========== TOKEN SWAPPING ========== */

    function migrateAllDRM() external onlyWhenNotHalted {
        uint256 amount = IERC20(DRM_TOKEN_ADDRESS).balanceOf(msg.sender);
        _migrateTokens(amount);
    }

    function migrateDRM(uint256 _amount) external onlyWhenNotHalted {
        _migrateTokens(_amount);
    }

    function _migrateTokens(uint256 _amount) internal {
        if (_amount == 0) revert CEREALTokenMigrator_ZeroSwap();

        // transfer user's BIT tokens to this contract
        IERC20(DRM_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), _amount);
        
        // transfer MNT tokens to user, if there are insufficient tokens, in the contract this will revert
        IERC20(CEP_TOKEN_ADDRESS).transfer(msg.sender, _amount);

        emit TokensMigrated(msg.sender, _amount);
    }

    /* ========== ADMIN UTILS ========== */

    function setTreasury(address _treasury) public onlyOwner {
        if (_treasury == address(0)) {
            revert CEREALTokenMigrator_InvalidTreasury(_treasury);
        }

        emit TreasuryChanged(treasury, _treasury);

        treasury = _treasury;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    function haltContract() public onlyOwner {
        halted = true;

        emit ContractHalted(msg.sender);
    }

    function unhaltContract() public onlyOwner {
        halted = false;

        emit ContractUnhalted(msg.sender);
    }

    function withdrawDrmTokens() external onlyOwner {
        uint256 balance = IERC20(DRM_TOKEN_ADDRESS).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        IERC20(DRM_TOKEN_ADDRESS).transfer(treasury, balance);
    }

    function withdrawCepTokens() external onlyOwner {
        uint256 balance = IERC20(CEP_TOKEN_ADDRESS).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        IERC20(CEP_TOKEN_ADDRESS).transfer(treasury, balance);
    }

}