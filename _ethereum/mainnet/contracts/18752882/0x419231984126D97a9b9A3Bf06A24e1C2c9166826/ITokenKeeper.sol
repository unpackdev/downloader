// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenKeeper {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event BridgedTokensReceived(address indexed account, address indexed token, uint256 amount);

    event ZapSet(address indexed zap);

    event StargateReceiverSet(address indexed receiver);

    event TokenTransferred(address indexed from, address indexed to, address indexed token, uint256 amount);

    /*///////////////////////////////////////////////////////////////
    											VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns an account's balance for a specific token
     *  @param _account The address of the account
     *  @param _token The address of the token
     * @return The account's token balance
     */
    function balances(address _account, address _token) external returns (uint256);

    /*///////////////////////////////////////////////////////////////
    											SETTER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets both Zap and StargateReceiver addresses
     *  @param _zap The Zap contract address
     *  @param _receiver The StargateReceiver contract address
     */
    function setZapAndStargateReceiver(address _zap, address _receiver) external;

    /**
     * @notice Sets the Zap address
     *  @param _zap The Zap contract address
     */
    function setZap(address _zap) external;

    /**
     * @notice Sets the StargateReceiver address
     *  @param _receiver The StargateReceiver contract address
     */
    function setStargateReceiver(address _receiver) external;

    /*///////////////////////////////////////////////////////////////
    											MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfers and registers the bridged tokens for an account
     *  @param _account The address of the account
     *  @param _token The address of the token
     *  @param _amount The bridged amount
     */
    function transferFromStargateReceiver(address _account, address _token, uint256 _amount) external;

    /**
     * @notice Transfers tokens to Zap contract for an account
     *  @param _token The address of the token
     *  @param _account The address of the account
     *  @return The transferred amount
     */
    function pullToken(address _token, address _account) external returns (uint256);

    /**
     * @notice Allows an account to withdraw their token balance
     *  @param _token The address of the token
     *  @return The transferred amount
     */
    function withdraw(address _token) external returns (uint256);
}
