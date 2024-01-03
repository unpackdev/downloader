// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IBlockUpdater.sol";
import "./ICircuitVerifier.sol";

contract HecoBlockUpdater is IBlockUpdater, Initializable, OwnableUpgradeable {
    event ImportValidator(uint256 indexed epoch, uint256 indexed blockNumber, bytes32 blockHash, bytes32 receiptHash);
    event ModBlockConfirmation(uint256 oldBlockConfirmation, uint256 newBlockConfirmation);

    struct ParsedInput {
        uint256 blockNumber;
        uint256 epochValidatorCount;
        uint256 blockConfirmation;
        bytes32 blockHash;
        bytes32 receiptHash;
        bytes32 signingValidatorSetHash;
        bytes32 epochValidatorSetHash;
    }

    struct ZkProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[] inputs;
    }

    uint256 public minBlockConfirmation;

    uint256 public publicInputSize;

    IBlockUpdater public oldBlockUpdater;

    mapping(uint256 => ICircuitVerifier) public blockVerifier;

    // blockHash=>receiptsRoot =>BlockConfirmation
    mapping(bytes32 => mapping(bytes32 => uint256)) public blockInfos;


    function initialize( uint256 _minBlockConfirmation) public initializer {
        __Ownable_init();
        minBlockConfirmation = _minBlockConfirmation;
        publicInputSize = 11;
    }

    function importBlock(bytes calldata _proof) external {
        ZkProof memory proofData;
        (proofData.a, proofData.b, proofData.c, proofData.inputs) = abi.decode(_proof, (uint256[2], uint256[2][2], uint256[2], uint256[]));

        uint256 blockSize = proofData.inputs.length / publicInputSize;
        require(blockSize * publicInputSize == proofData.inputs.length, "invalid public input size");

        ICircuitVerifier circuitVerifier = blockVerifier[blockSize];
        require(address(circuitVerifier) != address(0), "not set verifier");

        uint256[1] memory compressInput;
        compressInput[0] = _hashInput(proofData.inputs);
        require(circuitVerifier.verifyProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");

        ParsedInput[] memory parsedInputs = _parseInput(proofData.inputs, blockSize);
        for (uint256 i = 0; i < blockSize; i++) {
            if (i > 0 && parsedInputs[i].blockHash == parsedInputs[i - 1].blockHash) {
                break;
            }
            _importBlock(parsedInputs[i]);
        }
    }

    function checkBlock(bytes32 _blockHash, bytes32 _receiptHash) external view returns (bool) {
        (bool exist,) = _checkBlock(_blockHash, _receiptHash);
        return exist;
    }

    function checkBlockConfirmation(bytes32 _blockHash, bytes32 _receiptHash) external view returns (bool, uint256) {
        return _checkBlock(_blockHash, _receiptHash);
    }

    function _checkBlock(bytes32 _blockHash, bytes32 _receiptHash) internal view returns (bool, uint256) {
        uint256 blockConfirmation = blockInfos[_blockHash][_receiptHash];
        if (blockConfirmation > 0) {
            return (true, blockConfirmation);
        }
        if (address(oldBlockUpdater) != address(0)) {
            return oldBlockUpdater.checkBlockConfirmation(_blockHash, _receiptHash);
        }
        return (false, 0);
    }

    function _importBlock(ParsedInput memory parsedInput) internal {
        require(parsedInput.blockConfirmation >= minBlockConfirmation, "Not enough block confirmations");
        (bool exist,uint256 blockConfirmation) = _checkBlock(parsedInput.blockHash, parsedInput.receiptHash);
        if (exist && parsedInput.blockConfirmation <= blockConfirmation) {
            revert("already exist");
        }
        blockInfos[parsedInput.blockHash][parsedInput.receiptHash] = parsedInput.blockConfirmation;
        emit ImportBlock(parsedInput.blockNumber, parsedInput.blockHash, parsedInput.receiptHash);
    }


    function _parseInput(uint256[] memory _inputs, uint256 _blockSize) internal pure returns (ParsedInput[] memory)    {
        uint256 index = 0;
        ParsedInput[] memory result = new ParsedInput[](_blockSize);
        for (uint256 i = 0; i < _blockSize; i++) {
            result[i].blockNumber = _inputs[index];
            index++;
            result[i].blockHash = bytes32((_inputs[index + 1] << 128) | _inputs[index]);
            index += 2;
            result[i].receiptHash = bytes32((_inputs[index + 1] << 128) | _inputs[index]);
            index += 2;
            result[i].signingValidatorSetHash = bytes32((_inputs[index + 1] << 128) | _inputs[index]);
            index += 2;
            result[i].epochValidatorSetHash = bytes32((_inputs[index + 1] << 128) | _inputs[index]);
            index += 2;
            result[i].epochValidatorCount = _inputs[index];
            index++;
            result[i].blockConfirmation = _inputs[index];
            index++;
        }
        return result;
    }

    function _hashInput(uint256[] memory _inputs) internal pure returns (uint256) {
        uint256 n = _inputs.length;
        uint256 inputLength = n * 32;
        bytes memory packedInputs;
        assembly {
            packedInputs := mload(0x40) // Get the free memory pointer
            mstore(0x40, add(packedInputs, add(inputLength, 0x20))) // Update the free memory pointer

            let inputOffset := packedInputs
            mstore(inputOffset, inputLength) // Store the length of the concatenated inputs
            inputOffset := add(inputOffset, 0x20) // Move the pointer to the start of the concatenated inputs

            for {let i := 0} lt(i, n) {i := add(i, 1)} {
                let inputValue := mload(add(_inputs, mul(add(i, 1), 0x20))) // Load the input value
                mstore(inputOffset, inputValue) // Store the input value at the current offset
                inputOffset := add(inputOffset, 0x20) // Move the pointer to the next position
            }
        }
        uint256 computedHash = uint256(keccak256(packedInputs));
        return computedHash / 256;
    }

    function _computeEpoch(uint256 _blockNumber) internal pure returns (uint256) {
        return _blockNumber / 200;
    }

    //----------------------------------------------------------------------------------
    // onlyOwner
    function setBlockConfirmation(uint256 _minBlockConfirmation) external onlyOwner {
        emit ModBlockConfirmation(minBlockConfirmation, _minBlockConfirmation);
        minBlockConfirmation = _minBlockConfirmation;
    }

    function setOldBlockUpdater(address _oldBlockUpdater) external onlyOwner {
        oldBlockUpdater = IBlockUpdater(_oldBlockUpdater);
    }

    function setPublicInputSize(uint256 _publicInputSize) external onlyOwner {
        publicInputSize = _publicInputSize;
    }

    function setVerifier(uint256 _blockSize, address _blockVerifier) external onlyOwner {
        blockVerifier[_blockSize] = ICircuitVerifier(_blockVerifier);
    }
}