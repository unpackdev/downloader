pragma solidity 0.6.12;

import "./Ownable.sol";
import "./Initializable.sol";

contract ControllableOracle is OwnableUpgradeSafe {
    bool private _validity;
    uint256 private _data;

    function initialize()
        public
        initializer
    {
        __Ownable_init();
    }

    function storeData(uint256 data, bool validity)
        public
        onlyOwner
    {
        _data = data;
        _validity = validity;
    }

    function getData()
        public
        view
        returns (uint256, bool)
    {
        return (_data, _validity);
    }
}
// contract ControllableOracle  {
//     bool private _validity;
//     uint256 private _data;

//     function storeData(uint256 data, bool validity)
//         public
//     {
//         _data = data;
//         _validity = validity;
//     }

//     function getData()
//         public
//         view
//         returns (uint256, bool)
//     {
//         return (_data, _validity);
//     }
// }