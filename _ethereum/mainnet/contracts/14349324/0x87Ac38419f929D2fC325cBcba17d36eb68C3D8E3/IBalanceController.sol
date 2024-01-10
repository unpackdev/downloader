// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

/**
 * @dev Allows users (e.g. an owner) to withdraw funds.
 */
interface IBalanceController {
    receive() external payable;

    /**
     * @dev Allows the owner to move any ERC20 tokens owned by the
     * contract.
     */
    function withdrawERC20(address token, address account, uint256 amount) external;

    /**
     * @dev Allows the owner to move any ETH held by the contract.
     */
    function withdraw(address account, uint256 amount) external;
}
