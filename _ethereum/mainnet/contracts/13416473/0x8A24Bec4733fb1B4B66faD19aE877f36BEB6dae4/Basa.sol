// contracts/Basa.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";


contract BASA is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    // the maximum number of tokens
    uint256 public constant MAX_SUPPLY = 1000;
    // the maximum number of tokens to mint
    uint256 public constant MAX_MINT = 20;
    // the mint price in ether
    uint256 public constant MINT_PRICE = 0.04 ether;
    // flag to activate the minting of tickets
    bool private salesActivated;
    // metadata root uri
    string private _rootURI;

    /**
     * @dev Constructor
     */
    constructor()
        ERC721("BoredApeSpaceAgency", "BASA")
    {}


    function mintNFT(address recipient, uint numberOfMints) public payable returns (uint256){
        require(salesActivated,             "Mint not enabled");
        require(totalSupply().add(numberOfMints) <= MAX_SUPPLY, "Sale has already ended");
        require(MINT_PRICE == msg.value,    "Ether value sent is not correct");
        require(numberOfMints <= MAX_MINT,  "You can only mint a maximum of 20 BASA Tokens at once.");

        for(uint256 i = 0; i < numberOfMints; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_SUPPLY) {
                _safeMint(recipient, mintIndex);
            }
        }

        return numberOfMints;
    }


    function assignNFT(address recipient, uint numberOfMints) public onlyOwner() returns (uint256){
        require(totalSupply().add(numberOfMints) <= MAX_SUPPLY, "Sale has already ended");

        for(uint256 i = 0; i < numberOfMints; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_SUPPLY) {
                _safeMint(recipient, mintIndex);
            }
        }

        return numberOfMints;
    }

    /**
     * @dev Toggle the mint activation flag
     */
    function toggleSalesState() public onlyOwner() {
        salesActivated = !salesActivated;
    }

    function setBaseURI(string memory uri) external onlyOwner() {
        _rootURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(bytes(_rootURI).length > 0, "Base URI not yet set");
        require(_exists(tokenId),           "Token ID not valid");

        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _rootURI;
    }

    /**
     * @dev Withdraw contract balance to a specific destination
     */
    function withdraw(address _destination) onlyOwner() public returns (bool) {
        uint balance = address(this).balance;
        (bool success, ) = _destination.call{value:balance}("");
        // no need to call throw here or handle double entry attack
        // since only the owner is withdrawing all the balance
        return success;
    }

}
