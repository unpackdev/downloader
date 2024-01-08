// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IAntePool.sol";
import "./AnteTest.sol";

/// @title Ante Pool contract states matches their ETH balance
/// @notice Connects to already deployed Ante Pools to check them
contract AntePoolTest is AnteTest("Ante Pool contract state matches eth balance") {
    using SafeMath for uint256;

    /// @param antePoolContracts array of Ante Pools to check against
    constructor(address[] memory antePoolContracts) {
        testedContracts = antePoolContracts;
        protocolName = "Ante";
    }

    /// @notice test checks if any Ante Pool's balance is less than supposed store values
    /// @return true if contract balance is greater than or equal to stored Ante Pool values
    function checkTestPasses() public view override returns (bool) {
        for (uint256 i = 0; i < testedContracts.length; i++) {
            IAntePool antePool = IAntePool(testedContracts[i]);
            // totalPaidOut should be 0 before test fails
            if (
                testedContracts[i].balance <
                (
                    antePool
                        .getTotalChallengerStaked()
                        .add(antePool.getTotalStaked())
                        .add(antePool.getTotalPendingWithdraw())
                        .sub(antePool.totalPaidOut())
                )
            ) {
                return false;
            }
        }
        return true;
    }
}
