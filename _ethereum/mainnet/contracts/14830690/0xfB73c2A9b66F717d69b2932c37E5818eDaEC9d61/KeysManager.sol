//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoreRef.sol";
import "./IKeysManager.sol";
import "./IStakingPool.sol";

/// @title Keys manager contract
/// @author ...
/// @notice Contract for on managing public keys, signatures
contract KeysManager is IKeysManager, CoreRef {
    mapping(bytes => Validator) public _validators;

    uint256 public constant PUBKEY_LENGTH = 48;
    uint256 public constant SIGNATURE_LENGTH = 96;
    uint256 public constant VALIDATOR_DEPOSIT = 31e18;

    event AddValidator(bytes publicKey, bytes signature, address nodeOperator);
    event ActivateValidator(bytes[] publicKey);
    event DepositValidator(bytes publicKey);

    mapping (address => uint256) public override nodeOperatorValidatorCount;



    /// @notice constructor to initialize Core
    /// @param _core address of the core
    constructor(address _core) public CoreRef(_core) {}



    /// @notice function that returns public key of a particular validator.
    /// @param publicKey public key of the validator.
    function validators(bytes calldata publicKey)
        external
        view
        override
        returns (Validator memory)
    {
        return _validators[publicKey];
    }


    /// @notice function to add a new validator
    /// @param publicKey public key of the validator
    /// @param signature signature with private key needed for eth2 deposit
    /// @param nodeOperator address of the node operator
    function addValidator(
        bytes calldata publicKey,
        bytes calldata signature,
        address nodeOperator
    ) external override onlyNodeOperator {
        Validator memory _validator = _validators[publicKey];
        require(
            _validator.state == State.INVALID,
            "KeysManager: validator already exist"
        );

        _validator.state = State.VALID;
        _validator.signature = signature;
        _validator.nodeOperator = nodeOperator;
        _validator.deposit_root = calculateDepositDataRoot(publicKey, signature);

        _validators[publicKey] = _validator;
        emit AddValidator(publicKey, signature, nodeOperator);
    }




    /// @notice function for activating the status of an array of validator public keys
    /// @param publicKeys public keys array of validators.
    function activateValidator(bytes[] memory publicKeys) external override {
        require(
            msg.sender == core().oracle(),
            "KeysManager: Only oracle can activate"
        );
        for (uint256 i = 0; i < publicKeys.length; i++) {
            Validator storage validator = _validators[publicKeys[i]];
            require(validator.state == State.VALID, "KeysManager: Validator not in valid state");
            validator.state = State.ACTIVATED;
        }
        emit ActivateValidator(publicKeys);
    }



    /// @notice set status of validator to deposited
    /// @param publicKey public key of the validator.
    function depositValidator(bytes memory publicKey) external override {
        require(
            msg.sender == core().issuer(),
            "KeysManager: Only issuer can activate"
        );

        Validator storage validator = _validators[publicKey];
        
        require(
            IStakingPool(core().validatorPool()).numOfValidatorAllowed(validator.nodeOperator) > 
            nodeOperatorValidatorCount[validator.nodeOperator],
            "KeysManager: validator deposit not added by node operator"
        );
        
        require(
            validator.state == State.ACTIVATED,
            "KeysManager: Key not activated"
        );
        validator.state = State.DEPOSITED;
        nodeOperatorValidatorCount[validator.nodeOperator] += 1;

        IStakingPool(core().validatorPool()).claimAndUpdateRewardDebt(validator.nodeOperator);

        emit DepositValidator(publicKey);
    }


    /// @notice function to return the deposit data root node
    /// @return depositRoot is deposit root node 
    function calculateDepositDataRoot(
        bytes calldata pubKey,
        bytes calldata signature
    ) internal returns (bytes32 depositRoot) {
        uint256 deposit_amount = VALIDATOR_DEPOSIT / 1 gwei;
        bytes memory amount = to_little_endian_64(uint64(deposit_amount));

        bytes32 withdrawal_credentials = core().withdrawalCredential();
        bytes32 pubkey_root = sha256(abi.encodePacked(pubKey, bytes16(0)));
        bytes32 signature_root = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(signature[:64])),
                sha256(abi.encodePacked(signature[64:], bytes32(0)))
            )
        );
        depositRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkey_root, withdrawal_credentials)),
                sha256(abi.encodePacked(amount, bytes24(0), signature_root))
            )
        );
        require(pubKey.length == 48, "DepositContract: invalid pubkey length");
        require(
            signature.length == 96,
            "DepositContract: invalid signature length"
        );
        require(
            withdrawal_credentials.length == 32,
            "DepositContract: invalid withdrawal_credentials length"
        );
        
    }


    /// @notice function to convert address to Bytes
    /// @param a address to be converted to bytes.
    function toBytes(address a) public pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }


    /// @notice function to convert to integer to little endian 64 bytes format.
    /// @param value is the integer number.
    /// @return ret is 8 byte array.
    function to_little_endian_64(uint64 value)
        internal
        pure
        returns (bytes memory ret)
    {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }
    

}
