// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IHoody.sol";
import "./IHoodySign.sol";

interface IHoodyGang is IHoody {
    function transferFrom(address, address, uint256) external;

    function ownerOf(uint256) external view returns (address);

    function approve(address, uint256) external;
}

interface IHoodyCredit {
    function transfer(address, uint256) external returns (bool);

    function balanceOf(address) external returns (uint256);
}

contract HoodyGangStake is IHoody, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public rewardInterval = 1 days;
    mapping(address => EnumerableSet.UintSet) stakedNFTsByHolder;
    mapping(HoodyGangRarity => uint256) public rewardPointByRarity;
    mapping(uint256 => HoodyGangRarity) public stakedNFTsRarity;
    mapping(uint256 => uint256) public lastClaimedTime;

    address public hoodyGang;
    address public hoodyCredit;
    address public hoodySign;

    bool public rewardAvailable = true;

    event StakeNFT(address indexed holder, uint256 tokenID);
    event UnStakeNFT(address indexed holder, uint256 tokenID);
    event ResetTimer(uint256 tokenID, uint256 claimTime);

    constructor(address _hoodyGang, address _hoodyCredit) Ownable(msg.sender) {
        hoodyGang = _hoodyGang;
        hoodyCredit = _hoodyCredit;
    }

    function stake(
        uint256[] memory _tokenIds,
        HoodyGangRarity[] memory _rarities,
        bytes memory _signature
    ) external {
        require(
            IHoodySign(hoodySign).verifyForStake(
                msg.sender,
                _tokenIds,
                _rarities,
                _signature
            ),
            "Invalid Signature"
        );

        IHoodySign(hoodySign).increaseNonce(msg.sender);

        for (uint i; i < _tokenIds.length; i++) {
            require(
                IHoodyGang(hoodyGang).ownerOf(_tokenIds[i]) == msg.sender,
                "Not your token!"
            );
            stakedNFTsRarity[_tokenIds[i]] = _rarities[i];
            stakedNFTsByHolder[msg.sender].add(_tokenIds[i]);
            IHoodyGang(hoodyGang).approve(address(this), _tokenIds[i]);
            IHoodyGang(hoodyGang).transferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
            lastClaimedTime[_tokenIds[i]] = block.timestamp;

            emit StakeNFT(msg.sender, _tokenIds[i]);
        }
    }

    function unstake(uint256[] memory _tokenIds) external {
        claimCredit();
        for (uint i; i < _tokenIds.length; i++) {
            require(
                stakedNFTsByHolder[msg.sender].contains(_tokenIds[i]),
                "Not your token!"
            );
            stakedNFTsByHolder[msg.sender].remove(_tokenIds[i]);
            IHoodyGang(hoodyGang).transferFrom(
                address(this),
                msg.sender,
                _tokenIds[i]
            );

            emit UnStakeNFT(msg.sender, _tokenIds[i]);
        }
    }

    function calcTotalCreditsByHolder(
        address _holder
    ) public view returns (uint256) {
        uint256[] memory tokenIds = getStakeTokensByHolder(_holder);
        uint256 credit;
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (block.timestamp >= lastClaimedTime[tokenId] + rewardInterval) {
                credit +=
                    rewardPointByRarity[stakedNFTsRarity[tokenId]] *
                    ((block.timestamp - lastClaimedTime[tokenId]) /
                        rewardInterval);
            }
        }
        return credit;
    }

    function claimCredit() public {
        if (rewardAvailable) {
            uint256[] memory tokenIds = getStakeTokensByHolder(msg.sender);
            uint256 credit;
            for (uint256 i; i < tokenIds.length; i++) {
                uint256 tokenId = tokenIds[i];
                if (
                    block.timestamp >= lastClaimedTime[tokenId] + rewardInterval
                ) {
                    uint256 passed = (block.timestamp -
                        lastClaimedTime[tokenId]) / rewardInterval;
                    credit +=
                        rewardPointByRarity[stakedNFTsRarity[tokenId]] *
                        passed;
                    lastClaimedTime[tokenId] += passed * rewardInterval;
                }

                emit ResetTimer(tokenId, lastClaimedTime[tokenId]);
            }
            IHoodyCredit(hoodyCredit).transfer(msg.sender, credit);
        }
    }

    function getStakeTokensByHolder(
        address _holder
    ) public view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](
            stakedNFTsByHolder[_holder].length()
        );
        for (uint256 i; i < stakedNFTsByHolder[_holder].length(); i++) {
            tokenIds[i] = stakedNFTsByHolder[_holder].at(i);
        }
        return tokenIds;
    }

    function getLastClaimedTime(
        uint256[] memory _tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory claimTimes = new uint256[](_tokenIds.length);
        for (uint i; i < _tokenIds.length; i++) {
            claimTimes[i] = lastClaimedTime[_tokenIds[i]];
        }

        return claimTimes;
    }

    function setRewardPointByRarity(
        HoodyGangRarity[] memory _rarities,
        uint256[] memory _points
    ) external onlyOwner {
        require(_rarities.length == _points.length, "Invalid Params!");
        for (uint i; i < _rarities.length; i++) {
            rewardPointByRarity[_rarities[i]] = _points[i];
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = IHoodyCredit(hoodyCredit).balanceOf(address(this));
        IHoodyCredit(hoodyCredit).transfer(owner(), balance);
    }

    function closeStaking() external onlyOwner {
        rewardAvailable = false;
    }

    function setHoodySign(address _hoodySign) external onlyOwner {
        hoodySign = _hoodySign;
    }

    function setHoodyGang(address _hoodyGang) external onlyOwner {
        hoodyGang = _hoodyGang;
    }

    function setHoodyCredit(address _hoodyCredit) external onlyOwner {
        hoodyCredit = _hoodyCredit;
    }

    function setRewardInterval(uint256 _rewardInterval) external onlyOwner {
        rewardInterval = _rewardInterval;
    }
}
