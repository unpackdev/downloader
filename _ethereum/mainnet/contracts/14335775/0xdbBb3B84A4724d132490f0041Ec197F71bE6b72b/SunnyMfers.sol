//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract SunnyMfers is ERC721A, Ownable {
    bool public revealed;
    string public baseURI;
    string public gaURI;
    string public preURI = "ipfs://bafkreiey6koxutbsnsrplboteddmldrhsy26ooasa5o5r5nlbkpqi6zcam";

    uint256 public SUPPLY = 6969;
    uint256 public WALLETLIMIT = 20;
    uint256 public PRICE = 0.0069 ether;
    uint256 public GIVEAWAY = 20;
    uint256 public FREE = 69;

    event Minted(address sender, uint256 count);

    constructor() ERC721A("SUNNYMFERS", "SUNNYMFERS", WALLETLIMIT) {
        gaURI = preURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        if (revealed) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        } else if (_tokenId >= SUPPLY - GIVEAWAY) {
            return gaURI;
        } else {
            return preURI;
        }
    }

    function mint(uint256 count) public payable {
        require(
            totalSupply() - 1 + count <= SUPPLY - GIVEAWAY,
            "Exceeds total supply"
        );
        require(msg.sender == tx.origin, "No contracts");
        require(count <= WALLETLIMIT, "Exceeds max per txn");
        require(count > 0, "Must mint at least one token");
        require(totalSupply() - 1 + count <= FREE || count * PRICE <= msg.value, "Insufficient funds provided");
        require(
            _numberMinted(msg.sender) + count <= WALLETLIMIT,
            "There is a per-wallet limit!"
        );
        _safeMint(_msgSender(), count);
        emit Minted(msg.sender, count);
    }

    function giveaway(address winner) public onlyOwner {
        require(GIVEAWAY > 0, "No more to giveaway");
        _safeMint(winner, 1);
        GIVEAWAY = GIVEAWAY - 1;
    }

    function setReveal(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setgaURI(string memory _baseURI) public onlyOwner {
        gaURI = _baseURI;
    }

    function withdraw() public onlyOwner {
        require(
            payable(owner()).send(address(this).balance),
            "Withdrawal Failed"
        );
    }
}
