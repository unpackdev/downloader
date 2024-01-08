// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./ERC721.sol";

/**
 * @title Autograph
 * @author neuroswish
 *
 * Luxury rap, the Hermes of verses
 * Sophisticated ignorance, write my curses in cursive
 * I get it custom, you a customer
 * You ain't 'customed to going through Customs, you ain't been nowhere, huh?
 */

contract Autograph is ERC721("Autograph", "AUTOGRAPH") {
    // ======== Autograph params ========
    mapping(address => bool) public hasMinted; // sender has minted an autograph card
    mapping(address => mapping(address => bool)) public hasSignedAddress; // sender has signed recipient's card already
    mapping(address => address[]) public signers; // list of signers
    uint256 public lastMintedId; // token Id

    // ======== Events ========
    event Sign(address indexed recipient, address indexed signer);

    // ======== Functions ========
    function mint() public {
        require(hasMinted[msg.sender] == false, "you already have a card");
        uint256 newTokenId = lastMintedId + 1;
        lastMintedId = newTokenId;
        _mint(msg.sender, newTokenId);
        hasMinted[msg.sender] = true;
    }

    function sign(address _recipient) public {
        require(
            hasSignedAddress[msg.sender][_recipient] == false,
            "already signed"
        );
        require(msg.sender != _recipient, "can't sign your own card");
        signers[_recipient].push(msg.sender);
        emit Sign(_recipient, msg.sender);
        hasSignedAddress[msg.sender][_recipient] = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId <= lastMintedId, "token doesn't exist");
        return "ipfs://QmXGGgXjM9111KkkErCWV1or4j1nY3PDUnKqbVxEG7fRFj";
    }

    // ======== Utility ========
    function getSigners(address _address)
        public
        view
        returns (address[] memory)
    {
        return signers[_address];
    }
}
