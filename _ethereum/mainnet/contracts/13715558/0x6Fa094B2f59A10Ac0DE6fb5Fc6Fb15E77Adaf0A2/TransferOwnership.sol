pragma solidity ^0.6.7;

abstract contract CurvePoolLike {
    function apply_transfer_ownership() external virtual;
}

contract TransferOwnership {
    function commit_transfer_ownership(address pool) public {
        CurvePoolLike(pool).apply_transfer_ownership();
    }
}