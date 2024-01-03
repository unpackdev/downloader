// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

import "./GasTokenInterface.sol";

contract GasTokenUser {
    GasTokenInterface constant public GAS_TOKEN = GasTokenInterface(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    /**
     * @dev It's expected that frontend checks the CHI balance, so we don't check it here.
     */
    modifier usesGasToken(address holder) {
        uint256 gasCalcValue = gasleft();

        _;

        gasCalcValue = (_gasUsed(gasCalcValue) + 14154) / 41947;

        GAS_TOKEN.freeFromUpTo(
            holder,
            gasCalcValue
        );
    }

    function _gasUsed(uint256 startingGas) internal view returns (uint256) {
        return 21000 + startingGas - gasleft() + 16 * msg.data.length;
    }
}
