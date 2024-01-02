pragma solidity 0.8.22;

// Interface for the Factory contract.
interface IFactory {
    // Declares a function to deploy a new signer instance.
    // @param _hash: A unique identifier for the signer.
    // @param _x: X-coordinate of the public key.
    // @param _y: Y-coordinate of the public key.
    // @return bool: Returns true if deployment is successful.
    function deploy(bytes32 _hash, uint256 _x, uint256 _y) external returns (bool);
}

/**
 * @title IntermediateCaller
 * @dev A contract that serves as an intermediate caller to the Factory contract.
 */
contract IntermediateCaller {
    // Immutable address of the Factory contract.
    address public immutable factory;

    // Constructor to set the Factory contract's address.
    // @param _factory: The address of the Factory contract.
    constructor(address _factory) {
        factory = _factory;
    }

    // Function to deploy a signer through the Factory contract.
    // This allows external contracts or addresses to request signer deployments.
    // @param _hash: A unique identifier for the signer.
    // @param _x: X-coordinate of the public key.
    // @param _y: Y-coordinate of the public key.
    // @return bool: Returns true if deployment is successful.
    function deploySigner(bytes32 _hash, uint256 _x, uint256 _y) external returns (bool) {
        // Calls the deploy function of the Factory contract.
        return IFactory(factory).deploy(_hash, _x, _y);
    }
}
