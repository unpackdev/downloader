//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ITokensApprover {
    /**
     * @notice Data for issuing permissions for the token
     */
    struct ApproveConfig {
        string name;
        string version;
        string domainType;
        string primaryType;
        string noncesMethod;
        string permitMethod;
        bytes4 permitMethodSelector;
    }

    function addConfig(ApproveConfig calldata config) external returns (uint256);

    function setConfig(uint256 id, ApproveConfig calldata config) external returns (uint256);

    function setToken(uint256 id, address token) external;

    function getConfig(address token) view external returns (ApproveConfig memory);

    function getConfigById(uint256 id) view external returns (ApproveConfig memory);

    function configsLength() view external returns (uint256);

    function hasConfigured(address token) view external returns (bool);

    function callPermit(address token, bytes calldata permitCallData) external returns (bool, bytes memory);
}
