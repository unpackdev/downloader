// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

contract DwarfssTownWtf is ERC721A, Ownable {

    using SafeMath for uint256;
    using SafeMath for uint16;

    string baseURI;
    uint256 public MAX_SUPPLY;
    uint16 totalMint = 0;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _maxSupply
    ) ERC721A(_name, _symbol){
        MAX_SUPPLY = _maxSupply;
        baseURI = _baseURI;
    }

    string public contractURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint numberOfTokens) public payable {
        require(totalMint.add(numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(numberOfTokens <= 20, "20 per wallet only");

        if (totalMint < MAX_SUPPLY) {
            _mint(msg.sender, numberOfTokens);
            totalMint.add(numberOfTokens);
        }
    }


}
