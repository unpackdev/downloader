// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import "./MultiCall.sol";
import "./Balances.sol";
import "./ICreditFacade.sol";

interface CreditFacadeMulticaller {}

library CreditFacadeCalls {
    function revertIfReceivedLessThan(
        CreditFacadeMulticaller creditFacade,
        Balance[] memory expectedBalances
    ) internal pure returns (MultiCall memory) {
        return
            MultiCall({
                target: address(creditFacade),
                callData: abi.encodeWithSelector(
                    ICreditFacadeExtended.revertIfReceivedLessThan.selector,
                    expectedBalances
                )
            });
    }

    function addCollateral(
        CreditFacadeMulticaller creditFacade,
        address borrower,
        address token,
        uint256 amount
    ) internal pure returns (MultiCall memory) {
        return
            MultiCall({
                target: address(creditFacade),
                callData: abi.encodeWithSelector(
                    ICreditFacade.addCollateral.selector,
                    borrower,
                    token,
                    amount
                )
            });
    }

    function increaseDebt(CreditFacadeMulticaller creditFacade, uint256 amount)
        internal
        pure
        returns (MultiCall memory)
    {
        return
            MultiCall({
                target: address(creditFacade),
                callData: abi.encodeWithSelector(
                    ICreditFacade.increaseDebt.selector,
                    amount
                )
            });
    }

    function decreaseDebt(CreditFacadeMulticaller creditFacade, uint256 amount)
        internal
        pure
        returns (MultiCall memory)
    {
        return
            MultiCall({
                target: address(creditFacade),
                callData: abi.encodeWithSelector(
                    ICreditFacade.decreaseDebt.selector,
                    amount
                )
            });
    }

    function enableToken(CreditFacadeMulticaller creditFacade, address token)
        internal
        pure
        returns (MultiCall memory)
    {
        return
            MultiCall({
                target: address(creditFacade),
                callData: abi.encodeWithSelector(
                    ICreditFacade.enableToken.selector,
                    token
                )
            });
    }

    function disableToken(CreditFacadeMulticaller creditFacade, address token)
        internal
        pure
        returns (MultiCall memory)
    {
        return
            MultiCall({
                target: address(creditFacade),
                callData: abi.encodeWithSelector(
                    ICreditFacadeExtended.disableToken.selector,
                    token
                )
            });
    }
}
