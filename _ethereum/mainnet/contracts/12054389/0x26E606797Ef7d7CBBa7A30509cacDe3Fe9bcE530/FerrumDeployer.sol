pragma solidity >=0.6.0 <0.8.0;
import "./Create2.sol";

contract FerrumDeployer {
    uint256 constant EXTERNAL_HASH = 0x0ddafcd8600839ce553cacb17e362c83ea42ccfd1e8c8b3cb4d075124196dfc0;
    uint256 constant INTERNAL_HASH = 0x27fd0863a54f729686099446389b11108e6e34e7364d1f8e38a43e1661a07f3a;
    event Deployed(address);
    function deploy(bytes32 salt, bytes calldata bytecode)
    external returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(salt, INTERNAL_HASH, msg.sender)
        );
        address deployed = Create2.deploy(0, _data, bytecode);
        emit Deployed(deployed);
        return deployed;
    }

    /**
     * @dev Use this method if you want to incorporate the sender address in the contract address.
     */
    function deployFromContract(bytes32 salt, address deployer, bytes calldata bytecode)
    external returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(salt, EXTERNAL_HASH, deployer)
        );
        address deployed = Create2.deploy(0, _data, bytecode);
        emit Deployed(deployed);
        return deployed;
    }

    function computeAddressFromContract(bytes32 salt, bytes32 bytecodeHash, address deployer)
    external pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(salt, EXTERNAL_HASH, deployer)
        );
        return Create2.computeAddress(_data, bytecodeHash, deployer);
    }

    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer)
    external view returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(salt, INTERNAL_HASH, deployer)
        );
        return Create2.computeAddress(_data, bytecodeHash);
    }
}