// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./BaseContract.sol";

contract RebelKidsFamiliars is BaseContract {

    uint constant EDITION_SUPPLY = 666;
    mapping(address => mapping(uint => bool)) isEditionMinted;

    bool public isOnlyForKids;
    IERC721 public rebelKids;

    constructor() BaseContract(
        "Rebel Kids Familiars",
        "RBLFML",
        666,
        1,
        0.01 ether
    ) {
    }

    // region setters
    function setRebelKids(IERC721 rebelKidsAddress) external onlyOwner {
        rebelKids = rebelKidsAddress;
    }

    function setOnlyForKids(bool _isOnlyForKids) external onlyOwner {
        isOnlyForKids = _isOnlyForKids;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrice(uint _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }
    // endregion

    function _beforeMint() internal virtual override {
        uint editionNum = totalSupply() / EDITION_SUPPLY;
        require(!isEditionMinted[msg.sender][editionNum], "Can't mint more than 1 Familiar in that edition");
        isEditionMinted[msg.sender][editionNum] = true;
        if (isOnlyForKids) {
            require(address(rebelKids) != address(0), "RebelKids contract address is not set");
            require(rebelKids.balanceOf(msg.sender) > 0, "You must own at least one Rebel Kid to mint Familiar");
        }
    }

}
