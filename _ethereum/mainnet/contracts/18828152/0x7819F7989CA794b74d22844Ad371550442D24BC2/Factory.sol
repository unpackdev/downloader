pragma solidity 0.8.22;

import "./SignerProxy.sol";
import "./Signer.sol";
import "./IntermediateCaller.sol";
import "./SafeProxyFactory.sol";
import "./Safe.sol";

library FactoryErrors {
    error SaltDoesNotMatchSafe();
    error ImplementationNotDeployed();
    error ProxyNotDeployed();
}

/**
 * @title Factory
 * @dev A contract for creating instances of another contract.
 */
contract Factory {
    struct SignerData {
        uint256 x;
        uint256 y;
        address signer;
    }

    mapping(bytes32 => SignerData) internal signerData;

    event NewSignerCreated(address indexed proxy, uint256 _x, uint256 _y, address implementation);
    event NewFactorySetup(address INTERMEDIATE_CALLER);

    address public immutable INTERMEDIATE_CALLER;
    address public immutable IMPLEMENTATION;
    address internal constant SAFE_FACTORY = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;
    address internal constant SAFE_SINGLETON = 0xfb1bffC9d739B8D520DaF37dF666da4C687191EA;
    address internal constant SAFE_FALLBACK = 0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4;

    bytes4 internal constant SAFE_SETUP = 0xb63e800d;

    constructor() {
        INTERMEDIATE_CALLER = address(new IntermediateCaller(address(this)));
        IMPLEMENTATION = address(new Signer());
    }

    /**
     * @dev Deploys a new contract instance with the given parameters.
     * @param _hash The hash value to be passed to the deployed contract.
     * @param _x The x-coordinate value to be passed to the deployed contract.
     * @param _y The y-coordinate value to be passed to the deployed contract.
     * @return A boolean indicating the success of the deployment.
     */
    function deploy(bytes32 _hash, uint256 _x, uint256 _y) external returns (bool) {
        _deploy(IMPLEMENTATION, _hash, _x, _y);
        return true;
    }

    /**
     * @dev Deploys a new instance of a contract using the specified implementation and parameters.
     * @param _implementation The address of the contract implementation.
     * @param _hash The hash value.
     * @param _x The x-coordinate value.
     * @param _y The y-coordinate value.
     */
    function _deploy(address _implementation, bytes32 _hash, uint256 _x, uint256 _y)
        internal
        returns (address signer)
    {
        bytes32 salt = checkCaller(_implementation, _hash, _x, _y);

        signer = address(_deploySigner(_implementation, salt));
        Signer(signer).initialize(_x, _y);

        emit NewSignerCreated(signer, _x, _y, _implementation);

        signerData[_hash] = SignerData(_x, _y, signer);
    }

    /**
     * @dev Deploys a new SignerProxy contract using the specified implementation and salt.
     * @param _implementation The address of the implementation contract.
     * @param salt The salt value used for contract deployment.
     * @return proxy The deployed SignerProxy contract.
     */
    function _deploySigner(address _implementation, bytes32 salt) internal returns (SignerProxy proxy) {
        if (!isContract(_implementation)) revert FactoryErrors.ImplementationNotDeployed();

        bytes memory deploymentData =
            abi.encodePacked(type(SignerProxy).creationCode, uint256(uint160(_implementation)));

        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        /* solhint-enable no-inline-assembly */
        require(address(proxy) != address(0), "Create2 call failed");
    }

    /**
     * @dev Checks if the given address is a contract.
     * @param account The address to check.
     * @return A boolean value indicating whether the address is a contract or not.
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            size := extcodesize(account)
        }
        /* solhint-enable no-inline-assembly */
        return size > 0;
    }

    /**
     * @dev Checks if the caller of the function matches the specified implementation, hash, x, and y values.
     * @param _implementation The address of the implementation to check against.
     * @param _hash The hash value to check against.
     * @param _x The x value to check against.
     * @param _y The y value to check against.
     */
    function checkCaller(address _implementation, bytes32 _hash, uint256 _x, uint256 _y)
        internal
        view
        returns (bytes32)
    {
        bytes32 salt = keccak256(abi.encodePacked(_hash, _x, _y));
        address signer = _getAddress(_implementation, address(this), type(SignerProxy).creationCode, salt);
        address safe = _getSafeAddress(signer, _hash, _x, _y);

        if (msg.sender == safe) {
            return salt;
        } else {
            revert FactoryErrors.SaltDoesNotMatchSafe();
        }
    }

    /**
     * @dev Returns the address of the signer based on the provided hash and elliptic curve coordinates.
     * @param _hash The hash value used for signature verification.
     * @param _x The x-coordinate of the elliptic curve point.
     * @param _y The y-coordinate of the elliptic curve point.
     * @return The address of the signer.
     */
    function getSignerAddress(bytes32 _hash, uint256 _x, uint256 _y) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_hash, _x, _y));
        return _getAddress(IMPLEMENTATION, address(this), type(SignerProxy).creationCode, salt);
    }

    /**
     * @dev Retrieves the signer information for a given hash.
     * @param _hash The hash for which to retrieve the signer information.
     * @return x The x-coordinate of the signer's public key.
     * @return y The y-coordinate of the signer's public key.
     * @return signer The address of the signer.
     */
    function getSignerInfo(bytes32 _hash) external view returns (uint256 x, uint256 y, address signer) {
        SignerData memory data = signerData[_hash];
        (x, y, signer) = (data.x, data.y, data.signer);
    }

    /**
     * @dev Retrieves the safe address based on the signer, hash, x-coordinate, and y-coordinate.
     * @param _signer The address of the signer.
     * @param _hash The hash value.
     * @param _x The x-coordinate.
     * @param _y The y-coordinate.
     * @return The safe address.
     */
    function getSafeAddress(address _signer, bytes32 _hash, uint256 _x, uint256 _y) external view returns (address) {
        return _getSafeAddress(_signer, _hash, _x, _y);
    }

    /**
     * @dev Retrieves the safe address associated with a given hash.
     * @param _hash The hash for which to retrieve the safe address.
     * @return The safe address associated with the given hash.
     */
    function getSafeAddressbyHash(bytes32 _hash) external view returns (address) {
        SignerData storage data = signerData[_hash];
        return _getSafeAddress(data.signer, _hash, data.x, data.y);
    }

    /**
     * @dev Returns the safe address for a given signer, hash, x-coordinate, and y-coordinate.
     * @param _signer The address of the signer.
     * @param _hash The hash value.
     * @param _x The x-coordinate.
     * @param _y The y-coordinate.
     * @return The safe address.
     */
    function _getSafeAddress(address _signer, bytes32 _hash, uint256 _x, uint256 _y) internal view returns (address) {
        bytes memory data =
            abi.encodeWithSelector(IntermediateCaller(INTERMEDIATE_CALLER).deploySigner.selector, _hash, _x, _y);
        bytes memory safeSetup = _safeSetup(_signer, data, SAFE_FALLBACK, address(0), 0, payable(0));

        bytes memory creationCode = SafeProxyFactory(SAFE_FACTORY).proxyCreationCode();
        bytes32 salt = keccak256(abi.encodePacked(keccak256(safeSetup), uint256(uint160(_signer))));
        bytes memory deploymentData = abi.encodePacked(creationCode, uint256(uint160(SAFE_SINGLETON)));

        return _getAddress(SAFE_SINGLETON, SAFE_FACTORY, creationCode, salt);
    }

    /**
     * @dev Retrieves the address of a deployed contract instance based on the implementation address,
     * deployer address, bytecode, and salt.
     * 
     * @param _implementation The address of the contract implementation.
     * @param _deployer The address of the contract deployer.
     * @param _byteCode The bytecode of the contract.
     * @param _salt The salt used for contract deployment.
     * 
     * @return The address of the deployed contract instance.
     */
    function _getAddress(address _implementation, address _deployer, bytes memory _byteCode, bytes32 _salt)
        internal
        pure
        returns (address)
    {
        bytes memory deploymentData = abi.encodePacked(_byteCode, uint256(uint160(_implementation)));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), _deployer, _salt, keccak256(deploymentData)));
        return address(uint160(uint256(hash)));
    }

    /**
     * @dev Function to safely set up the contract.
     */
    function _safeSetup(
        address _owner,
        bytes memory _data,
        address _fallbackHandler,
        address _paymentToken,
        uint256 _payment,
        address payable _paymentReceiver
    ) internal view returns (bytes memory) {
        address[] memory signers = new address[](1);
        signers[0] = _owner;
        return abi.encodeWithSelector(
            SAFE_SETUP,
            signers,
            1,
            INTERMEDIATE_CALLER,
            _data,
            _fallbackHandler,
            _paymentToken,
            _payment,
            _paymentReceiver
        );
    }
}
