// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./PullPayment.sol";
import "./Ownable.sol";

// contract PumpedShibaSportsClub is ERC721, PullPayment, Ownable {
contract PumpedShibaSportsClub is ERC721, Ownable {
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant TOTAL_SUPPLY = 4_200;
    // uint256 public constant MINT_PRICE = 0.01 ether;

    Counters.Counter private currentTokenId;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor() ERC721("PumpedShibaSportsClub", "PSSC") {
        baseTokenURI = "https://api.pumpedshiba.com/NFT/token/";
    }

    function mintTo(address recipient) public returns (uint256) {
        // function mintTo(address recipient) public payable returns (uint256) {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");
        // require(
        //     msg.value == MINT_PRICE,
        //     "Transaction value did not equal the mint price"
        // );

        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.pumpedshiba.com/NFT/";
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        // function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // /// @dev Overridden in order to make it an onlyOwner function
    // function withdrawPayments(address payable payee)
    //     public
    //     virtual
    //     override
    //     onlyOwner
    // {
    //     super.withdrawPayments(payee);
    // }
}
