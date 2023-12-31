// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Create2.sol";
import "./Ownable.sol";
import "./AccessControl.sol";


contract Create2Deployer is Ownable, AccessControl {
    error CannotBeZeroAddress();
    error TransferNotAllowed();

    event ContractDeployed(address contract_);

    bytes32 public constant PROXY_EXECUTOR = keccak256("PROXY_EXECUTOR");

    constructor(address owner)  {
        require(owner != address(0));
        address[] memory accounts = new address[](1);
        accounts[0] = owner;
        addExecutors(accounts);
        _transferOwnership(owner);
    }

    struct Call {
        address target;
        bytes callData;
    }

    /// @notice Add accounts which can execute transactions
    /// @param accounts The accounts to add
    function addExecutors(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _grantRole(PROXY_EXECUTOR, accounts[i]);
        }
    }

    /// @notice Remove accounts which can execute transactions
    /// @param accounts The accounts to remove
    function removeExecutors(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _revokeRole(PROXY_EXECUTOR, accounts[i]);
        }
    }

    /**
     * @dev Deploys a contract using `CREATE2`. The address where the
     * contract will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `value`.
     * - if `value` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 value, bytes32 salt, bytes memory code) public onlyRole(PROXY_EXECUTOR) {
        address addr = Create2.deploy(value, salt, code);
        emit ContractDeployed(addr);
    }

    /// @notice Relay a call via this contract
    /// @param target The target address to call
    /// @param callData The call data to pass to the target
    /// @return The return value from the call
    function execute(address target, bytes calldata callData) external onlyRole(PROXY_EXECUTOR) returns (bytes memory) {
        return _executeInternal(target, callData);
    }

    /// @notice Relay multiple call via this contract. This will revert payable actions, ie sending msg.value.
    /// @param calls Array of calls to execute
    /// @return returnData The return value from the call
    function execute(Call[] calldata calls) external onlyRole(PROXY_EXECUTOR) returns (bytes[] memory returnData) {
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            returnData[i] = _executeInternal(calls[i].target, calls[i].callData);
        }
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}.
     * Any change in the `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 codeHash) public view returns (address) {
        return Create2.computeAddress(salt, codeHash);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a
     * contract located at `deployer`. If `deployer` is this contract's address, returns the
     * same value as {computeAddress}.
     */
    function computeAddressWithDeployer(
        bytes32 salt,
        bytes32 codeHash,
        address deployer
    ) public pure returns (address) {
        return Create2.computeAddress(salt, codeHash, deployer);
    }


    function _executeInternal(address target, bytes memory callData) internal returns (bytes memory returnData) {
        (bool success, bytes memory ret) = target.call(callData);
        if (success != true) {
            if (ret.length < 68) revert();
            assembly {
                ret := add(ret, 0x04)
            }
            revert(abi.decode(ret, (string)));
        }
        return ret;
    }

    /**
     * @dev The contract can receive ether to enable `payable` constructor calls if needed.
     */
    receive() external payable {}

}
