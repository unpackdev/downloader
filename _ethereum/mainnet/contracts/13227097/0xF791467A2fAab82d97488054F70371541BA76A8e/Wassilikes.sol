//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Wassilikes is Ownable, ERC721Burnable {
    // Setup imports
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;

    uint256 public constant PUBLIC_MINT_PRICE = 40000000000000000; // 0.04 ETH
    uint256 public constant MAX_SUPPLY = 333;
    bool public paused = true;
    address payable[2] royaltyRecipients;

    string public baseURI;

    constructor(
        string memory initialBaseURI,
        address payable[2] memory _royaltyRecipients
    ) public ERC721("Wassilikes", "WASSI") {
        require(_royaltyRecipients[0] != address(0), "Invalid address");
        require(_royaltyRecipients[1] != address(0), "Invalid address");

        baseURI = initialBaseURI;
        royaltyRecipients = _royaltyRecipients;
    }

    function claim(address recipient)
        public
        payable
        returns (uint256)
    {
        require(!paused, "Contract must be unpaused to mint");
        uint256 nextId = _tokenIdCounter.current();
        require(nextId < MAX_SUPPLY, "Token limit reached. Sorry.");
        require(msg.value >= PUBLIC_MINT_PRICE, "The price is .04 ETH or more.");

        _safeMint(recipient, nextId);
        _tokenIdCounter.increment();

        return nextId;
    }

    function ownerClaim(address recipient) public onlyOwner {
        require(_tokenIdCounter.current() < 2, "Owner can only mint the first two.");
        _safeMint(recipient, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function getSupply() public view returns(uint256) {
        return _tokenIdCounter.current();
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function withdrawETH() public onlyOwner  {
        uint256 royalty = address(this).balance / 3;

        Address.sendValue(payable(royaltyRecipients[0]), royalty * 2);
        Address.sendValue(payable(royaltyRecipients[1]), royalty);
    }

}
