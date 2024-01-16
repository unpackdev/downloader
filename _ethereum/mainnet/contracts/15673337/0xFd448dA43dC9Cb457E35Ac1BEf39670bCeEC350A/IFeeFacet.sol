// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFeeFacet {

    event ClaimProtocolFee(address indexed _token, address indexed _recipient, uint256 _amount);
    event SetFee(address indexed _token, uint256 _fee);
    event SetTokenPayment(address indexed _token, bool _status);

    /// @notice Claims unclaimed rent fees for a given asset to asset owner
    /// @param _assetId The target asset
    /// @return paymentToken_ The current asset payment token
    /// @return rentFee_ The rent fee amount in the current payment token
    function claimRentFee(uint256 _assetId) external returns (address paymentToken_, uint256 rentFee_);

    /// @notice Claims unclaimed rent fees for a set of assets to assets' owners
    /// @param _assetIds The array of assets
    function claimMultipleRentFees(uint256[] calldata _assetIds) external;

    /// @notice Claims protocol fees of a given payment token to contract owner
    /// Provide 0x0000000000000000000000000000000000000001 for ETH
    /// Can be called by any address. If owner EOA or contract has any issue with
    /// ETH processing or token withdrawals, the amount sent can be lost.
    /// @param _token The target token
    function claimProtocolFee(address _token) external;

    /// @notice Claims protocol fees for a set of tokens to contract owner
    /// Provide 0x0000000000000000000000000000000000000001 for ETH
    /// Can be called by any address. If owner EOA or contract has any issue with
    /// ETH processing or token withdrawals, the amount sent can be lost.
    /// @param _tokens The array of tokens
    function claimProtocolFees(address[] calldata _tokens) external;

    /// @notice Sets the protocol fee for token payments
    /// @param _token The target token
    /// @param _feePercentage The fee percentage, charged on every rent
    function setFee(address _token, uint256 _feePercentage) external;

    /// @notice Sets status of token payment (accepted or not) and its fee
    /// @param _token The target token
    /// @param _feePercentage The fee percentage, charged on every rent
    /// @param _status Whether the token will be added or removed from the
    /// supported token payments list
    function setTokenPayment(
        address _token,
        uint256 _feePercentage,
        bool _status
    ) external;

    /// @notice Gets the unclaimed amount of fees for a payment token
    /// @param _token The target token
    function protocolFeeFor(address _token) external view returns (uint256);

    /// @notice Gets the unclaimed amount of asset rent fees of a payment
    /// token for an asset
    /// @param _assetId The target asset
    /// @param _token The target token
    function assetRentFeesFor(uint256 _assetId, address _token)
        external
        view
        returns (uint256);

    /// @notice Gets whether the token payment is supported
    /// @param _token The target token
    function supportsTokenPayment(address _token) external view returns (bool);

    /// @notice Gets the total amount of token payments
    function totalTokenPayments() external view returns (uint256);

    /// @notice Gets the token payment at a given index
    function tokenPaymentAt(uint256 _index) external view returns (address);

    /// @notice Gets the fee percentage for a token payment
    /// @param _token The target token
    function feePercentage(address _token) external view returns (uint256);

    /// @notice Gets the fee precision
    function feePrecision() external pure returns (uint256);
}
