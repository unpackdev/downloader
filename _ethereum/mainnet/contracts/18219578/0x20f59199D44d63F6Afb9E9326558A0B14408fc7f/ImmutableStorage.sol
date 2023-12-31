// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * data contracts implement this interface if structGetter=false
 */
interface IImmutableGetter {
  function get() external view returns (bytes memory);
}

library ImmutableStoragePub { 
  function saveStruct(bytes memory data) external returns (address dataContract)  {
    return ImmutableStorage.saveStruct(data);
  }

  function save(bytes memory data, uint16 seed, bool structGetter) external returns (bytes32 key, bool reused)  {
    return ImmutableStorage.save(data, seed, structGetter);
  }
}

library ImmutableStorage {
  /* executable code word contains constructor code + runtime code + shared code + seed
   * constructor returns runtime code + shared code + seed + data
   * runtime returns just data or data_pos + data_len + data (depending on structGetter)
   *
   * offset                   opcode      name                                stack
   * --- constructor code start
   * 00                       3d          RETURNDATASIZE = PUSH1 0            [0]
   * 01                       3d          RETURNDATASIZE = PUSH1 0            [0, 0]
   * 02                       6007        PUSH1 DEPL_CODE_PTR=0x07            [DEPL_CODE_PTR, 0, 0]
   * 04                       6010        PUSH1 PC=JUMPDEST=0x10              [PC, DEPL_CODE_PTR, 0, 0]
   * 06                       56          JUMP                                [DEPL_CODE_PTR, 0, 0]
   * --- deployed code start
   * 07 (DEPL_CODE_PTR)       60          PUSH1 MSTORE_OFFSET                 [MSTORE_OFFSET] // MSTORE_OFFSET = 0 or (0x20 + padding)
   * 08 (MSTORE_OFFSET_PTR)   MO                                 
   * 09                       80          DUP1 { A }                          [MSTORE_OFFSET, MSTORE_OFFSET]
   * 0a                       3d          RETURNDATASIZE = PUSH1 0            [0, MSTORE_OFFSET, MSTORE_OFFSET]
   * 0b                       52          MSTORE {offset, value}              [MSTORE_OFFSET]

   * 0c                       60          PUSH1 DEST_OFFSET                   [DEST_OFFSET, MSTORE_OFFSET] // DEST_OFFSET = 0 or (0x40 + padding)
   * 0d (DEST_OFFSET_PTR)     DO
   * 0e                       6019        PUSH1 DATA_OFFSET=0x19              [DATA_OFFSET, DEST_OFFSET, MSTORE_OFFSET]     // DATA_OFFSET = END - DEPL_CODE_PTR
   * --- shared code start
   * 10 (JUMPDEST)            5b          JUMPDEST                            [SRC_OFFSET, DEST_OFFSET, MSTORE_OFFSET]
   * 11                       80          DUP1 { A }                          [SRC_OFFSET, SRC_OFFSET, DEST_OFFSET, MSTORE_OFFSET]
   * 12                       38          CODESIZE                            [CODE_SIZE, SRC_OFFSET, SRC_OFFSET, DEST_OFFSET, MSTORE_OFFSET]
   * 
   * 13                       03          SUB {a, b}                          [COPY_SIZE, SRC_OFFSET, DEST_OFFSET, MSTORE_OFFSET]
   * 14                       80          DUP1 { A }                          [COPY_SIZE, COPY_SIZE, SRC_OFFSET, DEST_OFFSET, MSTORE_OFFSET]
   * 15                       84          DUP5 { a, b, c, d, E }              [MSTORE_OFFSET, COPY_SIZE, COPY_SIZE, SRC_OFFSET, DEST_OFFSET, ...]
   * 16                       52          MSTORE {offset, value}              [COPY_SIZE, SRC_OFFSET, DEST_OFFSET]       // save data size. Only needed in deployed code, result rewritten in create code
   * 
   * 17                       80          DUP1 { A }                          [COPY_SIZE, COPY_SIZE, SRC_OFFSET, DEST_OFFSET]
   * 18                       91          SWAP2 { A, b, C }                   [SRC_OFFSET, COPY_SIZE, COPY_SIZE, DEST_OFFSET]
   * 19                       83          DUP4  { a, b, c, D }                [DEST_OFFSET, SRC_OFFSET, COPY_SIZE, COPY_SIZE, DEST_OFFSET]
   * 1a                       39          CODECOPY {destOffset, offset, size} [COPY_SIZE, DEST_OFFSET]
   * 
   * 1b                       01          ADD {a, b}                          [RETURN_SIZE]
   * 1c                       3d          RETURNDATASIZE = PUSH1 0            [0, RETURN_SIZE]
   * 1d                       f3          RETURN { offset, size }             []
   * 1e                       SEED        never executed
   * 20 (END)                 DATADATADATADATADATADATADATA          
   */
  bytes32 constant CODE = 0x3d3d60076010566000803d52600060195b80380380845280918339013df30000;
  uint constant DEPL_CODE_PTR = 0x07;
  uint constant MSTORE_OFFSET_PTR = 0x08;
  uint constant DEST_OFFSET_PTR = 0x0d;
  uint constant WORD = 0x20;
  uint constant RUNCODE_SIZE = 0x19; // = WORD - DEPL_CODE_PTR;

  event RecordCreated(address indexed dataContract);

  function _prepare(bytes memory data, uint16 seed, bool structGetter) private pure returns(bytes32 code, uint length, uint salt) {
    length = data.length;
    require(length > 0, "#IS: zero length");
    code = CODE;
    if (structGetter) {
      require(length % WORD == 0, "#IS: wrong length");
    } else {
      uint padding = (WORD - uint8(length % WORD)) % WORD;
      //and(add(length, 0x3f), not(0x1f))
      bytes memory codeBytes = bytes.concat(code);
      codeBytes[MSTORE_OFFSET_PTR] = bytes1(uint8(WORD + padding));
      codeBytes[DEST_OFFSET_PTR] = bytes1(uint8(WORD + WORD + padding));
      code = bytes32(codeBytes);
    }

    salt = uint(seed);
    code = code | bytes32(salt);
  }
  
  function getAddr(bytes memory data, uint16 seed, bool structGetter, address deployer) internal pure returns(address) {
    (bytes32 code, uint length, uint salt) = _prepare(data, seed, structGetter);
    bytes32 codeHash;
    
    assembly {
      mstore(data, code)
      codeHash := keccak256(data, add(length, WORD))
      mstore(data, length)
    }

    bytes32 deploymentHash = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, codeHash));
    return address(bytes20(deploymentHash << 96));
  }

  function getLength(address dataContract) internal view returns(uint length, uint codelength) {
    assembly {
      codelength := extcodesize(dataContract)
    }
    if (codelength > RUNCODE_SIZE) {
      length = codelength - RUNCODE_SIZE;
    }
  }

  /**
   * Simply saves struct as a contract
   * @param data bytes to save. Bytes should be prepared with abi.encode(someStruct)
   * @return dataContract address of data contract. The contract implements struct getter.
   */
  function saveStruct(bytes memory data) internal returns (address dataContract)  {
    (bytes32 key, ) = save(data, 0, true);
    dataContract = address(bytes20(key));
  }

  /** Simply saves bytes as a contract
   * @param data bytes to save
   * @return dataContract address of data contract. The contract implements IImmutableGetter.
   */
  function saveBytes(bytes memory data) internal returns (IImmutableGetter dataContract)  {
    (bytes32 key, ) = save(data, 0, false);
    dataContract = IImmutableGetter(address(bytes20(key)));
  }

  /**
   * Saves bytes as a contract
   * @param data bytes to save
   * @param seed seed allowing to create different contracts with same data. Also can be used as additional 2 bytes of data.
   * @param structGetter calls to data contract will return struct instead of just bytes if structGetter is true
   * @return key address and optional length of data contract
   * @return reused true if data contract already exists
   */
  function save(bytes memory data, uint16 seed, bool structGetter) internal returns (bytes32 key, bool reused)  {
    (bytes32 code, uint length, uint salt) = _prepare(data, seed, structGetter);
    address dataContract;
    assembly {
      mstore(data, code)
      dataContract := create2(0, data, add(length, WORD), salt)
      mstore(data, length)
    }

    reused = dataContract == address(0);
    if (reused){
      dataContract = getAddr(data, seed, structGetter, address(this));
      (length, ) = getLength(dataContract);
      require(length == data.length, "#IS: not saved. Low gas?");
    } else {
      emit RecordCreated(dataContract);
    }
    if (length >= type(uint96).max) {
      length = 0;
    }
    key = bytes32(bytes20(dataContract)) | bytes32(length);
  }

  /**
   * Simply loads bytes from a data contract. 
   * @param dataContract address of data contract
   * @return data 
   */
  function loadBytes(address dataContract) internal view returns (bytes memory data) { 
    return quickLoad(bytes32(bytes20(dataContract)));
  }

  /**
   * Loads bytes from a data contract. Validates that data contract was created by deployer.
   * @param key address and optional length of data contract. Saves >100 gas if length is specified. 
   * @param deployer optional address of data contract creator. Validation is done if deployer is specified. 
   * @return data data loaded
   * @return seed seed used in data contract creation
   */
  function load(bytes32 key, address deployer) internal view returns (bytes memory data, uint16 seed) {  
    address dataContract;
    uint length;
    assembly {
      let mask := shl(96, 1)
      dataContract := div(key, mask)
      length := mod(key, mask)
    }
    uint codelength;
    if (length == 0) {
      (length, codelength) = getLength(dataContract);
      require(length > 0, "#IS: empty store");
    } else {
      codelength = length + RUNCODE_SIZE;
    }

    bytes32 codeHash;
    uint salt;
    assembly {
      data := mload(0x40)
      mstore(0x40, add(data, 
        and(add(length, 0x3f), not(0x1f)) // memory size occupied by data including padding
      ))
      mstore(data, CODE) // use CODE for deployment code
      extcodecopy(dataContract, add(data, DEPL_CODE_PTR), 0, codelength) // copy runtime code with overwriting
      salt := and(mload(data), 0xffff)
      if gt(shl(0x60, deployer), 0) {
        codeHash := keccak256(data, add(length, WORD))
      }
      mstore(data, length)
    }

    if (deployer != address(0)) {
      bytes32 deploymentHash = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, codeHash));
      address computedAddress = address(bytes20(deploymentHash << 96));
      require(computedAddress == dataContract, "#IS: invalid store");
    } 

    seed = uint16(salt);
  }

  /**
     * Loads bytes from a data contract using minimum gas
     * @param key address and optional length of data contract. Saves >100 gas if length is specified. 
     * @return data data loaded
     */
  function quickLoad(bytes32 key) internal view returns (bytes memory data) {  
    address dataContract;
    uint length;
    assembly {
      let mask := shl(96, 1)
      dataContract := div(key, mask)
      length := mod(key, mask)
    }
    if (length == 0) {
      (length, ) = getLength(dataContract);
      require(length > 0, "#IS: empty store");
    }
    assembly {
      data := mload(0x40)
      mstore(0x40, add(data, 
        and(add(length, 0x3f), not(0x1f)) // memory size occupied by data including padding
      ))
      extcodecopy(dataContract, add(data, WORD), RUNCODE_SIZE, length) // copy runtime code
      mstore(data, length)
    }
  }
}