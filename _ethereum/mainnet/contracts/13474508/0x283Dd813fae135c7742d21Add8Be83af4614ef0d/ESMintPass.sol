// contracts/ESMintPass.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

/**
 * @title ESMintPass
 * @dev Ethereal Pass
 *
 * Authors: s.imo
 * Created: 15.10.2021
 */
contract ESMintPass is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings  for uint256;

    // the maximum number of mint-pass
    uint256 public constant MAX_SUPPLY = 2222;
    // the mint price in ether
    uint256 public constant MINT_PRICE = 0.22 ether;
    // the maximum number of mint-pass that can be minted
    uint256 public constant MAX_NUM_MINT = 20;
    // flag to activate the minting of mint-pass
    bool public salesActivated;
    // flag to activate different metadata per tokenID
    bool private _differentMetadata;
    // metadata root uri
    string private _rootURI;

    /**
     * @dev Constructor
     */
    constructor()
    ERC721("Ethereal Pass", "ETHSDIO")
    {}

    /**
     * @dev Mint 'numOfPass' new mint-pass
     */
    function mint(uint256 numOfPass) public payable {
        require(salesActivated, "Mint not enabled");
        require(totalSupply().add(numOfPass) <= MAX_SUPPLY, "Sale has already ended");
        require(numOfPass <= MAX_NUM_MINT, "Max MAX_NUM_MINT can be minted");
        require(MINT_PRICE.mul(numOfPass) == msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numOfPass; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_SUPPLY) {
                _safeMint(_msgSender(), mintIndex);
            }
        }
    }

    /**
     * @dev Assign 'numOfPass' mint-pass to the 'destination' address
    */
    function assign(uint256 numOfPass, address destination) public onlyOwner() {
        require(totalSupply().add(numOfPass) <= MAX_SUPPLY, "Sale has already ended");

        for (uint256 i = 0; i < numOfPass; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_SUPPLY) {
                _safeMint(destination, mintIndex);
            }
        }
    }

    /**
     * @dev Toggle the mint activation flag
     */
    function toggleSalesState() public onlyOwner() {
        salesActivated = !salesActivated;
    }

    /**
     * @dev Retrieve the token URI
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(bytes(_rootURI).length > 0, "Base URI not yet set");
        require(_exists(tokenId), "Token ID not valid");

        return _differentMetadata
                ? string(abi.encodePacked(_baseURI(), tokenId.toString()))
                : _baseURI();
    }

    /**
     * @dev Set the base uri.
     *      When 'differentMetadata' is set to true each token as a different id
     */
    function setBaseURI(string memory uri, bool differentMetadata) external onlyOwner() {
        _rootURI = uri;
        _differentMetadata = differentMetadata;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _rootURI;
    }

    /**
     * @dev Withdraw contract balance to a specific destination
     */
    function withdraw(address _destination) onlyOwner() public returns (bool) {
        uint balance = address(this).balance;
        (bool success,) = _destination.call{value : balance}("");
        // no need to call throw here or handle double entry attack
        // since only the owner is withdrawing all the balance
        return success;
    }

}
