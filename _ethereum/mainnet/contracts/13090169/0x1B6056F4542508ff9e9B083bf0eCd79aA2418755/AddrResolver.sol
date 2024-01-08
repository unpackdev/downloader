pragma solidity >=0.8.4;
import "./ResolverBase.sol";

abstract contract AddrResolver is ResolverBase {
  bytes4 private constant ADDR_INTERFACE_ID = 0x3b3b57de;
  bytes4 private constant ADDRESS_INTERFACE_ID = 0xf1cb7e06;
  uint256 constant COIN_TYPE_ETH = 60;

  event AddrChanged(bytes32 indexed node, address a);
  event AddressChanged(
    bytes32 indexed node,
    uint256 coinType,
    bytes newAddress
  );

  mapping(bytes32 => mapping(uint256 => bytes)) _addresses;

  /**
   * Returns the address associated with an ENS node.
   * @param node The ENS node to query.
   * @return The associated address.
   */
  function addr(bytes32 node) public view virtual returns (address payable) {
    bytes memory a = addr(node, COIN_TYPE_ETH);
    if (a.length == 0) {
      return payable(0);
    }
    return bytesToAddress(a);
  }

  function addr(bytes32 node, uint256 coinType)
    public
    view
    virtual
    returns (bytes memory)
  {
    return _addresses[node][coinType];
  }

  function supportsInterface(bytes4 interfaceID)
    public
    pure
    virtual
    override
    returns (bool)
  {
    return
      interfaceID == ADDR_INTERFACE_ID ||
      interfaceID == ADDRESS_INTERFACE_ID ||
      super.supportsInterface(interfaceID);
  }
}
