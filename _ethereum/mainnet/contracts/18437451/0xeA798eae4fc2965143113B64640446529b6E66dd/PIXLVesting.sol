// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

interface IPIXL {
    function burn(uint256 amount) external;

    function transfer(address to, uint256 amount) external returns (bool);
}

contract PIXLVesting is UUPSUpgradeable, OwnableUpgradeable {

    IPIXL public token;

    uint public preseedPrice;
    uint public seedPrice;

    enum SeedPhase {
        PRESEED,
        SEED,
        ITS_OVER
    }

    SeedPhase public seedPhase;

    // vesting settings
    uint public publicUnlockTs;
    uint public devUnlockTs;

    // vesting durations
    uint public devVestingDuration;
    uint public publicVestingDuration;

    // public limits and reserves
    uint public preseedLimitPerAddress;
    uint public seedLimitPerAddress;
    uint public reservedForPreseed;
    uint public reservedForSeed;

    // dev vesting
    uint public devsVestedAmount;
    uint public releasedToDevs;

    // vesters info
    mapping(address => VestingInfo) public vested;
    mapping(address => bool) public allowlist;

    struct VestingInfo {
        uint vestedOnPreseedPhase;
        uint vestedOnSeedPhase;
        uint released;
    }

    function initialize(address tokenAddress) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        token = IPIXL(tokenAddress);

        preseedPrice = 0.0000046 ether;
        seedPrice = 0.0000061 ether;

        seedPhase = SeedPhase.PRESEED;

        publicUnlockTs = 100000000000000;
        devUnlockTs = 100000000000000;

        // 240 days
        publicVestingDuration = 240 * 24 * 3600;
        // 300 days
        devVestingDuration = 300 * 24 * 3600;

        preseedLimitPerAddress = 400_000 ether;
        seedLimitPerAddress = 65_000 ether;
        reservedForPreseed = 1_500_000 ether;
        reservedForSeed = 6_000_000 ether;

        devsVestedAmount = 3_000_000 ether;
    }

    function setPrice(uint _preseedPrice, uint _seedPrice) external onlyOwner {
        preseedPrice = _preseedPrice;
        seedPrice = _seedPrice;
    }

    function setAllowlist(address[] calldata accounts, bool value) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            allowlist[accounts[i]] = value;
        }
    }

    function togglePreseed() external onlyOwner {
        if (seedPhase == SeedPhase.PRESEED) {
            seedPhase = SeedPhase.SEED;
        }
    }

    function toggleSeed() external onlyOwner {
        if (seedPhase == SeedPhase.SEED) {
            seedPhase = SeedPhase.ITS_OVER;
        }
    }

    function unlock() external onlyOwner {
        require(block.timestamp < publicUnlockTs, "Already unlocked");
        require(seedPhase == SeedPhase.ITS_OVER, "Wrong state");

        publicUnlockTs = block.timestamp;
        devUnlockTs = block.timestamp + 6 * 30 * 24 * 3600;

        token.burn(reservedForPreseed + reservedForSeed);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {

    }

    // preseed
    function preseed(uint amountIntegral) external payable {
        require(allowlist[msg.sender], "Account is not allowed to participate");
        require(amountIntegral * preseedPrice == msg.value, "Wrong eth value");

        uint amount = amountIntegral * 1 ether;
        _preseed(msg.sender, amount);
    }

    function preseedManually(address to, uint amountIntegral) external onlyOwner {
        _preseed(to, amountIntegral * 1 ether);
    }

    function _preseed(address to, uint amount) internal {
        require(seedPhase == SeedPhase.PRESEED, "Vesting not possible rn");
        require(reservedForPreseed >= amount, "Not enough tokens");
        require(vested[to].vestedOnPreseedPhase + amount <= preseedLimitPerAddress, "Too much for this wallet");
        reservedForPreseed -= amount;
        vested[to].vestedOnPreseedPhase += amount;
    }

    // preseed
    function seed(uint amountIntegral) external payable {
        require(amountIntegral * seedPrice == msg.value, "Wrong eth value");
        uint amount = amountIntegral * 1 ether;

        require(seedPhase == SeedPhase.SEED, "seed is not possible rn");
        require(reservedForSeed >= amount, "Not enough tokens");
        require(vested[msg.sender].vestedOnSeedPhase + amount <= seedLimitPerAddress, "Too much for this wallet");
        reservedForSeed -= amount;
        vested[msg.sender].vestedOnSeedPhase += amount;
    }

    function releasablePublic(address to) public view returns (uint) {
        return _releasable(
            vested[to].vestedOnSeedPhase + vested[to].vestedOnPreseedPhase,
            vested[to].released,
            true,
            publicUnlockTs,
            publicVestingDuration
        );
    }

    function releasableDev() public view returns (uint) {
        return _releasable(
            devsVestedAmount,
            releasedToDevs,
            false,
            devUnlockTs,
            devVestingDuration
        );
    }

    function _releasable(
        uint vestedAmount,
        uint released,
        bool release20Percents,
        uint startTs,
        uint duration
    ) internal view returns (uint) {
        require(block.timestamp > startTs, "Too early");
        uint timeDiff = block.timestamp - startTs;
        if (timeDiff > duration) {
            timeDiff = duration;
        }
        if (release20Percents) {
            return vestedAmount * 2 / 10 + timeDiff * vestedAmount * 8 / 10 / duration - released;
        } else {
            return timeDiff * vestedAmount / duration - released;
        }
    }

    function release() external {
        require(block.timestamp >= publicUnlockTs, "Not releasable yet");

        uint releasable = releasablePublic(msg.sender);
        require(releasable > 0, "Nothing to release");

        vested[msg.sender].released += releasable;
        _release(msg.sender, releasable);
    }

    function releaseDevs(address to) external onlyOwner {
        require(block.timestamp >= devUnlockTs, "Not releasable yet");

        uint releasable = releasableDev();
        releasedToDevs += releasable;

        _release(to, releasable);
    }

    function _release(address to, uint amount) internal {
        require(seedPhase == SeedPhase.ITS_OVER, "Can't release while vesting is active");
        token.transfer(to, amount);
    }

    function withdraw(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}
