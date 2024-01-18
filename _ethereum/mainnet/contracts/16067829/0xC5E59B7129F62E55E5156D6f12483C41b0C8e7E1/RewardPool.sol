// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./ICurve.sol";
import "./Collectionswap.sol";
import "./ICollectionswap.sol";
import "./IERC721.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

contract RewardPool is Ownable {
    address nftAddress;
    address moneyAddress;
    address bondingCurveAddress;
    Collectionswap public collectionswap;
    uint96 fee;
    uint128 delta;
    uint128 initialSpotPrice;
    uint256 public totalContribution;

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private contributorsSet; // enumerable contributors

    mapping(address => uint256[]) public mapAddressToLPTokenIdList;
    mapping(uint256 => uint256) public mapLPTokenIdToReward;
    mapping(uint256 => bool) public mapLPTokenIdToIsLive;

    constructor(address _nftAddress, address _moneyAddress, address _bondingCurveAddress, address payable _collectionSwapAddress, uint96 _fee, uint128 _delta, uint128 _initialSpotPrice) {
        nftAddress = _nftAddress;
        moneyAddress = _moneyAddress;
        bondingCurveAddress = _bondingCurveAddress;
        collectionswap = Collectionswap(_collectionSwapAddress);
        fee = _fee;
        delta = _delta;
        initialSpotPrice = _initialSpotPrice;

        totalContribution = 0;
    }

    function getMyContribution(address thisAddress) public view returns (uint256) {
        uint256 contribution = 0;
        uint256[] memory lpTokenIdList = mapAddressToLPTokenIdList[thisAddress];
        for (uint256 i = 0; i < lpTokenIdList.length; i++) {
            uint256 lpTokenId = lpTokenIdList[i];
            contribution += mapLPTokenIdToReward[lpTokenId];
        }
        return contribution;
    }

    function getMyAndTotalContribution(address thisAddress) public view returns (uint256, uint256) {
        return (getMyContribution(thisAddress), totalContribution);
    }

    function recalcAllContributions() public {
        uint256 totalContributionNew = 0;

        for (uint256 i = 0; i < contributorsSet.length(); i++) {
            address contributor = contributorsSet.at(i);
            // recalcContributionByAddress(contributor);
            uint256[] memory lpTokenIdList = mapAddressToLPTokenIdList[contributor];
            for (uint256 j = 0; j < lpTokenIdList.length; j++) {
                uint256 lpTokenId = lpTokenIdList[j];
                collectionswap.refreshPoolParameters(lpTokenId);
                uint256 indivContribution = collectionswap.getMeasurableContribution(lpTokenId);
                mapLPTokenIdToReward[lpTokenId] = indivContribution;
                totalContributionNew += indivContribution;
            }
        }
        totalContribution = totalContributionNew;
    }

    // back up function - only callable by owner as there are potential fairness issues from not having a global state
    function recalcContributionByAddressByIndex(
        address contributor,
        uint lpStartIndex,
        uint lpEndIndex // max is mapAddressToLPTokenIdList[contributor].length
        ) public onlyOwner {
        uint256[] memory lpTokenIdList = mapAddressToLPTokenIdList[contributor];
        uint256 decrement;
        uint256 increment;

        require(lpEndIndex <= lpTokenIdList.length, "lpEndIndex out of range");

        for (uint256 j = lpStartIndex; j < lpEndIndex; j++) {
            uint256 lpTokenId = lpTokenIdList[j];
            uint256 prevContribution = mapLPTokenIdToReward[lpTokenId];
            collectionswap.refreshPoolParameters(lpTokenId);
            uint256 newContribution = collectionswap.getMeasurableContribution(lpTokenId);
            mapLPTokenIdToReward[lpTokenId] = newContribution;
            if (newContribution > prevContribution) {
                increment += (newContribution - prevContribution);
            } else {
                decrement += (prevContribution - newContribution);
            }
        }
        totalContribution = totalContribution + increment - decrement;
    }

    // back up function - only callable by owner as there are potential fairness issues from not having a global state
    function recalcContributionByAddress(
        address contributor
        ) public onlyOwner {
        recalcContributionByAddressByIndex(contributor, 0, mapAddressToLPTokenIdList[contributor].length);
    }


    function updateContributorExists(address contributorAddress) private {
        if (!contributorsSet.contains(contributorAddress)) {
            contributorsSet.add(contributorAddress);
        }
    }

    function removeContributor(address contributorAddress) private {
        if (contributorsSet.contains(contributorAddress)) {
            contributorsSet.remove(contributorAddress);
        }    
    }

    function deposit(
        uint256 lpTokenId
    ) public {
        require(collectionswap.ownerOf(lpTokenId) == msg.sender);

        require((collectionswap.validatePoolParamsLte(lpTokenId, nftAddress, bondingCurveAddress, fee, delta)), 'LPToken params do not match RewardPool params');

        // transfer token to reward pool
        bool isLive = mapLPTokenIdToIsLive[lpTokenId];
        require(!isLive, 'LPToken already deposited');

        collectionswap.transferFrom(msg.sender,address(this),lpTokenId);
        uint256 contribution = collectionswap.getMeasurableContribution(lpTokenId);

        mapLPTokenIdToIsLive[lpTokenId] = true;
        mapLPTokenIdToReward[lpTokenId] = contribution;
        updateContributorExists(msg.sender);
        totalContribution += contribution;
        mapAddressToLPTokenIdList[msg.sender].push(lpTokenId);

    }

    function withdrawAll(
        uint256[] calldata lpTokenIdList
    ) public {
        uint256 decrement = 0;

        for (uint256 i = 0; i < lpTokenIdList.length; i++) {
            uint256 lpTokenId = lpTokenIdList[i];
            require(mapLPTokenIdToIsLive[lpTokenId], 'LPToken not deposited');
            mapLPTokenIdToIsLive[lpTokenId] = false;
            decrement += mapLPTokenIdToReward[lpTokenId];
            mapLPTokenIdToReward[lpTokenId] = 0;
            collectionswap.transferFrom(address(this),msg.sender,lpTokenId);
        }

        require(decrement <= totalContribution, 'decrement > totalContribution');
        totalContribution -= decrement;

        uint256[] memory emptyList;
        mapAddressToLPTokenIdList[msg.sender] = emptyList;
        removeContributor(msg.sender);

    }
}