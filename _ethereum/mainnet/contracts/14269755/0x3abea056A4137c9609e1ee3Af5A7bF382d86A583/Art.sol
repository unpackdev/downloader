// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Context.sol";
import "./ERC165.sol";
import "./IERC165.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./MerkleProof.sol";
import "./ERC20Pausable.sol";

// File: contracts/Art.sol

/**
 * @title Art contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Art is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 2022;
    string public BASE_URI;
    uint256 public constant MAX_PER_TX = 3;

    bool public isSaleActive = true;
    uint256 public price = 0 ether;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function setBaseURI(string memory baseURI) public onlyOwner {
        BASE_URI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(BASE_URI, Strings.toString(tokenId)));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function flipSale() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function mint(uint256 numberOfTokens) public payable whenNotPaused {
        uint256 totalSupply = totalSupply();
        require(isSaleActive, "Sale must be active to mint");
        require(numberOfTokens <= MAX_PER_TX, "Exceeds max per transaction");
        require(
            totalSupply + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        require(totalSupply < MAX_SUPPLY, "All arts are already minted");
        require(
            price.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}
