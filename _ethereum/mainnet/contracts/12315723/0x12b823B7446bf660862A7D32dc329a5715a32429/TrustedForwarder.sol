// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./Address.sol";

import "./MinimalForwarder.sol";

contract TrustedForwarder is MinimalForwarder, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    mapping(address => bool) public registeredContracts;

    event ForwardRequestExecuted(address indexed from, uint256 nonce, bool success, bytes returnData);

    event RegisteredContracts(address[] contracts);

    event UnregisteredContracts(address[] contracts);

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "Must have appropriate role");
        _;
    }

    constructor(address admin, address relayer)
        MinimalForwarder("TrustedForwarder", "1.0.0")
    {

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(RELAYER_ROLE, admin);
        _setupRole(RELAYER_ROLE, relayer);
    }

    function verify(ForwardRequest calldata req, bytes calldata signature)
        public
        view
        override
        returns (bool)
    {
        require(registeredContracts[req.to], "Contract must be registered");

        return super.verify(req, signature);
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        override
        onlyRole(RELAYER_ROLE)
        returns (bool success, bytes memory ret)
    {

        (success, ret) = super.execute(req, signature);

        emit ForwardRequestExecuted(req.from, req.nonce, success, ret);
    }

    function registerContracts(address[] calldata contracts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < contracts.length; i++) {
            address _contract = contracts[i];
            require(_contract.isContract(), "Address must be contract");
            require(
                !registeredContracts[_contract],
                "Address is already registered"
            );
            registeredContracts[_contract] = true;
        }

        emit RegisteredContracts(contracts);
    }

    function unregisterContracts(address[] calldata contracts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < contracts.length; i++) {
            address _contract = contracts[0];
            require(
                registeredContracts[_contract],
                "Address is not registered"
            );
            registeredContracts[_contract] = false;
        }

        emit UnregisteredContracts(contracts);
    }

    function getChainId() public view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}
