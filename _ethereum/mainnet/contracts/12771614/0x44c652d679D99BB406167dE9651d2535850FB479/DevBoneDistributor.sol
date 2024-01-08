// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./BoneLocker.sol";

contract DevBoneDistributor is Ownable {
    using SafeMath for uint256;

    IERC20 public bone;
    BoneLocker public boneLocker;
    address public devWallet;
    address public marketingAndGrowthWallet;

    uint256 public devSharePercent;
    uint256 public marketingAndGrowthSharePercent;

    event WalletUpdated(string wallet, address indexed user, address newAddr);
    event DistributionUpdated(uint devSharePercent, uint marketingAndGrowthSharePercent);

    constructor (
        IERC20 _bone,
        BoneLocker _boneLocker,
        address _devWallet,
        address _marketingAndGrowthWallet
    ) public {
        require(address(_bone) != address(0), "_bone is a zero address");
        require(address(_boneLocker) != address(0), "_boneLocker is a zero address");
        bone = _bone;
        boneLocker = _boneLocker;
        devWallet = _devWallet;
        marketingAndGrowthWallet = _marketingAndGrowthWallet;

        devSharePercent = 80;
        marketingAndGrowthSharePercent = 20;
    }

    function boneBalance() external view returns(uint) {
        return bone.balanceOf(address(this));
    }

    function setDevWallet(address _devWallet)  external onlyOwner {
        devWallet = _devWallet;
        emit WalletUpdated("Dev Wallet", msg.sender, _devWallet);
    }

    function setMarketingAndGrowthWallet(address _marketingAndGrowthWallet)  external onlyOwner {
        marketingAndGrowthWallet = _marketingAndGrowthWallet;
        emit WalletUpdated("Marketing and Growth Wallet", msg.sender, _marketingAndGrowthWallet);
    }

    function setWalletDistribution(uint _devSharePercent, uint _marketingAndGrowthSharePercent)  external onlyOwner {
        require(_devSharePercent.add(_marketingAndGrowthSharePercent) == 100, "distributor: Incorrect percentages");
        devSharePercent = _devSharePercent;
        marketingAndGrowthSharePercent = _marketingAndGrowthSharePercent;
        emit DistributionUpdated(_devSharePercent, _marketingAndGrowthSharePercent);
    }

    function distribute(uint256 _total) external onlyOwner {
        require(_total > 0, "No BONE to distribute");

        uint devWalletShare = _total.mul(devSharePercent).div(100);
        uint marketingAndGrowthWalletShare = _total.sub(devWalletShare);

        require(bone.transfer(devWallet, devWalletShare), "transfer: devWallet failed");
        require(bone.transfer(marketingAndGrowthWallet, marketingAndGrowthWalletShare), "transfer: marketingAndGrowthWallet failed");
    }

    // funtion to claim the locked tokens for devBoneDistributor, which will transfer the locked tokens for dev to devAddr after the devLockingPeriod
    function claimLockedTokens(uint256 r) external onlyOwner {

        boneLocker.claimAll(r);
    }
    // Update boneLocker address by the owner.
    function boneLockerUpdate(address _boneLocker) public onlyOwner {
        boneLocker = BoneLocker(_boneLocker);
    }
}
