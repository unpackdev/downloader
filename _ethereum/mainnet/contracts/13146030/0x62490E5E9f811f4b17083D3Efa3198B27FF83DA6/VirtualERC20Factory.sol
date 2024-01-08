// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./ERC20BaseToken.sol";
import "./VERCHelper.sol";

/// @notice This contract implements deteministic ERC-20 deployements. Used for Habitat V(irtual) ERC-20.
contract VirtualERC20Factory is ERC20BaseToken, VERCHelper {
  event Erc20Created(address indexed proxy);

  bool _initialized;

  /// @notice Returns the metadata of this (MetaProxy) contract.
  /// Only relevant with contracts created via the MetaProxy.
  /// @dev This function is aimed to be invoked with- & without a call.
  function getMetadata () public pure returns (
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 _totalSupply,
    bytes32 _domainSeparator
  ) {
    assembly {
      function stringcopy (_calldataPtr) -> calldataPtr, memPtr {
        calldataPtr := _calldataPtr

        let paddedLen := add(
          // len of bytes
          32,
          // roundup
          mul(
            div(
              add(calldataload(calldataPtr), 31),
              32
            ),
            32
          )
        )
        memPtr := mload(64)
        mstore(64, add(memPtr, paddedLen))
        calldatacopy(memPtr, calldataPtr, paddedLen)
        calldataPtr := add(calldataPtr, paddedLen)
      }

      // calldata layout:
      // [ arbitrary data... ] [ metadata... ] [ size of metadata 32 bytes ]
      let sizeOfPos := sub(calldatasize(), 32)
      let calldataPtr := sub(sizeOfPos, calldataload(sizeOfPos))
      // skip the first 64 bytes (abi encoded stuff)
      calldataPtr := add(calldataPtr, 64)

      _decimals := calldataload(calldataPtr)
      calldataPtr := add(calldataPtr, 32)

      _totalSupply := calldataload(calldataPtr)
      calldataPtr := add(calldataPtr, 32)

      _domainSeparator := calldataload(calldataPtr)
      calldataPtr := add(calldataPtr, 32)

      // copy token name to memory
      calldataPtr, _name := stringcopy(calldataPtr)
      // copy token symbol to memory
      calldataPtr, _symbol := stringcopy(calldataPtr)
    }
  }

  /// @notice VERC MetaProxy construction via calldata.
  function createProxy (
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 _totalSupply,
    bytes32 _domainSeparator
  ) external returns (address addr) {

    // create the proxy first
    addr = _metaProxyFromCalldata();
    require(addr != address(0), 'CP1');
    emit Erc20Created(addr);

    bytes32 tokenNameHash = keccak256(bytes(_name));
    bytes32 ret;
    assembly {
      // load free memory ptr
      let ptr := mload(64)
      // keep a copy to calculate the length later
      let start := ptr

      // we can't include `address verifyingContract`
      // keccak256('EIP712Domain(string name,uint256 chainId)')
      mstore(ptr, 0xcc85e4a69ca54da41cc4383bb845cbd1e15ef8a13557a6bed09b8bea2a0d92ff)
      ptr := add(ptr, 32)

      // see tokenNameHash
      mstore(ptr, tokenNameHash)
      ptr := add(ptr, 32)

      // store chainid
      mstore(ptr, chainid())
      ptr := add(ptr, 32)

      // hash
      ret := keccak256(start, sub(ptr, start))
    }
    // verify DOMAIN_SEPARATOR
    require(ret == _domainSeparator, 'CP2');

    VirtualERC20Factory(addr).init(_INITIAL_OWNER());
  }

  /// @notice Based on EIP-3448
  /// @dev Creates a child with metadata from calldata.
  /// Copies everything from calldata except the first 4 bytes.
  /// @return addr address(0) on error, else the address of the new contract (proxy)
  function _metaProxyFromCalldata () internal returns (address addr) {
    uint256 metadataSize;
    assembly {
      metadataSize := sub(calldatasize(), 4)
    }
    bytes memory initCode = VERCHelper._getInitCodeForVERC(address(this), 4, metadataSize);
    assembly {
      let start := add(initCode, 32)
      let size := mload(initCode)
      addr := create2(0, start, size, 0)
    }
  }

  /// @dev The address who receives the `totalSupply` on `init`.
  function _INITIAL_OWNER () internal view virtual returns (address) {
  }

  /// @notice Initializes and mints the total supply to the `_initialOwner`.
  function init (address _initialOwner) external {
    require(_initialized == false, 'S1');

    _initialized = true;

    (,,,uint256 _totalSupply,) = getMetadata();
    _balances[_initialOwner] = _totalSupply;

    emit Transfer(address(0), _initialOwner, _totalSupply);
  }

  /// @notice Returns the name of token.
  function name () public virtual view returns (string memory) {
    (string memory _name,,,,) = getMetadata();
    return _name;
  }

  /// @notice Returns the symbol of the token.
  function symbol () public virtual view returns (string memory) {
    (,string memory _symbol,,,) = getMetadata();
    return _symbol;
  }

  /// @notice Returns the decimal place of the token.
  function decimals () public virtual view returns (uint8) {
    (,,uint8 _decimals,,) = getMetadata();
    return _decimals;
  }

  /// @notice Returns the DOMAIN_SEPARATOR. See EIP-2612.
  function DOMAIN_SEPARATOR () public virtual override view returns (bytes32) {
    (,,,,bytes32 _domainSeparator) = getMetadata();
    return _domainSeparator;
  }

  /// @notice Returns the total supply of this token.
  function totalSupply () public virtual view returns (uint256) {
    (,,,uint256 _totalSupply,) = getMetadata();
    return _totalSupply;
  }
}
