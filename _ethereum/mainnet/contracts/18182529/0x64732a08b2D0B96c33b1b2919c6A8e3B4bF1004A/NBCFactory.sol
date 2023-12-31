// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Clones.sol";
import "./AccessControl.sol";
import "./NBCStructsAndEnums.sol";
import "./NBC721Cloneable.sol";

contract NBCCloneFactory is AccessControl {
  address public NBCPayableAddress = address(0x61566435CFf27FfbF813BD0E15b70428E3AF38e4);
  uint256 public NBCPrimarySaleShare = 5;
  address private drop721Impl;
  
  event ContractCreated(address creator, address contractAddress);
  
  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    NBC721Cloneable impl = new NBC721Cloneable();
    Init721Params memory _initParams = Init721Params(0, address(0), '', SaleMode.Standard, true, false, address(0), 0);
    address[] memory psAddresses = new address[](1);
    psAddresses[0] = NBCPayableAddress;
    uint256[] memory psShares = new uint256[](1);
    psShares[0] = 100;
    impl.initialize(
      "",
      "",
      _initParams,
      psAddresses,
      psShares,
      address(this)
    );
    drop721Impl = address(impl);
  }

  function update721Implementation(address newImplementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
    drop721Impl = newImplementation;
  }

  function get721ImplementationAddress() external view returns (address) {
    return drop721Impl;
  }

  function deployNBC721Clone(
    string memory _name,
    string memory _symbol,
    Init721Params calldata _initParams,
    address[] calldata _psAddresses,
    uint256[] calldata _psShares
  ) external {
    require(drop721Impl != address(0), "Implementation not set");
    address payable clone = payable(Clones.clone(drop721Impl));

    uint256 sharesTotal = 0;
    uint256 psLength = _psAddresses.length + 1;
    address[] memory psAddresses = new address[](psLength);
    uint256[] memory psShares = new uint256[](psLength);
    for (uint256 i = 0; i < psLength; ) {
      if (i == psLength - 1) {
        psAddresses[i] = NBCPayableAddress;
        psShares[i] = NBCPrimarySaleShare;
        sharesTotal += NBCPrimarySaleShare;
      } else {
        psAddresses[i] = _psAddresses[i];
        psShares[i] = _psShares[i];
        sharesTotal += _psShares[i];
      }
      
      unchecked {
        ++i;
      }
    }

    if (sharesTotal > 100) {
      revert InvalidPaymentSplitterSettings();
    }

    NBC721Cloneable(clone).initialize(
      _name,
      _symbol,
      _initParams,
      psAddresses,
      psShares,
      msg.sender
    );
    emit ContractCreated(msg.sender, clone);
  }
}