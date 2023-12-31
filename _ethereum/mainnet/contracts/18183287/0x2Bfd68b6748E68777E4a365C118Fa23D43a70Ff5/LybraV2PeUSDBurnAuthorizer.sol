// commit b908eb18eaf705ec77161dbfeaa85a59e48f03cc
pragma solidity ^0.8.19;

import "BaseACL.sol";

contract LybraV2PeUSDBurnAuthorizer is BaseACL {
    bytes32 public constant NAME = "LybraV2PeUSDBurnAuthorizer";
    uint256 public constant VERSION = 1;

    constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}

    //lybra related
    address public constant LybraWstETHVault = 0x5e28B5858DA2C6fb4E449D69EEb5B82e271c45Ce;
    address public constant LybraWBETHVault = 0xB72dA4A9866B0993b9a7d842E5060716F74BF262;
    address public constant LybraRETHVault = 0x090B2787D6798000710a8e821EC6111d254bb958;

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](3);
        _contracts[0] = LybraWstETHVault;
        _contracts[1] = LybraWBETHVault;
        _contracts[2] = LybraRETHVault;
    }

    function burn(address onBehalfOf, uint256 amount) external view {
        _checkRecipient(onBehalfOf);
    }

    function withdraw(address onBehalfOf, uint256 amount) external view {
        _checkRecipient(onBehalfOf);
    }

    function rigidRedemption(address provider, uint256 peusdAmount, uint256 minReceiveAmount) external view {}
}
