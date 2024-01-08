pragma solidity 0.6.12;

interface ISelfServiceAccessControls {

  function isEnabledForAccount(address account) external view returns (bool);

}
