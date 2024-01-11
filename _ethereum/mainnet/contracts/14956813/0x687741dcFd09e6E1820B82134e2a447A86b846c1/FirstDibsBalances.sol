//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "./PullPayment.sol";
import "./Ownable.sol";

contract FirstDibsBalances is Ownable {
    address[] escrowSources;

    constructor(address[] memory _escrowSources) {
        escrowSources = _escrowSources;
    }

    function addEscrowSource(address source) external onlyOwner {
        escrowSources.push(source);
    }

    function getBalancesForAddress(address payee) external view returns (uint256 totalBalance) {
        uint256 escrowSourceLength = escrowSources.length;
        for (uint256 i = 0; i < escrowSourceLength; ) {
            totalBalance += PullPayment(escrowSources[i]).payments(payee);
            unchecked {
                ++i;
            }
        }
    }

    function withdrawBalancesForAddress(address payable payee) external {
        uint256 escrowSourceLength = escrowSources.length;
        for (uint256 i = 0; i < escrowSourceLength; ) {
            PullPayment(escrowSources[i]).withdrawPayments(payee);
            unchecked {
                ++i;
            }
        }
    }
}
