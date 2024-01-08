// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;


interface IVault {
    struct TONAddress {
        int128 wid;
        uint256 addr;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    function saveWithdraw(
        bytes32 payloadId,
        address recipient,
        uint256 amount,
        uint256 bounty
    ) external;

    function deposit(
        address sender,
        TONAddress calldata recipient,
        uint256 _amount,
        PendingWithdrawalId calldata pendingWithdrawalId,
        bool sendTransferToTon
    ) external;

    function configuration() external view returns(TONAddress memory _configuration);
    function bridge() external view returns(address);
    function apiVersion() external view returns(string memory api_version);

    function initialize(
        address _token,
        address _governance,
        address _bridge,
        address _wrapper,
        address guardian,
        address management,
        uint256 targetDecimals
    ) external;

    function governance() external view returns(address);
    function token() external view returns(address);
    function wrapper() external view returns(address);
}
