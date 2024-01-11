// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ITokenSale {
    struct Campaign {
        bytes32 merkleRoot;
        uint64 startTime;
        uint64 endTime;
        uint256 srcCap;
        uint256 rate;
        uint256 totalSource;
        uint256 totalDest;
        bool isFundWithdraw;
        IERC20 token;
        IERC20 acceptToken;
    }

    struct UserInfo {
        uint256 allocation;
        uint256 contribute;
    }

    function setCampaign(
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
        string calldata _campaignID,
        IERC20 _token
    ) external;

    function buy(
        string calldata _campaignID,
        uint128 _index,
        uint256 _maxCap,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external payable;

    function withdrawSaleFund(string calldata _campaignID, address _to)
        external;

    function emergencyWithdraw(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    function getUserInfo(string calldata _campaignID, address _user)
        external
        view
        returns (UserInfo memory);

    function getCampaign(string calldata _campaignID)
        external
        view
        returns (Campaign memory);

    function getCampaignIds() external view returns (string[] memory);
}
