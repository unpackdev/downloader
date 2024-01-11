// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface iCryptoNerdz {
    function balanceOf(address owner) external view returns(uint256);
}

contract IQ is ERC20, Ownable {

    iCryptoNerdz public CryptoNerdz;

    uint256 constant public BASE_RATE = 5 ether;
    uint256 public immutable START;

    bool public rewardPaused = true;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    constructor(address cnAddress) ERC20("IQ Token", "IQ") {
        CryptoNerdz = iCryptoNerdz(cnAddress);
        START = block.timestamp - (7 days);
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(CryptoNerdz));

        if(from != address(0)) {
            rewards[from] += getPendingReward(from);
            lastUpdate[from] = block.timestamp;
        }

        if(to != address(0)) {
            rewards[to] += getPendingReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function claimReward() external {
        require(!rewardPaused, "ClaimingPaused"); 
        _mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender], "AddressCannotBurn");
        _burn(user, amount);
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        return CryptoNerdz.balanceOf(user) *BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400;
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }
}
