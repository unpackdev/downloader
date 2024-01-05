// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./CloneLibrary.sol";

contract DutchAuctionFactory {
    using CloneLibrary for address;

    event NewDutchAuctionContract(address deployed);
    address public owner;
    address payable public router;
    address public dutchAuctionImplementation;

    constructor(address dutchAuctionImplementation_, address payable router_) {
        owner = msg.sender;
        dutchAuctionImplementation = dutchAuctionImplementation_;
        router = router_;
    }

    function DutchAuctionMint(
        address token_,
        address payable owner_
    ) public returns (address dutchAuction){

        dutchAuction = dutchAuctionImplementation.createClone();

        DutchAuctionInterface(dutchAuction).initialize(
            token_,
            owner_,
            address(this)
        );

        emit NewDutchAuctionContract(address(dutchAuction));
    }

    function setNewOwner(address newOwner) public {
        require(msg.sender == owner, "Only owner");
        owner = newOwner;
    }

    function setNewImplementation(address newImplementation) public {
        require(msg.sender == owner, "Only owner");
        dutchAuctionImplementation = newImplementation;
    }

    function setNewRouter(address payable newRouter) public {
        require(msg.sender == owner, "Only owner");
        router = newRouter;
    }

    function getRouter() external view returns (address payable) {
        return router;
    }
}

interface DutchAuctionInterface {
    function initialize(
        address token,
        address payable owner,
        address factory
    ) external;
}