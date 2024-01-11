// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

interface IWETH {
    /**
     * @dev deposit eth to the contract
     */

    function deposit() external payable;

    /**
     * @dev transfer allows to transfer to a wallet or contract address
     * @param to recipient address
     * @param value amount to be transfered
     * @return Transfer status.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev allow to withdraw weth from contract
     */

    function withdraw(uint256) external;
}
