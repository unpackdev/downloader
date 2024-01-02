// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPoolFactory {
    /*///////////////////////////////////////////////////////////////
                            	EVENTS
    ///////////////////////////////////////////////////////////////*/

    event PoolFactoryCreated(address indexed owner, address indexed registry, address treasury, uint256 protocolFee);

    event DeployerAdded(address indexed account, address indexed token);

    event DeployerRemoved(address indexed account, address indexed token);

    event PoolCreated(address indexed pool);

    event TemplateAdded(address indexed template);

    event TemplateRemoved(address indexed template);

    event TreasurySet(address indexed oldTreasury, address indexed newTreasury);

    event ProtocolFeeSet(uint256 oldFee, uint256 newFee);

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the address of a pool template located at _index
     *  @param _index The index of a pool template stored in the EnumerableSet
     * @return The address of a pool template
     */
    function getTemplateAt(uint256 _index) external view returns (address);

    /**
     * @notice Returns the total number of pool templates
     * @return The total number of pool templates
     */
    function getTemplateCount() external view returns (uint256);

    /**
     * @notice Checks if an address is stored in the templates
     * @param _template The address of a pool template
     * @return True if the template address has been found, false otherwise
     */
    function hasTemplate(address _template) external view returns (bool);

    /**
     * @notice Checks if an account is an authorized deployer for a token
     * @param _account The account address
     * @param _token The address of a token
     * @return True if the pair (account, token) has been found, false otherwise
     */
    function canDeploy(address _account, address _token) external view returns (bool);

    /*///////////////////////////////////////////////////////////////
    										SETTERS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifies the treasury address
     * @param _newTreasury The new treasury address
     */
    function setTreasury(address _newTreasury) external;

    /**
     * @notice Modifies the protocol fee
     * @param _feeBps The new protocol fee amount
     */
    function setProtocolFee(uint256 _feeBps) external;

    /*///////////////////////////////////////////////////////////////
    								MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new pool using the Clone mechanism
     * @param _template The pool template address
     * @param _token The token address used for the pool
     * @param _seedingPeriod The period in seconds during which users are able to stake
     * @param _lockPeriod The period in seconds during which the staked tokens are locked
     * @param _rewardAmount The total reward amount for the staking pool
     * @param _maxStakePerAddress The maximum amount of tokens that can be staked by a single address
     * @param _maxStakePerPool The maximum amount of tokens that can be staked in the pool
     */
    function createPool(
        address _template,
        address _token,
        uint256 _seedingPeriod,
        uint256 _lockPeriod,
        uint256 _rewardAmount,
        uint256 _maxStakePerAddress,
        uint256 _maxStakePerPool
    ) external returns (address);

    /**
     * @notice Adds a new pool template to the storage
     * @param _template The address of the pool template
     */
    function addTemplate(address _template) external;

    /**
     * @notice Removes a new pool template from the storage
     * @param _template The address of the pool template
     */
    function removeTemplate(address _template) external;

    /**
     * @notice Whitelist an account to be a pool deployer for a specific token
     * @param _account The account address
     * @param _token The token address
     */
    function addDeployer(address _account, address _token) external;

    /**
     * @notice Removes the rights for an account to be a pool deployer for a specific token
     * @param _account The account address
     * @param _token The token address
     */
    function removeDeployer(address _account, address _token) external;
}
