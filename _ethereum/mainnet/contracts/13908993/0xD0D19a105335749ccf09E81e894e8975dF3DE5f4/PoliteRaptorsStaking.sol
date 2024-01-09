// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

interface IERC20Mintable is IERC20Upgradeable {
    function mint(address, uint256) external;
}

contract PoliteRaptorsStaking is OwnableUpgradeable, ERC721HolderUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    struct StakedRaptorInfo {
        uint16 lockMultiplier;
        uint256 stakeTimestamp;
        uint256 unlockTimestamp;
        bool exists;
    }

    IERC20Mintable public token;
    IERC721Upgradeable public raptors;

    uint256 public defaultMintPerDay;
    mapping(uint16 => uint16) public lockMultipliers;

    mapping(address => mapping(uint256 => StakedRaptorInfo)) public stakedRaptors;
    mapping(address => EnumerableSetUpgradeable.UintSet) internal stakedRaptorIds;
    mapping(address => uint256) public lastClaimTimestamps;

    function initialize(address tokenAddress, address raptorsAddress) public initializer {
        token = IERC20Mintable(tokenAddress);
        raptors = IERC721Upgradeable(raptorsAddress);
        defaultMintPerDay = 1 ether;

        //initializing
        OwnableUpgradeable.__Ownable_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();
    }

    // ------------------
    // Public functions
    // ------------------

    function stake(uint256[] memory raptorIds, uint16 lockDays) external {
        require(raptorIds.length <= 32, "PoliteRaptorsStaking: Max 32 in one tx");
        require(lockMultipliers[lockDays] > 0, "PoliteRaptorsStaking: Lock days not found");

        require(stakedRaptorIds[msg.sender].length() + raptorIds.length <= 255, "PoliteRaptorsStaking: Max 255 raptors per address");

        if (stakedRaptorIds[msg.sender].length() == 0) {
            lastClaimTimestamps[msg.sender] = block.timestamp;
        }

        for (uint8 i = 0; i < raptorIds.length; i++) {
            uint256 raptorId = raptorIds[i];

            raptors.safeTransferFrom(msg.sender, address(this), raptorId);

            stakedRaptors[msg.sender][raptorId] = StakedRaptorInfo({
                lockMultiplier: lockMultipliers[lockDays],
                unlockTimestamp: block.timestamp + lockDays * 1 days,
                stakeTimestamp: block.timestamp,
                exists: true
            });

            stakedRaptorIds[msg.sender].add(raptorId);
        }
    }

    function withdraw(uint256[] memory raptorIds) external {
        require(raptorIds.length <= 32, "PoliteRaptorsStaking: Max 32 in one tx");
        claimTokens();

        for (uint8 i = 0; i < raptorIds.length; i++) {
            uint256 raptorId = raptorIds[i];
            require(stakedRaptors[msg.sender][raptorId].exists, "PoliteRaptorsStaking: Not your raptor");

            require(block.timestamp > stakedRaptors[msg.sender][raptorId].unlockTimestamp, "PoliteRaptorsStaking: Raptor locked");

            stakedRaptors[msg.sender][raptorId] = StakedRaptorInfo({
                lockMultiplier: 0,
                unlockTimestamp: 0,
                stakeTimestamp: 0,
                exists: false
            });

            stakedRaptorIds[msg.sender].remove(raptorId);

            raptors.safeTransferFrom(address(this), msg.sender, raptorId);
        }
    }

    function claimTokens() public {
        uint256 numOfClaimableTokens = claimableTokens();
        lastClaimTimestamps[msg.sender] = block.timestamp;
        token.mint(msg.sender, numOfClaimableTokens);
    }

    // ------------------
    // View Functions
    // ------------------

    function claimableTokens() public view returns (uint256 numOfClaimableTokens) {
        for (uint8 i = 0; i < stakedRaptorIds[msg.sender].length(); i++) {
            StakedRaptorInfo memory raptor = stakedRaptors[msg.sender][stakedRaptorIds[msg.sender].at(i)];
                        uint256 thresholdTimestamp = lastClaimTimestamps[msg.sender] > raptor.stakeTimestamp
                ? lastClaimTimestamps[msg.sender]
                : raptor.stakeTimestamp;
            numOfClaimableTokens += ((block.timestamp - thresholdTimestamp) / 1 days) * defaultMintPerDay * (raptor.lockMultiplier / 100);
        }
    }

    function stakedRaptorsOf(address owner) public view returns (uint256[] memory raptorIds) {
        EnumerableSetUpgradeable.UintSet storage stakedRaptorIdsOfUser = stakedRaptorIds[owner];
        raptorIds = new uint256[](stakedRaptorIdsOfUser.length());

        for (uint8 i = 0; i < stakedRaptorIds[owner].length(); i++) {
            raptorIds[i] = stakedRaptorIds[owner].at(i);
        }
    }

    function numberOfStakedRaptors(address user) external view returns (uint256) {
        return stakedRaptorIds[user].length();
    }

    // ------------------
    // Owner functions
    // ------------------

    function setDefaultMintPerDay(uint256 amount) external onlyOwner {
        defaultMintPerDay = amount;
    }

    // multiplier in percentage from 100 (e.g. 170 for 70% on top)
    function setLockMultiplier(uint16 lockDays, uint16 multiplier) external onlyOwner {
        require(multiplier >= 100, "PoliteRaptorsStaking: Minimum multiplier = 100");
        lockMultipliers[lockDays] = multiplier;
    }

    function deleteLockMultiplier(uint16 lockDays) external onlyOwner {
        delete lockMultipliers[lockDays];
    }


}
