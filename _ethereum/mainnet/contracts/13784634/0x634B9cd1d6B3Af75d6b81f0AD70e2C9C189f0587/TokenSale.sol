// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./EnumerableSet.sol";

import "./Ownable.sol";
import "./ITokenSale.sol";

contract TokenSale is ITokenSale, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 constant RATE_PRECISION = 1e18;

    mapping(string => Campaign) campaigns;
    string[] campaignIds;
    mapping(string => mapping(address => UserInfo)) usersInfo;

    event Buy(
        address indexed user,
        string _campaignID,
        IERC20 srcToken,
        uint256 srcAmount,
        IERC20 dstToken,
        uint256 dstAmount
    );

    constructor() {}

    function setCampaign(
        string calldata _campaignID,
        bytes32 _merkleRoot,
        uint64 _startTime,
        uint64 _endTime,
        uint256 _srcCap,
        uint256 _dstCap,
        IERC20 _acceptToken,
        IERC20 _token
    ) external override onlyOwner {
        Campaign storage c = campaigns[_campaignID];
        c.merkleRoot = _merkleRoot;
        c.startTime = _startTime;
        c.endTime = _endTime;
        c.srcCap = _srcCap;
        c.rate = (_dstCap * RATE_PRECISION) / _srcCap;
        c.acceptToken = _acceptToken;
        c.token = _token;
        campaignIds.push(_campaignID);
    }

    function setCampaignToken(string calldata _campaignID, IERC20 _token)
        external
        override
        onlyOwner
    {
        Campaign storage c = campaigns[_campaignID];
        c.token = _token;
    }

    function buy(
        string calldata _campaignID,
        uint128 _index,
        uint256 _maxCap,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external payable override nonReentrant {
        address _user = tx.origin;
        Campaign storage c = campaigns[_campaignID];

        require(block.timestamp >= c.startTime, "not start");
        require(block.timestamp < c.endTime, "already end");

        // Verify the whitelist proof.
        bytes32 node = keccak256(
            abi.encodePacked(_campaignID, _index, _user, _maxCap)
        );
        require(
            MerkleProof.verify(_merkleProof, c.merkleRoot, node),
            "Invalid whitelist proof"
        );

        c.totalSource += _amount;
        require(c.totalSource <= c.srcCap, "exceed total cap");

        UserInfo storage userInfo = usersInfo[_campaignID][_user];
        userInfo.contribute += _amount;

        require(userInfo.contribute <= _maxCap, "exceed individual cap");

        uint256 tokenAmount = (_amount * c.rate) / RATE_PRECISION;
        userInfo.allocation += tokenAmount;
        c.totalDest += tokenAmount;

        // collect fund
        if (c.acceptToken == IERC20(address(0))) {
            require(msg.value == _amount, "amount not enough");
        } else {
            c.acceptToken.safeTransferFrom(_user, address(this), _amount);
        }

        emit Buy(
            _user,
            _campaignID,
            c.acceptToken,
            _amount,
            c.token,
            tokenAmount
        );
    }

    function getUserInfo(string calldata _campaignID, address _user)
        external
        view
        override
        returns (UserInfo memory)
    {
        return usersInfo[_campaignID][_user];
    }

    function getCampaign(string calldata _campaignID)
        external
        view
        override
        returns (Campaign memory)
    {
        return campaigns[_campaignID];
    }

    function getCampaignIds() external view override returns (string[] memory) {
        return campaignIds;
    }

    function withdrawSaleFund(string calldata _campaignID, address _to)
        external
        override
        onlyOwner
    {
        Campaign memory c = campaigns[_campaignID];
        require(!c.isFundWithdraw, "already withdraw");
        require(block.timestamp > c.endTime, "not end");
        c.isFundWithdraw = true;
        _safeTransfer(c.acceptToken, _to, c.totalSource);
    }

    function emergencyWithdraw(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        _safeTransfer(_token, _to, _amount);
    }

    function _safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_token == IERC20(address(0))) {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "transfer failed");
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }
}
