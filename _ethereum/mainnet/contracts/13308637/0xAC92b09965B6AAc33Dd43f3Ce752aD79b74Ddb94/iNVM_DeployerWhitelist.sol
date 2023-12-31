// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title iNVM_DeployerWhitelist
 */
interface iNVM_DeployerWhitelist {

    /********************
     * Public Functions *
     ********************/

    function initialize(address _owner, bool _allowArbitraryDeployment) external;
    function owner() external returns (address _owner);
    function setWhitelistedDeployer(address _deployer, bool _isWhitelisted) external;
    function setOwner(address _newOwner) external;
    function setAllowArbitraryDeployment(bool _allowArbitraryDeployment) external;
    function enableArbitraryContractDeployment() external;
    function isDeployerAllowed(address _deployer) external returns (bool _allowed);
}
