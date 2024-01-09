// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;


interface IVault {
    struct TONAddress {
        int128 wid;
        uint256 addr;
    }

    struct StrategyParams {
        uint256 performanceFee;
        uint256 activation;
        uint256 debtRatio;
        uint256 minDebtPerHarvest;
        uint256 maxDebtPerHarvest;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalSkim;
        uint256 totalLoss;
        address rewardsManager;
        TONAddress rewards;
    }


    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    function saveWithdraw(
        bytes32 payloadId,
        address recipient,
        uint256 amount,
        uint256 timestamp,
        uint256 bounty
    ) external;

    function deposit(
        address sender,
        TONAddress calldata recipient,
        uint256 _amount,
        PendingWithdrawalId calldata pendingWithdrawalId,
        bool sendTransferToTon
    ) external;

    function forceWithdraw(
        address recipient,
        uint256 id
    ) external;

    function setPendingWithdrawApprove(
        address recipient,
        uint256 id,
        uint256 approveStatus
    ) external;

    function configuration() external view returns(TONAddress memory _configuration);
    function bridge() external view returns(address);
    function apiVersion() external view returns(string memory api_version);

    function initialize(
        address _token,
        address _governance,
        address _bridge,
        uint256 _targetDecimals
    ) external;

    function setWrapper(address _wrapper) external;
    function setGuardian(address _guardian) external;
    function setManagement(address _management) external;
    function setGovernance(address _governance) external;

    function debtOutstanding() external view returns (uint256);
    function creditAvailable() external view returns (uint256);
    function report(uint256 profit, uint256 loss, uint256 debtPayment) external returns (uint256);
    function revokeStrategy() external;

    function strategies(address strategy) external view returns (StrategyParams memory);

    function governance() external view returns(address);
    function token() external view returns(address);
    function guardian() external view returns(address);
    function withdrawGuardian() external view returns(address);
    function management() external view returns(address);
    function wrapper() external view returns(address);

    function tokenDecimals() external view returns(uint256);
    function targetDecimals() external view returns(uint256);
}
