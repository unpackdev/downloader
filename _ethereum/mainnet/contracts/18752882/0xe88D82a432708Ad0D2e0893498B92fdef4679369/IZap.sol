// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AsyncSwapper.sol";

interface IZap {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error DelegateSwapFailed();

    error PoolNotRegistered();

    error WrongPoolToken();

    error WrongAmount();

    error InvalidChainId();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event StargateDestinationsSet(uint16[] chainIds, address[] destinations);

    /*///////////////////////////////////////////////////////////////
                          MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Wrapper function calling the stakeFor function of a Pool contract
     * Pulls the funds from msg.sender
     *  @param _pool The pool address
     *  @param _amount The stake amount
     */
    function stake(address _pool, uint256 _amount) external;

    /**
     * @notice Wrapper function calling the stakeFor function of a Pool contract
     * Pulls the funds from the TokenKeeper contract
     *  @param _pool The pool address
     */
    function stakeFromBridge(address _pool) external;

    /**
     * @notice Swaps a token for another using the swapper then stakes it in the pool
     *  @param _swapParams A struct containing all necessary params allowing a token swap
     *  @param _pool The pool address
     */
    function swapAndStake(SwapParams memory _swapParams, address _pool) external;

    /**
     * @notice Swaps a token for another using the swapper then stakes it in the pool
     * Pulls the funds from the TokenKeeper contract
     *  @param _swapParams A struct containing all necessary params allowing a token swap
     *  @param _pool The pool address
     */
    function swapAndStakeFromBridge(SwapParams memory _swapParams, address _pool) external;

    /**
     *  @notice Swaps a token for another using the swapper then bridges it
     *  @param _swapParams A struct containing all necessary params allowing a token swap
     *  @param _minAmount The minimum amount of bridged tokens caller is willing to accept
     *  @param _dstChainId The destination chain ID
     *  @param _srcPoolId The source pool ID
     *  @param _dstPoolId The destination pool ID
     *  @param _dstAccount The destination account
     */
    function swapAndBridge(
        SwapParams memory _swapParams,
        uint256 _minAmount,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _dstAccount
    ) external payable;

    /**
     * @notice Bridges tokens to a specific chain using Stargate
     *  @param _token The token address
     *  @param _amount The amount of token to bridge
     *  @param _minAmount The minimum amount of bridged tokens caller is willing to accept
     *  @param _dstChainId The destination chain ID
     *  @param _srcPoolId The source pool ID
     *  @param _dstPoolId The destination pool ID
     *  @param _dstAccount The destination account
     */
    function bridge(
        address _token,
        uint256 _amount,
        uint256 _minAmount,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _dstAccount
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                            SETTERS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Configure our Stargate receivers on destination chains
    /// @dev Arrays are expected to be index synced
    /// @param _chainIds List of Stargate chain ids to configure
    /// @param _destinations List of our receivers on chain id
    function setStargateDestinations(uint16[] calldata _chainIds, address[] calldata _destinations) external;
}
