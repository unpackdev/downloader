// commit 99d105d700ccfa5d6bb036808f205ba12c5c7db3
pragma solidity ^0.8.19;

import "BaseACL.sol";

contract ENSContentHashSettingAuthorizer is BaseACL {
    bytes32 public constant NAME = "ENSContentHashSettingAuthorizer";
    uint256 public constant VERSION = 1;

    address public constant ENS_PUBLIC_RESOLVER = 0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63;

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

    constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](1);
        _contracts[0] = ENS_PUBLIC_RESOLVER;
    }

    function multicall(bytes[] calldata data) external view onlyContract(ENS_PUBLIC_RESOLVER) {
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, ) = address(this).staticcall(data[i]);
            require(success, "Setting not allowed");
        }
    }

    function setContenthash(bytes32 node, bytes calldata hash) external view onlySelf {}
}
