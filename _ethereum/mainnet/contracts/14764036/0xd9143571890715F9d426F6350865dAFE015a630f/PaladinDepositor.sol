// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

import "./ZapDepositor.sol";
import "./IPaladinPool.sol";

contract PaladinDepositor is ZapDepositor {
    using SafeERC20Upgradeable for IERC20;
    mapping(address => address) internal paladinUnderlyingLendingPools; // underlying to respective Pool

    event PaladinLendingPoolUpdated(
        address indexed _underlying,
        address indexed _pool
    );

    /**
     * @notice Deposit a defined underling in the depositor protocol
     * @param _token the token to deposit
     * @param _underlyingAmount the amount to deposit
     * @return the amount ibt generated and sent back to the caller
     */
    function depositInProtocol(address _token, uint256 _underlyingAmount)
        public
        override
        onlyZaps
        tokenIsValid(_token)
        returns (uint256)
    {
        address paladinUnderlyingLendingPool = paladinUnderlyingLendingPools[
            _token
        ];

        IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            _underlyingAmount
        ); // pull tokens

        uint256 PalTokens = IPaladinPool(paladinUnderlyingLendingPool).deposit(
            _underlyingAmount
        ); // deposit underlying in the pool and get IBTs to depositor.
        IERC20(IBTOfUnderlying[_token]).transfer(msg.sender, PalTokens); // transfer IBT from depositor to Zap

        return PalTokens;
    }

    /**
     * @notice Deposit a defined underling in the depositor protocol from the caller adderss
     * @param _token the token to deposit
     * @param _underlyingAmount the amount to deposit
     * @param _from the address from which the underlying need to be pulled
     * @return the amount ibt generated
     */
    function depositInProtocolFrom(
        address _token,
        uint256 _underlyingAmount,
        address _from
    ) public override onlyZaps tokenIsValid(_token) returns (uint256) {
        address paladinUnderlyingLendingPool = paladinUnderlyingLendingPools[
            _token
        ];

        IERC20(_token).transferFrom(_from, address(this), _underlyingAmount); // pull tokens

        uint256 PalTokens = IPaladinPool(paladinUnderlyingLendingPool).deposit(
            _underlyingAmount
        ); // deposit underlying in the pool and get IBTs to depositor.
        IERC20(IBTOfUnderlying[_token]).transfer(msg.sender, PalTokens); // transfer IBT from depositor to Zap

        return PalTokens;
    }

    function setPaladinLendingPool(address _underlying, address _pool)
        external
        onlyOwner
    {
        paladinUnderlyingLendingPools[_underlying] = _pool;
        IERC20(_underlying).approve(_pool, MAX_UINT256);
        emit PaladinLendingPoolUpdated(_underlying, _pool);
    }
}
