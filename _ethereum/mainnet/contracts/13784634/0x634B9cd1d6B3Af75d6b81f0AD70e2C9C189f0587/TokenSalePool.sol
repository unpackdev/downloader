// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./ITokenSalePool.sol";
import "./IDistributor.sol";
import "./Operators.sol";
import "./TokenSale.sol";

contract TokenSalePool is ITokenSalePool, Operators {
    mapping(string => ITokenSalePool.Pool) public poolInfo;
    string[] public poolIds;

    mapping(string => bool) public poolExists;

    function createPool(
        string calldata _poolID,
        string calldata _poolName,
        uint256 _poolCreationTime
    ) external override onlyOperator {
        require(!poolExists[_poolID], "Pool ID already existed");
        IDistributor distributor;
        ITokenSale tokenSale = new TokenSale();

        poolInfo[_poolID] = Pool({
            poolID: _poolID,
            poolName: _poolName,
            poolCreationTime: _poolCreationTime,
            tokenSale: tokenSale,
            distributor: distributor
        });
        poolExists[_poolID] = true;
        poolIds.push(_poolID);
    }

    function setDistributor(string calldata _poolID, IDistributor _distributor)
        external
        override
        onlyOperator
    {
        poolInfo[_poolID].distributor = _distributor;
    }

    function setCampaign(
        string calldata _poolID,
        string calldata _campaignID,
        bytes32 _merkleRoot,
        uint64 _startTime,
        uint64 _endTime,
        uint256 _srcCap,
        uint256 _dstCap,
        IERC20 _acceptToken,
        IERC20 _token
    ) external override onlyOperator {
        return
            poolInfo[_poolID].tokenSale.setCampaign(
                _campaignID,
                _merkleRoot,
                _startTime,
                _endTime,
                _srcCap,
                _dstCap,
                _acceptToken,
                _token
            );
    }

    function setCampaignToken(
        string calldata _poolID,
        string calldata _campaignID,
        IERC20 _token
    ) external override onlyOperator {
        poolInfo[_poolID].tokenSale.setCampaignToken(_campaignID, _token);
    }

    function setCampaignTokenOfPool(string calldata _poolID, IERC20 _token)
        external
        override
        onlyOperator
    {
        string[] memory campaignIDs = getCampaignIds(_poolID);
        for (uint32 i = 0; i < campaignIDs.length; i++) {
            poolInfo[_poolID].tokenSale.setCampaignToken(
                campaignIDs[i],
                _token
            );
        }
    }

    function buy(
        string calldata _poolID,
        string calldata _campaignID,
        uint128 _index,
        uint256 _maxCap,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external payable override {
        poolInfo[_poolID].tokenSale.buy{value: msg.value}(
            _campaignID,
            _index,
            _maxCap,
            _amount,
            _merkleProof
        );
    }

    function withdrawSaleFund(
        string calldata _poolID,
        string calldata _campaignID,
        address _to
    ) external override onlyOwner {
        poolInfo[_poolID].tokenSale.withdrawSaleFund(_campaignID, _to);
    }

    function withdrawSaleFundOfPool(string calldata _poolID, address _to)
        external
        override
        onlyOwner
    {
        string[] memory campaignIDs = getCampaignIds(_poolID);
        for (uint32 i = 0; i < campaignIDs.length; i++) {
            poolInfo[_poolID].tokenSale.withdrawSaleFund(campaignIDs[i], _to);
        }
    }

    function emergencyWithdraw(
        string calldata _poolID,
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        poolInfo[_poolID].tokenSale.emergencyWithdraw(_token, _to, _amount);
    }

    function getUserInfo(
        string calldata _poolID,
        string calldata _campaignID,
        address _user
    ) external view override returns (ITokenSale.UserInfo memory) {
        return poolInfo[_poolID].tokenSale.getUserInfo(_campaignID, _user);
    }

    function getCampaign(string calldata _poolID, string calldata _campaignID)
        external
        view
        override
        returns (ITokenSale.Campaign memory)
    {
        return poolInfo[_poolID].tokenSale.getCampaign(_campaignID);
    }

    function getCampaignIds(string calldata _poolID)
        public
        view
        override
        returns (string[] memory)
    {
        return poolInfo[_poolID].tokenSale.getCampaignIds();
    }

    function getTokenSaleContractAddress(string calldata _poolID)
        external
        view
        override
        returns (address)
    {
        return address(poolInfo[_poolID].tokenSale);
    }

    function getDistributorAddress(string calldata _poolID)
        external
        view
        override
        returns (address)
    {
        return address(poolInfo[_poolID].distributor);
    }
}
