// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";


interface ICryptid {
    function ownerOf(uint id) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
}

interface IPowerup {
    function mintPowerup(address account) external;
    function burn(address _user, uint id, uint quantity) external;
}

interface IHoldingStorage {
    function getAccountStakedCount(address user) external view returns (uint256);
    function getAccountLastUpdate(address user) external view returns (uint256);
    function spendBounty(address _staker, uint256 _amount) external;
}

contract HoldingFacilityLogic is Ownable, ReentrancyGuard {
    bool private _paused = false;

    ICryptid public cryptid;
    IPowerup public powerup;
    IHoldingStorage public holdingStorage;

    mapping(address => bool) public managers;
    mapping(address => uint256) public yieldMod;


    uint public constant DAILY_YIELD_RATE = 15 ether;
    uint256 public powerupCost = 300 ether;

    // emergency rescue to allow unstaking without any checks but without $GGOLD
    bool public rescueEnabled = false;

//   ==== MODIFIERS ====

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

//   ==== Public Write Functions ====
 
    function usePowerup (uint8 id) public whenNotPaused nonReentrant {
        powerup.burn(msg.sender, id, 1);
        if (id == 1) {
            updateYieldMod(msg.sender, 10);
        }
        if (id == 2) {
            updateYieldMod(msg.sender, 30);
        }
        else {}
    }

    function purchasePowerup () public whenNotPaused nonReentrant {
        holdingStorage.spendBounty(msg.sender, powerupCost);
        powerup.mintPowerup(msg.sender);
        powerupCost = powerupCost + (powerupCost/100);
    }


//   ==== Public Read Functions ====

    function paused() public view virtual returns(bool) {
        return _paused;
    }
    
    function getPendingReward(address user) external view returns(uint256) {
        if (holdingStorage.getAccountStakedCount(user) == 0) {
            return 0;
        }
        else {
          uint256 pendingRewards = holdingStorage.getAccountStakedCount(user) * DAILY_YIELD_RATE * ((yieldMod[user] + 100) / 100) * (block.timestamp - holdingStorage.getAccountLastUpdate(user)) / 86400;
        return pendingRewards;  
        }
    }

    function getYieldMod(address _user) public view virtual returns(uint256) {
        return yieldMod[_user];
    }

//   ==== Internal Functions ====

    function updateYieldMod(address _account, uint256 _amount) internal { 
        require(yieldMod[_account] < 300, "Max yield modification already achieved");
        if(yieldMod[_account] + _amount >= 300) {
            yieldMod[_account] = 300;
        }
        else {
            yieldMod[_account] = yieldMod[_account] + _amount;
        }
    }    

//   ==== Admin Functions ====

    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    function setPaused(bool _state) external onlyOwner {
        _paused = _state;
    }

    function setCryptid(address _cryptid) external onlyOwner { 
        cryptid = ICryptid(_cryptid); 
    }

    function setPowerup(address _powerup) external onlyOwner {
        powerup = IPowerup(_powerup);
    }

    function setStorage(address _storage) external onlyOwner {
        holdingStorage = IHoldingStorage(_storage);
    }

}