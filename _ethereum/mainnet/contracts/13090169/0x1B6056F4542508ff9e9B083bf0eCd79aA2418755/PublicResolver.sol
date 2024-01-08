pragma solidity >=0.8.4;

import "./ENS.sol";
import "./ABIResolver.sol";
import "./AddrResolver.sol";
import "./ContentHashResolver.sol";
import "./DNSResolver.sol";
import "./InterfaceResolver.sol";
import "./NameResolver.sol";
import "./PubkeyResolver.sol";
import "./TextResolver.sol";

interface INameWrapper {
  function ownerOf(uint256 id) external view returns (address);
}

/**'fis
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract PublicResolver is
  ABIResolver,
  AddrResolver,
  ContentHashResolver,
  DNSResolver,
  InterfaceResolver,
  NameResolver,
  PubkeyResolver,
  TextResolver
{
  ENS ens;
  INameWrapper nameWrapper;

  /**
   * A mapping of operators. An address that is authorised for an address
   * may make any changes to the name that the owner could, but may not update
   * the set of authorisations.
   * (owner, operator) => approved
   */
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Logged when an operator is added or removed.
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  constructor(address _ens, address wrapperAddress) {
    ens = ENS(_ens);
    nameWrapper = INameWrapper(wrapperAddress);
  }

  function isAuthorised(bytes32 node) internal view override returns (bool) {
    return msg.sender == addr(node);
  }

  function multicall(bytes[] calldata data)
    external
    returns (bytes[] memory results)
  {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      (bool success, bytes memory result) = address(this).delegatecall(data[i]);
      require(success);
      results[i] = result;
    }
    return results;
  }

  function supportsInterface(bytes4 interfaceID)
    public
    pure
    virtual
    override(
      ABIResolver,
      AddrResolver,
      ContentHashResolver,
      DNSResolver,
      InterfaceResolver,
      NameResolver,
      PubkeyResolver,
      TextResolver
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceID);
  }
}
