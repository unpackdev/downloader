// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICompensationVault {
    struct CompensationParams {
        uint256 deadline;
        uint256 nonce;
        address vault; // address of CompensationVault contract
        uint256 quote; // quote from changer
        uint256 targetQuote; // quote from other aggregator
        uint256 compensationAmount; // amount of compensation token
        address maker; // transaction maker
        address signer; // parameter signer address
        bool transferCompensation; // if true, transfer compensation. otherwise, accumulate
        bytes signature; // parameter signature
    }

    function remainingCompensation() external view returns (uint256);

    function getDailyLimit() external view returns (uint256);

    /**
     * @dev get current compensation of account
     */
    function getCompensation(address account) external view returns (uint256);

    /**
     * @dev claim compensation tokens
     */
    function claimCompensation() external returns (uint256);

    /**
     * @dev add compensation token
     */
    function addCompensation(uint256 amount1Out, CompensationParams calldata compensationParams) external;

    /**
     * @dev calculate compensation amount wrt limits
     */
    function calcCompensationAmount(uint256 compensationAmount) external view returns (uint256);

    function setSigner(address account, bool value) external;

    function setRouter(address account, bool value) external;

    function rescueTokens(address _token, uint256 _value) external;

    function pause() external;

    function unpause() external;
}
