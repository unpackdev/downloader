pragma solidity ^0.8.0;

import "./IERC721A.sol";

interface CollectionA is IERC721A {
    function presaleBuy(
        bytes32[] calldata _proofs,
        address _buyer,
        uint256 _quantity
    ) external payable;
}