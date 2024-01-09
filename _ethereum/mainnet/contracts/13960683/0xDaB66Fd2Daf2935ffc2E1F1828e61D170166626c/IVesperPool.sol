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

    function deposit(uint256 _share) external;

    function governor() external returns (address);

    function keepers() external returns (address);

    function multiTransfer(
        address[] memory _recipients,
        uint256[] memory _amounts
    ) external returns (bool);

    function excessDebt(address _strategy) external view returns (uint256);

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external;

    function reportEarning(
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external;

    function resetApproval() external;

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function withdrawETH(uint256 _amount) external;

    function whitelistedWithdraw(uint256 _amount) external;

    function addInList(address _target, address _add) external;

    function feeWhitelist() external view returns (address);

    function feeCollector() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function token() external view returns (address);

    function tokensHere() external view returns (uint256);

    function totalDebtOf(address _strategy) external view returns (uint256);

    function totalValue() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function withdrawByStrategy(uint256) external;

    function controller() external view returns (address);

    function feeWhiteList() external view returns (address);

    function getStrategies() external view returns (address[] memory);

    function poolRewards() external view returns (address);
}
