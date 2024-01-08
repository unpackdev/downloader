// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./SafeERC20.sol";

import "./BaseDistributor.sol";

contract MixDistributor is BaseDistributor {
    using SafeERC20 for IERC20;

    struct ReleaseInfo {
        uint256[] trancheStartTimestamps;
        uint256[] trancheEndTimestamps;
        uint32[] percentageOfTranches;
        TrancheType[] trancheTypes;
    }

    mapping(string => mapping(address => uint256)) claimedAmount;
    mapping(string => ReleaseInfo) releaseInfo;

    ITokenSale public tokenSale;

    constructor(ITokenSale _tokenSale) {
        tokenSale = _tokenSale;
    }

    function setReleaseInfo(
        string calldata _campaignID,
        uint256[] calldata _trancheStartTimestamps,
        uint256[] calldata _trancheEndTimestamps,
        uint32[] calldata _percentageOfTranches,
        TrancheType[] calldata _trancheTypes
    ) external override onlyOwner {
        ReleaseInfo storage info = releaseInfo[_campaignID];
        // require(
        //     info.trancheStartTimestamps.length == 0,
        //     "already set tranches"
        // );
        uint32 i;
        uint32 percentageSum = 0;
        require(
            (_trancheStartTimestamps.length == _percentageOfTranches.length) &&
                (_trancheStartTimestamps.length ==
                    _trancheEndTimestamps.length) &&
                (_trancheStartTimestamps.length == _trancheTypes.length),
            "number of timestamps must be equal to number of tranches"
        );
        for (i = 0; i < _percentageOfTranches.length; i++)
            percentageSum += _percentageOfTranches[i];
        require(
            percentageSum == 100,
            "total percentage of claiming token must be 100"
        );
        info.trancheStartTimestamps = _trancheStartTimestamps;
        info.trancheEndTimestamps = _trancheEndTimestamps;
        info.percentageOfTranches = _percentageOfTranches;
        info.trancheTypes = _trancheTypes;
        emit ReleaseInfoSet(
            _campaignID,
            _trancheStartTimestamps,
            _trancheEndTimestamps,
            _percentageOfTranches,
            _trancheTypes
        );
    }

    function getWithdrawableAmount(string calldata _campaignID, address _user)
        external
        view
        override
        returns (uint256)
    {
        return _getWithdrawableAmount(_campaignID, _user);
    }

    function getWithdrawedAmount(string calldata _campaignID, address _user)
        external
        view
        override
        returns (uint256)
    {
        return claimedAmount[_campaignID][_user];
    }

    function withdraw(string calldata _campaignID)
        external
        override
        nonReentrant
    {
        address _user = tx.origin;
        uint256 _amount = _getWithdrawableAmount(_campaignID, _user);
        ITokenSale.Campaign memory campaign = tokenSale.getCampaign(
            _campaignID
        );
        claimedAmount[_campaignID][_user] += _amount;
        _safeTransfer(campaign.token, _user, _amount);
        emit Withdraw(_user, _campaignID, _amount);
    }

    function _getWithdrawableAmount(string calldata _campaignID, address _user)
        internal
        view
        returns (uint256)
    {
        ReleaseInfo memory _info = releaseInfo[_campaignID];
        if (block.timestamp < _info.trancheStartTimestamps[0]) {
            return 0;
        }
        ITokenSale.UserInfo memory userInfo = tokenSale.getUserInfo(
            _campaignID,
            _user
        );
        uint256 totalClaimable = 0;
        for (uint32 i = 0; i < _info.trancheStartTimestamps.length; i++) {
            if (block.timestamp >= _info.trancheStartTimestamps[i]) {
                if (_info.trancheTypes[i] == TrancheType.ONCE) {
                    totalClaimable +=
                        (userInfo.allocation * _info.percentageOfTranches[i]) /
                        100;
                } else if (_info.trancheTypes[i] == TrancheType.LINEAR) {
                    uint256 timestamp = _min(
                        block.timestamp,
                        _info.trancheEndTimestamps[i]
                    );
                    totalClaimable +=
                        (((userInfo.allocation *
                            (timestamp - _info.trancheStartTimestamps[i])) /
                            (_info.trancheEndTimestamps[i] -
                                _info.trancheStartTimestamps[i])) *
                            _info.percentageOfTranches[i]) /
                        100;
                }
            }
        }

        return totalClaimable - claimedAmount[_campaignID][_user];
    }

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a < _b) return _a;
        return _b;
    }
}
