// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

import "./ZapDepositor.sol";
import "./IAaveLendingPool.sol";
import "./console.sol";

contract AaveDepositor is ZapDepositor {
    using SafeERC20Upgradeable for IERC20;
    mapping(address => address) internal aaveUnderlyingLendingPools; // underlying to respective Pool

    event AaveLendingPoolUpdated(
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
        address aaveUnderlyingLendingPool = aaveUnderlyingLendingPools[_token];

        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _underlyingAmount
        );

        IAaveLendingPool(aaveUnderlyingLendingPool).deposit(
            _token,
            _underlyingAmount,
            msg.sender,
            0
        );

        return IERC20(IBTOfUnderlying[_token]).balanceOf(msg.sender);
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
        address aaveUnderlyingLendingPool = aaveUnderlyingLendingPools[_token];

        IERC20(_token).safeTransferFrom(
            _from,
            address(this),
            _underlyingAmount
        );

        IAaveLendingPool(aaveUnderlyingLendingPool).deposit(
            _token,
            _underlyingAmount,
            msg.sender,
            0
        );

        return IERC20(IBTOfUnderlying[_token]).balanceOf(msg.sender);
    }

    function setAaveLendingPool(address _underlying, address _pool)
        external
        onlyOwner
    {
        aaveUnderlyingLendingPools[_underlying] = _pool;
        IERC20(_underlying).safeApprove(_pool, MAX_UINT256);
        emit AaveLendingPoolUpdated(_underlying, _pool);
    }
}
