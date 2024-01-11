// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./DigitalCertLib.sol";
import "./MarketLib.sol";
interface IMarket {
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function burnBatchFor ( uint256[] calldata certIds, uint256[] calldata burnAmounts ) external;
  function burnFor ( uint256 certId, uint256 burnAmount ) external;
  function getLastRedeemId (  ) external view returns ( uint256 );
  function getRedeemByRedeemId ( uint256 redeemId ) external view returns ( MarketLib.Redeemed memory );
  function getRedeemIdsByAddress ( address customer ) external view returns ( uint256[] memory );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function isDigitalCertPaused ( uint256 certId ) external view returns ( bool );
  function onERC1155BatchReceived ( address operator, address from, uint256[] memory ids, uint256[] memory values, bytes memory data ) external returns ( bytes4 );
  function onERC1155Received ( address operator, address from, uint256 id, uint256 value, bytes memory data ) external returns ( bytes4 );
  function onRedeem ( uint256 certId, uint256 amount ) external;
  function ownerAddress (  ) external view returns ( address );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function setPauseForCertId ( uint256 certId, bool isPaused ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
}
