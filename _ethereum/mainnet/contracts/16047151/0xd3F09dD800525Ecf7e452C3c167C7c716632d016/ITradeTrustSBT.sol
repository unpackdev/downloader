// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC721ReceiverUpgradeable.sol";
import "./ISBTUpgradeable.sol";
import "./ITitleEscrowFactory.sol";

interface ITradeTrustSBT is IERC721ReceiverUpgradeable, ISBTUpgradeable {
  function genesis() external view returns (uint256);

  function titleEscrowFactory() external view returns (ITitleEscrowFactory);
}
