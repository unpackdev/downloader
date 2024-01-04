pragma solidity 0.6.6;

import "./IBurnGasHelper.sol";
import "./Utils.sol";
import "./Withdrawable.sol";


contract BurnGasHelper is IBurnGasHelper, Utils, Withdrawable {


    address public gasTokenAddr;

    constructor(
        address _admin,
        address _gasToken
    ) public Withdrawable(_admin) {
        gasTokenAddr = _gasToken;
    }

    function updateGasToken(address _gasToken) external onlyAdmin {
        gasTokenAddr = _gasToken;
    }

    function getAmountGasTokensToBurn(
        uint256 gasTotalConsumption
    ) external override view returns(uint numGas, address gasToken) {

        gasToken = gasTokenAddr;
        uint256 gas = gasleft();
        uint256 safeNumTokens = 0;
        if (gas >= 27710) {
            safeNumTokens = (gas - 27710) / 7020; // (1148 + 5722 + 150);
        }

        uint256 gasSpent = 21000 + 16 * gasTotalConsumption;
        numGas = (gasSpent + 14154) / 41947;

        numGas = minOf(safeNumTokens, numGas);
    }
}
