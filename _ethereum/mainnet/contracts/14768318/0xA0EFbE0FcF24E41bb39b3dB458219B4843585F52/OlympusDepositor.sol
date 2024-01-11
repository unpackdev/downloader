// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

import "./ZapDepositor.sol";
import "./IOlympusStaking.sol";

contract OlympusDepositor is ZapDepositor {
    using SafeERC20Upgradeable for IERC20;

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
        IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            _underlyingAmount
        ); // pull underlying tokens

        uint256 balanceOf_IBT = IOlympusStaking(IBTOfUnderlying[_token]).stake(
            msg.sender,
            uint256(_underlyingAmount),
            false,
            true
        ); // deposit underlying in the vault and mint IBTs to depositor.

        return balanceOf_IBT;
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
        require(
            IERC20(_token).transferFrom(
                _from,
                address(this),
                _underlyingAmount
            ),
            "OlympusDepositor: Underlying Pull failed"
        ); // pull underlying tokens

        uint256 balanceOf_IBT = IOlympusStaking(IBTOfUnderlying[_token]).stake(
            msg.sender,
            uint256(_underlyingAmount),
            false,
            true
        ); // stake underlying in the staking and mint IBTs to depositor.

        return balanceOf_IBT;
    }
}
