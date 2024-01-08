//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";

import "./YoloInterfaces.sol";

/**
  ERC20 utility token.
 */

contract YoloChips is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    struct LandDeed {
        uint256 tokenId;
        uint256 yield;
    }

    event ChipsCashed(address indexed account, uint256 amount);
    
    bool public airdropped = false;
    uint256 public airdropOffset = 0;

    mapping (address => uint256) public accountRewards;
    mapping (address => uint256) public lastAccountUpdate;
    mapping (uint256 => uint256) public lastPropertyUpdate;

    mapping (address => bool) public marketplaces;

    uint256 public airdropAmount = 1000;
    uint256 public startTime = 1638316800; // Dec 01, 2021.
    uint256 public endTime = 1893456000; // Jan 01, 2030.

    IYoloDice public diceV1;
    IYoloBoardDeed public landDeeds;

    constructor(address _diceV1) ERC20("Yolo Chips", "CHIPS") {
        diceV1 = IYoloDice(_diceV1);
    }

    // Setters.

    function setAirdropAmount(uint256 _amount) external onlyOwner {
        airdropAmount = _amount;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    function setDiceV1(address _diceV1) external onlyOwner {
        diceV1 = IYoloDice(_diceV1);
    }

    function setLandDeeds(address _deeds) external onlyOwner {
        landDeeds = IYoloBoardDeed(_deeds);
    }

    function setMarketplace(address _address, bool _allowed) external onlyOwner {
        marketplaces[_address] = _allowed;
    }

    // Core functionality.

    /// @notice This issues initial rewards to V1 dice holders.
    /// It will reward holders from token _start (inclusive) to token _end (exclusive)
    function performAirdrop(uint256 _start, uint256 _end) external onlyOwner {
        require(!airdropped, "Yolo Chips: Airdrop already done");
        require(_start == airdropOffset, "Yolo Chips: Incorrect airdrop start index");

        // Iterate through all V1 dice.
        uint max = Math.min(_end, diceV1.totalSupply());
        for (uint256 tokenId = _start; tokenId < max; tokenId++) {
            address diceOwner = diceV1.ownerOf(tokenId);
            if (diceOwner != address(0x0)) {
                accountRewards[diceOwner] = accountRewards[diceOwner].add(airdropAmount);
            }
        }

        airdropOffset = max;

        // If we hit the end, mark the airdrop completed.
        if (max == diceV1.totalSupply()) {
            airdropped = true;
        }
    }

    /// @notice Called when property deed tokens are transferred.
    function updateOwnership(address _from, address _to) external {
        require(msg.sender == address(landDeeds), "Yolo Chips: Not allowed");

        // Update old and new owners before the transfer takes place.
        _updateRewards(_from);
        _updateRewards(_to);
    }

    /// @notice Shows current (including pending) rewards for an account.
    function getEarnedRewards(address _address) external view returns (uint256) {
        if (block.timestamp < startTime) {
            return accountRewards[_address];
        }

        LandDeed[] memory properties = _getProperties(_address);

        uint256 earned = 0;
        uint256 time = Math.min(block.timestamp, endTime);

        for (uint256 idx = 0; idx < properties.length; idx++) {
            uint256 lastUpdate = Math.max(lastPropertyUpdate[properties[idx].tokenId], startTime);

            if (lastUpdate > 0) {
                uint256 yield = (properties[idx].yield).mul((time.sub(lastUpdate))).div(86400);
                earned = earned.add(yield);
            }
        }

        return accountRewards[_address].add(earned);
    }

    function spend(address account, uint256 amount) external {
        require(marketplaces[msg.sender], "Yolo Chips: Not allowed to spend $CHIPS");
        _burn(account, amount);
    }

    /// @notice Withdraws balance and resets rewards.
    function cashOut() external {
        // First, ensure we're up to date.
        _updateRewards(msg.sender);

        uint256 reward = accountRewards[msg.sender];
        if (reward > 0) {
            accountRewards[msg.sender] = 0;

            _mint(msg.sender, reward.mul(1 ether));
            emit ChipsCashed(msg.sender, reward);
        }
    }

    // Helpers.

    /// @notice Updates a user's reward balance based on owned properties.
    function _updateRewards(address _address) internal {
        if (block.timestamp < startTime) {
            return;
        } 

        LandDeed[] memory properties = _getProperties(_address);

        uint256 earned = 0;
        uint256 time = Math.min(block.timestamp, endTime);

        for (uint256 idx = 0; idx < properties.length; idx++) {
            uint256 lastUpdate = Math.max(lastPropertyUpdate[properties[idx].tokenId], startTime);

            if (lastUpdate > 0) {
                uint256 yield = (properties[idx].yield).mul((time.sub(lastUpdate))).div(86400);
                earned = earned.add(yield);
            }
            if (lastUpdate != endTime) {
                lastPropertyUpdate[properties[idx].tokenId] = time;
            }
        }

        accountRewards[_address] = accountRewards[_address].add(earned);
        lastAccountUpdate[_address] = time;
    }

    /// @notice Returns Land Deeds owned by the address.
    function _getProperties(address _address) internal view returns (LandDeed[] memory) {
        uint balance = landDeeds.balanceOf(_address);

        LandDeed[] memory properties = new LandDeed[](balance);
        for (uint256 idx = 0; idx < balance; idx++) {
            uint256 tokenId = landDeeds.tokenOfOwnerByIndex(_address, idx);
            uint256 yield = landDeeds.yieldRate(tokenId);
            properties[idx] = LandDeed(tokenId, yield);
        }

        return properties;
    }

}
