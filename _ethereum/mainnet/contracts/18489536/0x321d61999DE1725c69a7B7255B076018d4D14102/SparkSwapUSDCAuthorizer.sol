// commit 72851dc7b28e8982506694bd739a08d668212610
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseACL.sol";

contract SparkSwapUSDCAuthorizer is BaseACL {
    bytes32 public constant NAME = "SparkSwapUSDCAuthorizer";
    uint256 public constant VERSION = 1;

    address public constant dssPSM = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;

    constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](1);

        _contracts[0] = dssPSM;
    }

    // ACL methods
    function buyGem(address usr, uint256 gemAmt) external view onlyContract(dssPSM) {
        // use 'require' to check the access
        // use '_checkRecipient' to check the recipient
        // all address parameters will be checked by '_checkRecipient', make sure the check is correct
        _checkRecipient(usr);
    }
}
