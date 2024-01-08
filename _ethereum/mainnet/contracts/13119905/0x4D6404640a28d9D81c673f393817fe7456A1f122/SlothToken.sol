// // SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

pragma solidity ^0.7.0;
pragma abicoder v2;

contract SlothToken is ERC721, Ownable {
    using SafeMath for uint256;

    string public TOKEN_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN TOKENS ARE ALL SOLD OUT

    uint256 public constant tokenPrice = 40000000000000000; // 0.04 ETH

    // uint256 public constant maxTokenPurchase = 20;

    uint256 public constant MAX_TOKENS = 9999;

    bool public saleIsActive = false;
    bool public allowListIsActive = false;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;

    uint256 public allowListMaxMint = 2;

    uint256 public tokenReserve = 50;

    event TokenMinted(uint256 supply);

    constructor() ERC721("Sleep Sloths", "SSTH") {}

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function reserveTokens(address _to, uint256 _reserveAmount)
        external
        onlyOwner
    {
        require(
            _reserveAmount > 0 && _reserveAmount <= tokenReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(_to, mintIndex);
        }
        tokenReserve = tokenReserve.sub(_reserveAmount);
    }

    function setProvenanceHash(string memory provenanceHash)
        external
        onlyOwner
    {
        TOKEN_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipAllowListState() external onlyOwner {
        allowListIsActive = !allowListIsActive;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function mintToken(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Token");
        require(
            numberOfTokens > 0, // && numberOfTokens <= maxTokenPurchase,
            "Can only mint one or more tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= tokenPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
                emit TokenMinted(mintIndex);
            }
        }
    }

    function allowListMintToken(uint256 numberOfTokens) external payable {
        require(allowListIsActive, "Allow List is not active");
        require(_allowList[msg.sender], "You are not on the Allow List");
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of token"
        );
        require(
            numberOfTokens > 0 && numberOfTokens <= allowListMaxMint,
            "Cannot purchase this many tokens"
        );
        require(
            _allowListClaimed[msg.sender].add(numberOfTokens) <=
                allowListMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            msg.value >= tokenPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() < MAX_TOKENS) {
                _allowListClaimed[msg.sender] += 1;
                _safeMint(msg.sender, mintIndex);
                emit TokenMinted(mintIndex);
            }
        }
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = true;
        }
    }

    function removeFromAllowList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = false;
        }
    }

    function setAllowListMaxMint(uint256 maxMint) external onlyOwner {
        allowListMaxMint = maxMint;
    }

    function onAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }
}
