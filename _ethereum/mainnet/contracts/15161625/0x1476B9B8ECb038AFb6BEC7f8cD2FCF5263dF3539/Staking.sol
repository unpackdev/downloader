// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

interface HopeToken is IERC20 {
    function mintHopeTokenForCopacabanaCasino(address to, uint256 amount) external;
}

contract Staking is IERC721Receiver, AccessControl, ReentrancyGuard, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public copeBearContractAddress;
    address public hopeTokenContractAddress;

    mapping(address => EnumerableSet.UintSet) private stakedTokens;
    mapping(address => mapping(uint256 => uint256)) public stakedTimestamps;

    EnumerableSet.AddressSet private stakers;

    uint256 rewardPerSecond = 798611111111111;
    uint256 stolenBearChance = 5;

    bool isActiveStake = true;
    bool isActiveUnstake = true;
    bool isActiveClaim = true;

    constructor(address _copeBearContractAddress, address _hopeTokenContractAddress) {
        copeBearContractAddress = _copeBearContractAddress;
        hopeTokenContractAddress = _hopeTokenContractAddress;
    }

    function stake(uint256[] calldata tokenIds) external nonReentrant {
        require(isActiveStake, 'Not active');
        require(tokenIds.length > 0, 'Must provide token IDs');

        bool neverStaked = stakedTokens[msg.sender].length() <= 0;

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(copeBearContractAddress).safeTransferFrom(msg.sender, address(this), tokenIds[i], '');
            stakedTokens[msg.sender].add(tokenIds[i]);
            stakedTimestamps[msg.sender][tokenIds[i]] = block.timestamp;
        }

        if (neverStaked) {
            stakers.add(msg.sender);
        }
    }

    function unstakeAndClaim(uint256[] calldata tokenIds) external nonReentrant {
        require(isActiveUnstake, 'Not active');
        require(stakers.length() > 0, 'Nothing staked');

        uint256 totalClaimAmount = 0;

        address[] memory stakersWithoutSender = new address[](stakers.length() - 1);

        bool useOffset = false;
        for (uint256 i; i < stakers.length(); i++) {
            if (stakers.at(i) == msg.sender) {
                useOffset = true;
                continue;
            }
            stakersWithoutSender[i - (useOffset ? 1 : 0)] = stakers.at(i);
        }

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(stakedTokens[msg.sender].contains(tokenId), 'Unstaking token that is now owned');

            address copeBearOwner = msg.sender;

            if (stakersWithoutSender.length > 0 && (uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                msg.sender,
                i,
                stakersWithoutSender.length,
                tokenId
            ))) & 0xFFFF) % stolenBearChance == 0) {
                uint256 newOwnerIndex = (uint256(keccak256(abi.encodePacked(
                    tx.origin,
                    blockhash(block.number - 1),
                    block.timestamp,
                    msg.sender,
                    i,
                    stakersWithoutSender.length,
                    tokenId
                ))) & 0xFFFF) % stakersWithoutSender.length;
                copeBearOwner = stakersWithoutSender[newOwnerIndex];
            }

            stakedTokens[msg.sender].remove(tokenId);
            IERC721(copeBearContractAddress).safeTransferFrom(address(this), copeBearOwner, tokenId, '');

            uint256 lastTimestamp = stakedTimestamps[msg.sender][tokenId];
            totalClaimAmount = totalClaimAmount + ((block.timestamp - lastTimestamp) * rewardPerSecond);
            stakedTimestamps[msg.sender][tokenId] = block.timestamp;
        }

        if (stakedTokens[msg.sender].length() <= 0) {
            stakers.remove(msg.sender);
        }

        HopeToken(hopeTokenContractAddress).mintHopeTokenForCopacabanaCasino(msg.sender, totalClaimAmount);
    }

    function claim() external nonReentrant {
        require(isActiveClaim, 'Not active');
        require(stakedTokens[msg.sender].length() > 0, "Nothing staked");

        uint256 totalClaimAmount = 0;

        for (uint256 i; i < stakedTokens[msg.sender].length(); i++) {
            uint256 tokenId = stakedTokens[msg.sender].at(i);
            uint256 lastTimestamp = stakedTimestamps[msg.sender][tokenId];
            totalClaimAmount = totalClaimAmount + ((block.timestamp - lastTimestamp) * rewardPerSecond);
            stakedTimestamps[msg.sender][tokenId] = block.timestamp;
        }

        HopeToken(hopeTokenContractAddress).mintHopeTokenForCopacabanaCasino(msg.sender, totalClaimAmount);
    }

    function staked(address stakerAddress) external view returns (uint256[] memory) {
        return stakedTokens[stakerAddress].values();
    }

    function rewards(address stakerAddress) external view returns (uint256) {
        uint256 totalClaimAmount = 0;

        for (uint256 i; i < stakedTokens[stakerAddress].length(); i++) {
            uint256 lastTimestamp = stakedTimestamps[stakerAddress][stakedTokens[stakerAddress].at(i)];
            totalClaimAmount = totalClaimAmount + ((block.timestamp - lastTimestamp) * rewardPerSecond);
        }

        return totalClaimAmount;
    }

    function setStolenBearChance(uint256 _stolenBearChance) external onlyOwner {
        stolenBearChance = _stolenBearChance;
    }

    function setIsActiveStake(bool _active) external onlyOwner {
        isActiveStake = _active;
    }

    function setIsActiveUnstake(bool _active) external onlyOwner {
        isActiveUnstake = _active;
    }

    function setIsActiveClaim(bool _active) external onlyOwner {
        isActiveClaim = _active;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
