pragma solidity >=0.5.16;

// import "./Initializable.sol";

abstract contract ChainIdHolding {
    uint256 public chainId;

    function __ChainIdHolding_init() internal {
        uint256 _cid;
        assembly {
            _cid := chainid()
        }
        chainId = _cid;
    }
    // constructor() internal {

    // }
}
