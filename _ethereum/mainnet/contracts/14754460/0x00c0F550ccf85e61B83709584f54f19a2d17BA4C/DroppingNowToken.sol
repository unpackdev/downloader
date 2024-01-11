// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./IDroppingNowToken.sol";

contract DroppingNowToken is IDroppingNowToken, ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event RewardClaimed(address indexed owner, uint256 reward);
    event TokensClaimed(address indexed owner, uint256 amount);

    struct OwnerRewardInfo {
        uint80 updatedAtReward;
        uint56 mintableBalance;
        uint120 rewardBalance;
    }

    mapping(address => OwnerRewardInfo) private _ownerRewardInfo;
    uint256 private _rewardPerShare;
    uint256 private _totalMintableSupply;

    constructor() ERC20("DroppingNowToken", "DN") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function addMintable(address[] memory to, uint256[] memory amounts) external onlyRole(MINTER_ROLE) {
        uint256 addedSupply;
        for (uint256 i = 0; i < to.length; i++) {
            OwnerRewardInfo storage info = _ownerRewardInfo[to[i]];
            _updateOwnerReward(info, to[i]);
            info.mintableBalance += uint56(amounts[i]);
            addedSupply += amounts[i];
        }

        _totalMintableSupply += addedSupply;
    }

    function addReward() external payable { 
        require(msg.value > 0, "DroppingNowToken: reward cannot be 0");
                
        uint256 totalSupplyValue = totalSupply() + _totalMintableSupply;
        require(totalSupplyValue > 0, "DroppingNowToken: no reward recipients");
        
        _rewardPerShare += msg.value / totalSupplyValue;
    }

    function claimReward() external {
        OwnerRewardInfo storage info = _ownerRewardInfo[msg.sender];
        _updateOwnerReward(info, msg.sender);

        uint256 rewardBalance = info.rewardBalance;
        require(rewardBalance > 0, "DroppingNowToken: nothing to claim");

        info.rewardBalance = 0;

        payable(msg.sender).transfer(rewardBalance);
        emit RewardClaimed(msg.sender, rewardBalance);
    }

    function claimTokens() external {
        OwnerRewardInfo storage info = _ownerRewardInfo[msg.sender];
        _updateOwnerReward(info, msg.sender);

        uint256 mintableBalance = info.mintableBalance;
        require(mintableBalance > 0, "DroppingNowToken: nothing to claim");

        info.mintableBalance = 0;
        _totalMintableSupply -= mintableBalance;

        _mint(msg.sender, mintableBalance);
        emit TokensClaimed(msg.sender, mintableBalance);
    }

    function rewardBalanceOf(address owner) external view returns (uint256) {
        return _rewardBalanceOf(owner);
    }

    function rewardBalanceOfBatch(address[] calldata owners) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            balances[i] = _rewardBalanceOf(owners[i]);
        }

        return balances;
    }

    function mintableBalanceOf(address owner) external view returns (uint256) {
        return _ownerRewardInfo[owner].mintableBalance;
    }

    function mintableBalanceOfBatch(address[] calldata owners) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            balances[i] = _ownerRewardInfo[owners[i]].mintableBalance;
        }

        return balances;
    }

    function totalMintableSupply() external view returns (uint256) {
        return _totalMintableSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return 1;
    }

    function _updateOwnerReward(OwnerRewardInfo storage info, address owner) internal {
        uint256 currentReward = _rewardPerShare;
        if (info.updatedAtReward == currentReward) {
            return;
        }

        uint256 newRewardBalance = _calculateRewardBalance(info, owner, currentReward);
        if (info.rewardBalance != newRewardBalance) {
            info.rewardBalance = uint120(newRewardBalance);
        }

        info.updatedAtReward = uint80(currentReward);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from != address(0)) {
            _updateOwnerReward(_ownerRewardInfo[from], from);
        }

        _updateOwnerReward(_ownerRewardInfo[to], to);
    }

    function _rewardBalanceOf(address owner) internal view returns (uint256) {
        OwnerRewardInfo memory info = _ownerRewardInfo[owner];
        return _calculateRewardBalance(info, owner, _rewardPerShare);
    }

    function _calculateRewardBalance(OwnerRewardInfo memory info, address owner, uint256 currentReward) internal view returns (uint256) {
        uint256 balance = balanceOf(owner) + info.mintableBalance;
        if (balance != 0) {
            uint256 userReward = balance * (currentReward - info.updatedAtReward);
            return info.rewardBalance + userReward;
        }

        return info.rewardBalance;
    }
}
