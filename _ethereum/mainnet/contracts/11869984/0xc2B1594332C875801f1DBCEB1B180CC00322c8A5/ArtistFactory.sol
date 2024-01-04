// This contract clones an erc1155 contract for artst to own their art and create/tokenize communities around them.

import "./Clones.sol";

pragma solidity ^0.6.0;

contract ArtistFactory {
    address public logic; //address of erc1155 contract

    using Clones for address;

    constructor(address _logic) public {
        logic = _logic;
    }

    function create(string calldata _name) external payable {
        bytes memory initData =
            abi.encodeWithSignature("initialize(string)", _name);

        address instance = logic.clone();
        // instance.functionCallWithValue(initData, msg.value);
    }
}
