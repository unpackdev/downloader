pragma solidity ^0.7.6;

import "./ENS.sol";
import "./StealthKeyResolver.sol";

/**
 * A registrar that allocates StealthKey ready subdomains to the first person to claim them.
 * Based on the FIFSRegistrar contract here:
 * https://github.com/ensdomains/ens/blob/master/contracts/FIFSRegistrar.sol
 */
contract StealthKeyFIFSRegistrar {
    ENS public ens;
    bytes32 public rootNode;

    /**
     * Constructor.
     * @param _ens The address of the ENS registry.
     * @param _rootNode The node that this registrar administers.
     */
    constructor(ENS _ens, bytes32 _rootNode) {
        ens = _ens;
        rootNode = _rootNode;
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param _label The hash of the label to register.
     * @param _owner The address of the new owner.
     * @param _resolver The Stealth Key compatible resolver that will be used for this subdomain
     * @param _spendingPubKeyPrefix Prefix of the spending public key (2 or 3)
     * @param _spendingPubKey The public key for generating a stealth address
     * @param _viewingPubKeyPrefix Prefix of the viewing public key (2 or 3)
     * @param _viewingPubKey The public key to use for encryption
     */
    function register(
        bytes32 _label,
        address _owner,
        StealthKeyResolver _resolver,
        uint256 _spendingPubKeyPrefix,
        uint256 _spendingPubKey,
        uint256 _viewingPubKeyPrefix,
        uint256 _viewingPubKey
    ) public {
        // calculate the node for this subdomain
        bytes32 _node = keccak256(abi.encodePacked(rootNode, _label));

        // ensure the subdomain has not yet been claimed
        address _currentOwner = ens.owner(_node);
        require(_currentOwner == address(0x0), 'StealthKeyFIFSRegistrar: Already claimed');

        // temporarily make this contract the subnode owner to allow it to update the stealth keys
        ens.setSubnodeOwner(rootNode, _label, address(this));
        _resolver.setStealthKeys(_node, _spendingPubKeyPrefix, _spendingPubKey, _viewingPubKeyPrefix, _viewingPubKey);

        // transfer ownership to the registrant and set stealth key resolver
        ens.setSubnodeRecord(rootNode, _label, _owner, address(_resolver), 0);
    }
}
