pragma solidity 0.8.16;

import "./Initializable.sol";
import "./ICloneable.sol";
import "./ERC721.sol";

contract Cloneable is ICloneable, Initializable {
    constructor() {
        _disableInitializers();
    }

    /***********************************************|
    |               External                        |
    |______________________________________________*/
    function isInitialized() external view returns (bool) {
        return _getInitializedVersion() > 0;
    }
}
