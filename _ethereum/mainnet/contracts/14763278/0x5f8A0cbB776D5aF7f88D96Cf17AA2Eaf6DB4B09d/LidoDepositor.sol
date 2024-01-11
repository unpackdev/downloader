// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

import "./ZapDepositor.sol";
import "./ILidoSTETH.sol";

contract LidoDepositor is ZapDepositor {
    using SafeERC20Upgradeable for IERC20;

    ILidoSTETH public constant ST_ETH =
        ILidoSTETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84); // mainnet address

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
        require(_token == address(0x00), "Lido: Token address not valid");

        IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            _underlyingAmount
        );
        uint256 IBTAMOUNT = ST_ETH.submit{ value: _underlyingAmount }(
            address(0x00)
        ); // deposit ETH and get STETH to depositor with referral address to 0x00.
        return IBTAMOUNT;
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
        IERC20(_token).transferFrom(_from, address(this), _underlyingAmount); // pull eth from user to depositor
        uint256 IBTAMOUNT = ST_ETH.submit{ value: _underlyingAmount }(
            address(0x00)
        ); // deposit ETH and get STETH to depositor with referral address to 0x00.
        return IBTAMOUNT;
    }
}
