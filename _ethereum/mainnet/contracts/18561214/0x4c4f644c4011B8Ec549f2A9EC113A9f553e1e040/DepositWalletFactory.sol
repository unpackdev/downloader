pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./BeaconProxy.sol";

import "./DepositWalletConfig.sol";
import "./DepositWalletImpl.sol";

contract DepositWalletFactory is Ownable {
    using SafeERC20 for IERC20;

    DepositWalletConfig public immutable config;
    address public beacon;

    // Record the vault proxy contract address
    mapping(string => address) public proxyAddresses;

    event NewDepositWalletAddress(string indexed userId, address indexed proxyAddress);

    constructor(
        DepositWalletConfig config_,
        address beacon_
    ) {
        config = config_;
        beacon = beacon_;
    }

    modifier onlyOperator() {
        _;
    }

    function _getCreationBytecode(address beacon_) internal pure returns (bytes memory) {
        bytes memory bytecode = type(BeaconProxy).creationCode;

        return abi.encodePacked(bytecode, abi.encode(beacon_, new bytes(0)));
    }

    function _getSalt(string memory userId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(userId));
    }

    function _getAddress(bytes memory bytecode, bytes32 salt)
        internal
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }

    function predictAddress(string memory userId) external view onlyOperator returns (address) {
        bytes memory bytecode = _getCreationBytecode(beacon);
        bytes32 salt = _getSalt(userId);
        return _getAddress(bytecode, salt);
    }

    function createProxy(string memory userId)  external onlyOperator {
        // check if there is a proxy address created for given userId
        address existingProxyAddress = proxyAddresses[userId];
        if (existingProxyAddress != address(0)) {
            return;
        }
        
        // otherwise create new proxy contract
        bytes memory bytecode = _getCreationBytecode(beacon);
        bytes32 salt = _getSalt(userId);

        address instance;
        assembly {
            instance := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(instance)) {
                revert(0, 0)
            }
        }

        DepositWalletImpl(payable(instance)).initialize(
            config
        );

        proxyAddresses[userId] = instance;

        emit NewDepositWalletAddress(userId, instance);
    }
}