// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ITokenSale.sol";
import "./IDistributor.sol";

interface ITokenSalePool {
    struct Pool {
        string poolID;
        string poolName;
        uint256 poolCreationTime;
        ITokenSale tokenSale;
        IDistributor distributor;
    }

    function createPool(
        string calldata _poolID,
        string calldata _poolName,
        uint256 _poolCreationTime
    ) external;

    function setDistributor(string calldata _poolID, IDistributor _distributor)
        external;

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
    ) external;

    function setCampaignToken(
        string calldata _poolID,
        string calldata _campaignID,
        IERC20 _token
    ) external;

    function setCampaignTokenOfPool(string calldata _poolID, IERC20 _token)
        external;

    function buy(
        string calldata _poolID,
        string calldata _campaignID,
        uint128 _index,
        uint256 _maxCap,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external payable;

    function withdrawSaleFund(
        string calldata _poolID,
        string calldata _campaignID,
        address _to
    ) external;

    function withdrawSaleFundOfPool(string calldata _poolID, address _to)
        external;

    function emergencyWithdraw(
        string calldata _poolID,
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    function getUserInfo(
        string calldata _poolID,
        string calldata _campaignID,
        address _user
    ) external view returns (ITokenSale.UserInfo memory);

    function getCampaignIds(string calldata _poolID)
        external
        view
        returns (string[] memory);

    function getCampaign(string calldata _poolID, string calldata _campaignID)
        external
        view
        returns (ITokenSale.Campaign memory);

    function getTokenSaleContractAddress(string calldata _poolID)
        external
        view
        returns (address);

    function getDistributorAddress(string calldata _poolID)
        external
        view
        returns (address);
}
