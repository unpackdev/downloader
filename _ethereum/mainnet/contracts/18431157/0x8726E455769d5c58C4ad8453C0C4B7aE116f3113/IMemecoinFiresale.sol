// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Errors.sol";
import "./Structs.sol";

interface IMemecoinFiresale {
    event UserReserved(address indexed user, uint32 amount, uint256 userTotalReserved, uint32 max);
    event UserRefunded(address indexed user, uint32 wonAmount);
    event FiresaleStatedUpdated(FiresaleState newState);
    event RefundStartDateUpdated(uint256 _refundStartDate);
    event SignerUpdated(address newSigner);
    event UpgraderUpdated(address newUpgrader);

    function reserve(address _vault, uint32 _amount, uint32 _max, bytes calldata _signature) external payable;
    function refund(address _vault, uint32 _allocatedAmount, bytes calldata _signature) external;

    function setFiresaleState(FiresaleState _state) external;
    function setRefundStartDate(uint256 _refundStartDate) external;

    function setSigner(address _signer) external;
    function setUpgrader(address _upgrader) external;

    function withdrawSales(uint256 _totalFiresaleItems) external;
    function withdrawRefund(address _receiver, uint256 _amount) external;

    function getFiresaleUsersCount() external view returns (uint256);
    function getFiresaleUsers(uint256 _fromIdx, uint256 _toIdx) external view returns (address[] memory);
}
