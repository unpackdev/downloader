//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

// IMPORTANT: _burn() must never be called
contract NRDNM2 is ERC721A, Ownable {
    using Strings for uint256;

    uint immutable public startSaleTimestamp;
    uint public constant TOKEN_LIMIT = 250;
    uint public mintPrice = 0.05 ether;
    string public baseURI;
    bool public revealed = false;
    bool public finalized = false;

    constructor(string memory _baseURI)
        ERC721A("NRDNM 2.0", "NRDNM2")
    {
        baseURI = _baseURI;
        startSaleTimestamp = block.timestamp;
    }

    /** Once finality reached, baseURI & reveal flag are locked. **/
    function setParams(string memory newBaseURI, bool _reveal) external onlyOwner {
        require(finalized == false, "Finality reached.");

        baseURI = newBaseURI;
        revealed = _reveal;
    }

    function setPrice(uint _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    /** Lock permanently, once **/
    function lockFinal(bool _final) external onlyOwner {
        require(finalized == false, "Finality reached.");

        finalized = _final;
    }

    function mintFromSale(uint amount) public payable {
        require(block.timestamp > startSaleTimestamp, "Public sale hasn't started yet");
        require(amount <= 5, "Up to 5 tokens can be minted at once");
        uint cost;
        unchecked {
            cost = amount * mintPrice;
        }
        require(msg.value == cost, "wrong payment");
        _mint(msg.sender, amount, '', false);
        require(totalSupply() <= TOKEN_LIMIT, "limit reached");
    }

    /**
    * Contract balance payout to team via owner withdrawal
    */
    function withdraw(address payable assistant) external onlyOwner {
        uint fifteenPercent = (address(this).balance/20) * 3;

        (bool success, ) = assistant.call{value: fifteenPercent}(""); //15% cut to assistant
        require(success, "Failed to send Ether");

        payable(msg.sender).transfer(address(this).balance);          //Remainder to owner
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    
        //Before reveal, return baseURI for placeholder
        if (revealed == false) return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI)) : '';
        else return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }
}