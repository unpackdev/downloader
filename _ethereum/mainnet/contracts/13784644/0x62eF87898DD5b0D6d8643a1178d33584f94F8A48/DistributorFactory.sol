// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IDistributor.sol";
import "./IDistributorFactory.sol";
import "./ITokenSale.sol";
import "./MixDistributor.sol";
import "./Operators.sol";
import "./Ownable.sol";

contract DistributorFactory is Operators, IDistributorFactory {
    ITokenSalePool public tokenSalePool;

    constructor(ITokenSalePool _tokenSalePool) {
        tokenSalePool = _tokenSalePool;
    }

    mapping(string => IDistributor) distributors;

    function setTokenSalePool(ITokenSalePool _tokenSalePool)
        external
        override
        onlyOperator
    {
        tokenSalePool = _tokenSalePool;
    }

    function createDistributor(string calldata _poolID)
        public
        override
        onlyOperator
    {
        IDistributor distributor;

        distributor = new MixDistributor(
            ITokenSale(tokenSalePool.getTokenSaleContractAddress(_poolID))
        );

        distributors[_poolID] = distributor;
        tokenSalePool.setDistributor(_poolID, distributor);
    }

    function createDistributorWithReleaseInfo(
        string calldata _poolID,
        string[] calldata _campaignIDs,
        uint256[] calldata _trancheStartTimestamps,
        uint256[] calldata _trancheEndTimestamps,
        uint32[] calldata _percentageOfTranches,
        IDistributor.TrancheType[] calldata _trancheTypes
    ) external override onlyOperator {
        createDistributor(_poolID);
        setReleaseInfoSameInManyCampaigns(
            _poolID,
            _campaignIDs,
            _trancheStartTimestamps,
            _trancheEndTimestamps,
            _percentageOfTranches,
            _trancheTypes
        );
    }

    function emergencyWithdraw(
        string calldata _poolID,
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        distributors[_poolID].emergencyWithdraw(_token, _to, _amount);
    }

    function withdraw(string calldata _poolID, string calldata _campaignID)
        external
        override
    {
        distributors[_poolID].withdraw(_campaignID);
    }

    function withdrawManyCampaigns(
        string calldata _poolID,
        string[] calldata _campaignIDs
    ) external override {
        uint256 total = 0;
        for (uint32 i = 0; i < _campaignIDs.length; i++) {
            uint256 cWithdrawable = distributors[_poolID].getWithdrawableAmount(
                _campaignIDs[i],
                tx.origin
            );
            total += cWithdrawable;
            if (cWithdrawable > 0)
                distributors[_poolID].withdraw(_campaignIDs[i]);
        }
        if (total == 0) {
            revert("nothing to withdraw");
        }
    }

    function setReleaseInfo(
        string calldata _poolID,
        string calldata _campaignID,
        uint256[] calldata _trancheStartTimestamps,
        uint256[] calldata _trancheEndTimestamps,
        uint32[] calldata _percentageOfTranches,
        IDistributor.TrancheType[] calldata _trancheTypes
    ) public override onlyOperator {
        distributors[_poolID].setReleaseInfo(
            _campaignID,
            _trancheStartTimestamps,
            _trancheEndTimestamps,
            _percentageOfTranches,
            _trancheTypes
        );
    }

    function setReleaseInfoSameInManyCampaigns(
        string calldata _poolID,
        string[] calldata _campaignIDs,
        uint256[] calldata _trancheStartTimestamps,
        uint256[] calldata _trancheEndTimestamps,
        uint32[] calldata _percentageOfTranches,
        IDistributor.TrancheType[] calldata _trancheTypes
    ) public override onlyOperator {
        for (uint32 i = 0; i < _campaignIDs.length; i++) {
            setReleaseInfo(
                _poolID,
                _campaignIDs[i],
                _trancheStartTimestamps,
                _trancheEndTimestamps,
                _percentageOfTranches,
                _trancheTypes
            );
        }
    }

    function getWithdrawableAmount(
        string calldata _poolID,
        string calldata _campaignID,
        address _user
    ) external view override returns (uint256) {
        return distributors[_poolID].getWithdrawableAmount(_campaignID, _user);
    }

    function getWithdrawableAmountManyCampaigns(
        string calldata _poolID,
        string[] calldata _campaignIDs,
        address _user
    ) external view override returns (uint256) {
        uint256 withdrawable = 0;
        for (uint32 i = 0; i < _campaignIDs.length; i++) {
            withdrawable += distributors[_poolID].getWithdrawableAmount(
                _campaignIDs[i],
                _user
            );
        }
        return withdrawable;
    }

    function getWithdrawedAmount(
        string calldata _poolID,
        string calldata _campaignID,
        address _user
    ) external view override returns (uint256) {
        return distributors[_poolID].getWithdrawedAmount(_campaignID, _user);
    }

    function getWithdrawedAmountManyCampaigns(
        string calldata _poolID,
        string[] calldata _campaignIDs,
        address _user
    ) external view override returns (uint256) {
        uint256 withdrawed = 0;
        for (uint32 i = 0; i < _campaignIDs.length; i++) {
            withdrawed += distributors[_poolID].getWithdrawedAmount(
                _campaignIDs[i],
                _user
            );
        }
        return withdrawed;
    }

    function getDistributorAddress(string calldata _poolID)
        external
        view
        override
        returns (address)
    {
        return address(distributors[_poolID]);
    }
}
