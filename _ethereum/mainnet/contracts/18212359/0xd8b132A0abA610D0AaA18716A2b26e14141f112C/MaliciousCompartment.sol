// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./Ownable2Step.sol";
import "./SafeERC20.sol";
import "./MaliciousOwnerContract.sol";
import "./ILenderVaultImpl.sol";

contract MaliciousCompartment {
    address internal immutable _tokenToBeWithdrawn;
    address internal immutable _maliciousOwnerContract;

    constructor(address tokenToBeWithdrawn, address maliciousOwnerContract) {
        _tokenToBeWithdrawn = tokenToBeWithdrawn;
        _maliciousOwnerContract = maliciousOwnerContract;
    }

    function initialize(address _vaultAddr, uint256 /*_loanIdx*/) external {
        MaliciousOwnerContract(_maliciousOwnerContract).callback(
            _vaultAddr,
            _tokenToBeWithdrawn
        );
    }

    function claimVaultOwnership(address lenderVault) external {
        Ownable2Step(lenderVault).acceptOwnership();
    }
}
