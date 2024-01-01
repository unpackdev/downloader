pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract HodlessRevenueShare is Initializable, OwnableUpgradeable {
    receive() external payable {} // solhint-disable-line no-empty-blocks

    function initialize(address initialOwner) initializer public {
        __Ownable_init(initialOwner);
    }
}
