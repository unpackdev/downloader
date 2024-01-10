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
import "./ERC20Pausable.sol";

// File: contracts/OX3Lander.sol

/**
 * @title OX3Lander contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract OX3Lander is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant FREE_MAX_SUPPLY = 1000;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_PER_ADDRESS = 20;

    string public BASE_URI;
    bool public isSaleActive = false;
    uint256 public price = 0.01 ether;
    mapping(address => uint256) public purchased;

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

    function publicSale(address _address, uint256 numberOfTokens)
        public
        payable
        onlyOwner
    {
        uint256 totalSupply = totalSupply();
        require(isSaleActive, "Sale must be active to mint");
        require(tx.origin == msg.sender, "Contract address not allowed");
        require(
            totalSupply + numberOfTokens <= MAX_SUPPLY,
            "Exceed max supply"
        );
        if (totalSupply + numberOfTokens < FREE_MAX_SUPPLY) {
            require(msg.value == 0, "Ether value sent is not correct");
        } else if (totalSupply > FREE_MAX_SUPPLY) {
            require(
                price.mul(numberOfTokens) == msg.value,
                "Ether value sent is not correct"
            );
        } else {
            require(
                price.mul(totalSupply + numberOfTokens - FREE_MAX_SUPPLY) ==
                    msg.value,
                "Ether value sent is not correct"
            );
        }

        purchased[_address] += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(_address, totalSupply + i);
        }
    }

    function mint(uint256 numberOfTokens) public payable whenNotPaused {
        uint256 totalSupply = totalSupply();
        require(isSaleActive, "Sale must be active to mint");
        require(tx.origin == msg.sender, "Contract address not allowed");
        require(numberOfTokens <= MAX_PER_TX, "Exceeds max per transaction");
        require(
            purchased[_msgSender()] + numberOfTokens <= MAX_PER_ADDRESS,
            "Exceeds per address supply"
        );
        require(
            totalSupply + numberOfTokens <= MAX_SUPPLY,
            "Exceed max supply"
        );
        if (totalSupply + numberOfTokens < FREE_MAX_SUPPLY) {
            require(msg.value == 0, "Ether value sent is not correct");
        } else if (totalSupply > FREE_MAX_SUPPLY) {
            require(
                price.mul(numberOfTokens) == msg.value,
                "Ether value sent is not correct"
            );
        } else {
            require(
                price.mul(totalSupply + numberOfTokens - FREE_MAX_SUPPLY) ==
                    msg.value,
                "Ether value sent is not correct"
            );
        }

        purchased[_msgSender()] += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), totalSupply + i);
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
