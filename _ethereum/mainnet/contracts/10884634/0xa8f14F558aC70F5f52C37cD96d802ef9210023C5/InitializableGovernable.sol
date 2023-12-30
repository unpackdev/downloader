pragma solidity 0.5.11;

/**
 * @title OUSD InitializableGovernable Contract
 * @author Origin Protocol Inc
 */
import "./Initializable.sol";

import "./Governable.sol";

contract InitializableGovernable is Governable, Initializable {
    function _initialize(address _governor) internal {
        _changeGovernor(_governor);
    }
}
