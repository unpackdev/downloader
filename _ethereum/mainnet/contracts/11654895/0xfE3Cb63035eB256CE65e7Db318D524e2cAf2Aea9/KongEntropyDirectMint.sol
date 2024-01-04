pragma solidity 0.5.2;

/***************
**            **
** INTERFACES **
**            **
***************/

/**
 * @title Interface for EllipticCurve contract.
 */
interface EllipticCurveInterface {

    function validateSignature(bytes32 message, uint[2] calldata rs, uint[2] calldata Q) external view returns (bool);

}

/**
 * @title Interface for Register contract.
 */
interface RegisterInterface {

  function getKongAmount(bytes32 hardwareHash) external view returns (uint);
  function verifyMintableHardwareHash(bytes32 primaryPublicKeyHash, bytes32 secondaryPublicKeyHash, bytes32 tertiaryPublicKeyHash, bytes32 hardwareSerial) external view returns (bytes32);
  function mintKong(bytes32 hardwareHash, address recipient) external;

}

/*********************************
**                              **
** ENTROPY DIRECT MINT CONTRACT **
**                              **
*********************************/

/**
 * @title Kong Entropy Contract.
 *
 * @dev   This contract can be presented with signatures for public keys registered in the
 *        `Register` contract. The function `submitEntropy()` verifies the validity of the
 *        signature using the remotely deployed `EllipticCurve` contract. If the signature
 *        is valid, the contract calls the `mintKong()` function of the `Register` contract
 *        to mint Kong.
 */
contract KongEntropyDirectMint {

    // Addresses of the contracts `Register` and `EllipticCurve`.
    address public _regAddress;
    address public _eccAddress;

    // Array storing hashes of signatures successfully submitted to submitEntropy() function.
    bytes32[] public _hashedSignaturesArray;

    // Length of _hashedSignaturesArray.
    uint256 public _hashedSignaturesIndex;

    // Mapping for minting status of keys.
    mapping(bytes32 => bool) public _mintedKeys;

    // Emits when submitEntropy() is successfully called.
    event Minted(
        bytes32 hardwareHash,
        bytes32 message,
        uint256 r,
        uint256 s
    );

    /**
     * @dev The constructor sets the addresses of the contracts `Register` and `EllipticCurve`.
     *
     * @param eccAddress           The address of the EllipticCurve contract.
     * @param regAddress           The address of the Register contract.
     */
    constructor(address eccAddress, address regAddress) public {

        _eccAddress = eccAddress;
        _regAddress = regAddress;

    }

    /**
     * @dev `submitEntropy()` can be presented with SECP256R1 signatures of public keys registered
     *      in the `Register` contract. When presented with a valid signature in the expected format,
     *      the contract calls the `mintKong()` function of `Register` to mint Kong token to `to`.

     *
     * @param primaryPublicKeyHash    Hash of the primary public key.
     * @param secondaryPublicKeyHash  Hash of the secondary public key.
     * @param hardwareSerial          Hash of the hardwareSerial number.
     * @param tertiaryPublicKeyX      The x-coordinate of the tertiary public key.
     * @param tertiaryPublicKeyY      The y-coordinate of the tertiary public key.
     * @param to                      Recipient.
     * @param blockNumber             Block number of the signed blockhash.
     * @param rs                      The array containing the r & s values fo the signature.
     */
    function submitEntropy(
        bytes32 primaryPublicKeyHash,
        bytes32 secondaryPublicKeyHash,
        bytes32 hardwareSerial,
        uint256 tertiaryPublicKeyX,
        uint256 tertiaryPublicKeyY,
        address to,
        uint256 blockNumber,
        uint256[2] memory rs
    )
        public
    {

        // Hash the provided tertiary key.
        bytes32 hashedKey = sha256(abi.encodePacked(tertiaryPublicKeyX, tertiaryPublicKeyY));

        // Hash all the keys in order to calculate the hardwareHash.
        bytes32 calculatedHardwareHash = sha256(abi.encodePacked(primaryPublicKeyHash, secondaryPublicKeyHash, hashedKey, hardwareSerial));

        // Verify that no signature has been submitted before for this key.
        require(_mintedKeys[calculatedHardwareHash] == false, 'Has already been minted.');

        // Verify that the primary key hash is registered and associated with a non-zero tertiary key hash.
        // Verify that the hash of the provided tertiary key coincides with the stored hash of the tertiary key.
        bytes32 compareHardwareHash = RegisterInterface(_regAddress).verifyMintableHardwareHash(primaryPublicKeyHash, secondaryPublicKeyHash, hashedKey, hardwareSerial);        

        // Require that the hashes match -- this check is redundant unless the Registry contract has a bug.
        require(calculatedHardwareHash == compareHardwareHash, 'Invalid parameter, hashes do not match.');

        // Get Kong amount; Divide internal representation by 10 ** 17 for cost scaling.
        uint scaledKongAmount = RegisterInterface(_regAddress).getKongAmount(calculatedHardwareHash) / uint(10 ** 17);

        // Perform work in proportion to scaledKongAmount.
        bytes32 powHash = blockhash(block.number);
        for (uint i=0; i < scaledKongAmount; i++) {
            powHash = keccak256(abi.encodePacked(powHash));
        }

        // Validate signature.
        bytes32 messageHash = sha256(abi.encodePacked(to, blockhash(blockNumber)));
        require(_validateSignature(messageHash, rs, tertiaryPublicKeyX, tertiaryPublicKeyY), 'Invalid signature.');

        // Create a hash of the provided signature.
        bytes32 sigHash = sha256(abi.encodePacked(rs[0], rs[1]));

        // Store hashed signature and update index / length of array.
        _hashedSignaturesIndex = _hashedSignaturesArray.push(sigHash);

        // Update mapping with minted keys.
        _mintedKeys[calculatedHardwareHash] = true;

        // Call minting function in Register contract.
        RegisterInterface(_regAddress).mintKong(calculatedHardwareHash, to);

        // Emit event.
        emit Minted(calculatedHardwareHash, messageHash, rs[0], rs[1]);
    }

    /**
     * @dev Function to validate SECP256R1 signatures.
     *
     * @param message           The hash of the signed message.
     * @param rs                R+S value of the signature.
     * @param publicKeyX        X-coordinate of the publicKey.
     * @param publicKeyY        Y-coordinate of the publicKey.
     */
    function _validateSignature(
        bytes32 message,
        uint256[2] memory rs,
        uint256 publicKeyX,
        uint256 publicKeyY
    )
        internal view returns (bool)
    {
        return EllipticCurveInterface(_eccAddress).validateSignature(message, rs, [publicKeyX, publicKeyY]);
    }

    /**
     * @dev Function to return the submitted signatures at location `index` in the array of
     *      signatures.
     *
     * @param index             Location of signature in array of hashed signatures.
     */
    function getHashedSignature(
        uint256 index
    )
        public view returns(bytes32)
    {
        require(index <= _hashedSignaturesIndex - 1, 'Invalid index.');
        return _hashedSignaturesArray[index];
    }

}