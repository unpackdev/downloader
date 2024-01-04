import "./DropletWrapper.sol";

contract DropletWrapperMainnet is DropletWrapper {
  address _droplet;

  /// @notice Can only be set by the `OWNER`.
  /// Works only once after setting a non-zero address.
  function setDroplet (address droplet) external {
    require(msg.sender == OWNER());
    require(_droplet == address(0));

    _droplet = droplet;
  }

  function DROPLET () internal view override returns (address) {
    return _droplet;
  }

  function OWNER () internal view override returns (address) {
    // multisig
    return 0xc97f82c80DF57c34E84491C0EDa050BA924D7429;
  }

  function SOURCE_TOKEN () internal view override returns (address) {
    // HBT
    return 0x0aCe32f6E87Ac1457A5385f8eb0208F37263B415;
  }

  function ACTIVATION_DELAY () internal view override returns (uint256) {
    // 2 weeks
    return 1209600;
  }
}
