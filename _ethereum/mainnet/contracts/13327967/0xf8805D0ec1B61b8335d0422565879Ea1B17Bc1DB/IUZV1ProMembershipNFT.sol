// contracts/interfaces/pro/IUZV1ProMembershipNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Upgradeable.sol";

interface IUZV1ProMembershipNFT is IERC721Upgradeable {
    function mint(address receiver) external;

    function setMinterAddress(address newMinterAddress) external;

    function switchTransferable() external;
}
