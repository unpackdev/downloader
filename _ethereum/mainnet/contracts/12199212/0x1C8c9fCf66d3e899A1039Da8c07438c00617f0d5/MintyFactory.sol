// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./CloneLibrary.sol";

contract MintyFactory {
    using CloneLibrary for address;

    event NewMintyContract(address deployed);
    address public owner;
    address payable public router;
    address public mintyImplementation;

    constructor(address mintyImplementation_, address payable router_) {
        owner = msg.sender;
        mintyImplementation = mintyImplementation_;
        router = router_;
    }

    function MintyMint(
        string memory name,
        string memory symbol,
        string memory url,
        uint256 tokenCost,
        uint256 tokenCap,
        address payable mintyOwner
    ) public returns (address minty){

        minty = mintyImplementation.createClone();

        MintyInterface(minty).initialize(
            name,
            symbol,
            url,
            tokenCost,
            tokenCap,
            mintyOwner,
            address(this)
        );

        emit NewMintyContract(address(minty));
    }

    function setNewOwner(address newOwner) public {
        require(msg.sender == owner, "Only owner");
        owner = newOwner;
    }

    function setNewRouter(address payable newRouter) public {
        require(msg.sender == owner, "Only owner");
        router = newRouter;
    }

    function setNewImplementation(address newImplementation) public {
        require(msg.sender == owner, "Only owner");
        mintyImplementation = newImplementation;
    }

    function getRouter() external view returns (address payable) {
        return router;
    }
}

interface MintyInterface {
    function initialize(
        string calldata name_,
        string calldata symbol_,
        string calldata url_,
        uint256 tokenCost_,
        uint256 tokenCap_,
        address payable owner_,
        address factoryContract_
    ) external;
}