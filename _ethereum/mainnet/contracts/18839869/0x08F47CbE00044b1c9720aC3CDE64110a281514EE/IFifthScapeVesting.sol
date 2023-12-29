// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

interface IFifthScapeVesting {
    function getAllocatedTokens(
        address _beneficiary
    ) external view returns (uint256 amount);

    function getClaimedTokens(
        address _beneficiary
    ) external view returns (uint256 amount);

    function getClaimableTokens(
        address _beneficiary
    ) external view returns (uint256 amount);

    function getReleasedTokensAtTimestamp(
        address _beneficiary,
        uint256 _timestamp
    ) external view returns (uint256 amount);

    function getBlacklist(
        address _account
    ) external view returns (bool isBlacklist);

    function getManager(
        address _account
    ) external view returns (bool isManager);

    function claimTokens(address[] memory _beneficiaries) external;

    function allocateTokensManager(
        address _benificiary,
        uint256 _amount
    ) external;

    function allocateTokens(
        address[] memory _benificiaries,
        uint256[] memory _amounts
    ) external;

    function updateStart(uint256 _start) external;

    function updateToken(address _token) external;

    function setManager(address _manager, bool _isManager) external;

    function blacklist(address _beneficiary) external;

    function removeBlacklist(address _beneficiary) external;

    function withdrawERC20(address _tokenAddress, uint256 _amount) external;

    function withdrawNative(uint256 _amount) external;

    function pause() external;

    function unpause() external;
}
