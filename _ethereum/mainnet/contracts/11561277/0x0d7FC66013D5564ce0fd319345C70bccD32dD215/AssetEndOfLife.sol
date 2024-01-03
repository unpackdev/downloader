pragma solidity 0.5.8;


contract AssetEndOfLife {
    function () external payable {
        revert('End Of Life Reached');
    }
}