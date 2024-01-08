pragma solidity 0.6.12;

interface INRDAAuction {
  function setArtistsControlAddressAndEnabledEdition(uint256 _editionNumber, address _address) external;
}
