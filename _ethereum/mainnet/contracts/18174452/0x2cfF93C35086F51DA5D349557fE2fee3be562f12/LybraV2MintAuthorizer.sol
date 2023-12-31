// commit 2eaf119cda8db53ead57f342a8967cf792bc365a
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseACL.sol";

contract LybraV2MintAuthorizer is BaseACL {
    bytes32 public constant NAME = "LybraV2MintAuthorizer";
    uint256 public constant VERSION = 1;

    constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}

    address public constant LybraStETHVault = 0xa980d4c0C2E48d305b582AA439a3575e3de06f0E;

    function depositEtherToMint(uint256 mintAmount) external view onlyContract(LybraStETHVault) {}

    function depositAssetToMint(uint256 assetAmount, uint256 mintAmount) external view onlyContract(LybraStETHVault) {}

    function mint(address onBehalfOf, uint256 amount) external view {
        _checkRecipient(onBehalfOf);
    }

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](1);
        _contracts[0] = LybraStETHVault;
    }
}
