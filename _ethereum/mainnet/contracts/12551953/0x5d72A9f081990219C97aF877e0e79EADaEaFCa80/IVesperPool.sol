// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
import "./IERC20.sol";

interface IVesperPool is IERC20 {
    function approveToken() external;

    function domainSeparator() external view returns (bytes32);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function deposit() external payable;

    function deposit(uint256) external;

    function multiTransfer(uint256[] memory) external returns (bool);

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external;

    function rebalance() external;

    function resetApproval() external;

    function sweepErc20(address) external;

    function withdraw(uint256) external;

    function withdrawETH(uint256) external;

    function withdrawByStrategy(uint256) external;

    function feeCollector() external view returns (address);

    function getPricePerShare() external view returns (uint256);

    function token() external view returns (address);

    function tokensHere() external view returns (uint256);

    function totalValue() external view returns (uint256);

    function withdrawFee() external view returns (uint256);
}
