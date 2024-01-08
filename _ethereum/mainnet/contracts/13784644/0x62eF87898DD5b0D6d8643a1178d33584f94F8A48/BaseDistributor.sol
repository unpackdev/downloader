// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./ITokenSale.sol";
import "./IDistributor.sol";

abstract contract BaseDistributor is IDistributor, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event ReleaseInfoSet(
        string _campaignID,
        uint256[] trancheStartTimestamps,
        uint256[] trancheEndTimestamps,
        uint32[] percentageOfTranches,
        TrancheType[] trancheTypes
    );

    event Withdraw(address user, string _campaignID, uint256 _amount);

    constructor() {}

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

    function withdraw(string calldata _campaignID) external virtual override {}

    function setReleaseInfo(
        string calldata _campaignID,
        uint256[] calldata _trancheStartTimestamps,
        uint256[] calldata _trancheEndTimestamps,
        uint32[] calldata _percentageOfTranches,
        TrancheType[] calldata _trancheTypes
    ) external virtual override onlyOwner {}

    function getWithdrawableAmount(string calldata _campaignID, address _user)
        external
        view
        virtual
        override
        returns (uint256)
    {}

    function getWithdrawedAmount(string calldata _campaignID, address _user)
        external
        view
        virtual
        override
        returns (uint256)
    {}
}
