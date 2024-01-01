// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IPortal.sol";

contract BridgeToBase is OwnableUpgradeable{
    address public constant CROSS_CHAIN_PORTAL =
        0x49048044D57e1C92A77f79988d21Fa8fAF74E97e;
    address public constant BASE_RECEIVER =
        0xECe2E9A2ED3FD284FF52ba02cF7220E697437ff9;
    uint64 public constant GAS_LIMIT = 250_000;

    uint256[50] private _gap;

      function initialize() public initializer {
        __Ownable_init();
    }
    
    receive() external payable {
        bytes memory mintAtBaseNftData = abi.encodeWithSelector(
            bytes4(keccak256("mintAtBaseNft(address)")),
            msg.sender
        );

       IProtal(CROSS_CHAIN_PORTAL).depositTransaction{value: msg.value}(
            BASE_RECEIVER,
            msg.value,
            GAS_LIMIT,
            false,
            mintAtBaseNftData
        );
    }
}
