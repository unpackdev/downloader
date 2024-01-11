// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IOneWarDescriptor.sol";

interface IOneWarModifier {
    event TreasuryUpdated(address payable _treasury);

    event DescriptorUpdated(IOneWarDescriptor _descriptor);

    event DescriptorLocked();

    function treasury() external view returns (address payable);

    function setTreasury(address payable _treasury) external;

    function descriptor() external view returns (IOneWarDescriptor);

    function setDescriptor(IOneWarDescriptor _descriptor) external;

    function lockDescriptor() external;
}
