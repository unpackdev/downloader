// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./IERC20.sol";

/**
 * @title VoltaPower
 * @dev Calculates the voting power for Volta Club's governance system. The calculation takes into account the user’s holdings of Volta, as well as their collateral and debts, to determine their effective voting power.
 */
contract VoltaPower {
    IERC20 public volta;
    IERC20 public uVOLTA;
    IERC20 public variableDebtVOLTA;

    /**
     * @dev Constructor function to initialize the smart contract with addresses of specific tokens.
     * @param _volta Address of the Volta token contract.
     * @param _uVolta Address of the uVolta token contract.
     * @param _variableDebtVolta Address of the variableDebtVOLTA token contract.
     */
    constructor(address _volta, address _uVolta, address _variableDebtVolta) {
        require(
            _volta != address(0) &&
                _uVolta != address(0) &&
                _variableDebtVolta != address(0),
            "Invalid token address"
        );
        volta = IERC20(_volta);
        uVOLTA = IERC20(_uVolta);
        variableDebtVOLTA = IERC20(_variableDebtVolta);
    }

    /**
     * @dev Internal function to get the balance of a specific token for an account.
     * @param token The ERC20 token contract.
     * @param account The address of the account.
     * @return The balance of the token for the given account.
     */
    function getBalance(
        IERC20 token,
        address account
    ) internal view returns (uint256) {
        return token.balanceOf(account);
    }

    /**
     * @dev External function to calculate the effective balance of an account.
     * It sums the balances of Volta and uVOLTA tokens and subtracts the balance of variableDebtVOLTA tokens.
     * If the debt is greater than the sum of Volta and uVOLTA, the function returns 0.
     * @param account The address of the account.
     * @return The calculated effective voting power of the account.
     */
    function balanceOf(address account) external view returns (uint256) {
        uint256 voltaBalance = getBalance(volta, account);
        uint256 uVoltaBalance = getBalance(uVOLTA, account);
        uint256 debtVoltaBalance = getBalance(variableDebtVOLTA, account);

        return
            debtVoltaBalance > (voltaBalance + uVoltaBalance)
                ? 0
                : (voltaBalance + uVoltaBalance - debtVoltaBalance);
    }
}
