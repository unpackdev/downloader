pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./INonfungiblePositionManager.sol";
import "./AccessControl.sol";


contract MultiSend is AccessControl { 
    bytes32 public constant ACCESS_ROLE = keccak256("ACCESS_ROLE");

    constructor (address admin, address[] memory owners) {
        for (uint256 i = 0; i < owners.length; i++) {
            _setupRole(ACCESS_ROLE, owners[i]);
        }
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    modifier canAccess() {
        require(hasRole(ACCESS_ROLE, msg.sender));
        _;
    }

    function multicall(
        address[] calldata to,
        bytes[] calldata data
    ) external payable canAccess returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = to[i].call(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    } 
}