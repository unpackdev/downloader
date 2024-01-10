pragma solidity 0.5.16;

import "./NotifyHelperStateful.sol";

contract ViewerNotifyHelperStateful {

  /// configuration check method
  function getConfig(address helper, uint256 totalAmount)
  external view returns(address[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
    (
      address[] memory pools,
      uint256[] memory percentages,
      uint256[] memory amounts
    ) = NotifyHelperStateful(helper).getConfig(totalAmount);

    uint256[] memory types = new uint256[](pools.length);
    for (uint256 i = 0; i < pools.length; i++) {
      (, NotifyHelperStateful.NotificationType notificationType, , ) = NotifyHelperStateful(helper).notifications(i);
      types[i] = uint256(notificationType);
    }

    return (pools, percentages, amounts, types);
  }
}
