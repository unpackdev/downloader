// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ERC721.sol";

contract RareApes is ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant NFT_PRICE = 8e16;

    uint256 public constant MAX_NFT_SUPPLY = 5000;

    uint256 public immutable SALE_START_TIMESTAMP;

    address payable private immutable _owner;

    address payable private immutable _dev;

    address payable private immutable _marketing;

    address payable private immutable _stakeholder;

    constructor (uint256 saleStartTimestamp) public ERC721 ("Rare Apes", "APES") {
        SALE_START_TIMESTAMP = saleStartTimestamp;
        _owner = msg.sender;
        _stakeholder = 0x1d60B7B37047e082DEd520E1Ff23236F154C0967;
        _marketing = 0x67F1c840063ac94C726da2468342357d031557c1;
        _dev = 0x208EbAb8b7e698E2D8C1b81354b9f088952760Ef;
        _setBaseURI("ipfs://QmcZjLkFMjxSeaP7DN6iwaaYnHKdKKVr22L7SJjFW8D2zN/");
        
        for (uint i = 0; i < 5; i++) {
            _safeMint(msg.sender, i);
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI(), tokenId.toString(), ".json"));
    }

    /**
    * @dev Mints NFT
    */
    function mintNFT(uint256 numberOfNfts) public payable {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 20, "You may not buy more than 20 NFTs at once");
        require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(NFT_PRICE.mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    /**
     * @dev Withdraw ether from this contract
    */
    function withdraw() public {
        require(_msgSender() == _owner, "UNAUTHORIZED");
        uint balance = address(this).balance;
        uint twentyPercent = balance.div(5);
        uint sixtyPercent = balance - twentyPercent.mul(2);

        _dev.transfer(twentyPercent);
        _stakeholder.transfer(twentyPercent);
        _marketing.transfer(sixtyPercent);
    }
}