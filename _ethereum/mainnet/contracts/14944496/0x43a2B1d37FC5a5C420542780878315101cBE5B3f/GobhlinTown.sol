//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract GobhlinTown is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public _gobblinbody;
    bool public halt = false;
    uint256 public gobhlins = 9999;
    uint256 public littlegobblins = 10;
    mapping(address => uint256) public howmanygobblins;

    constructor(string memory _metadataURI) ERC721A("gobhlintown", "GOBHLIN") {
        _gobblinbody = _metadataURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _gobblinbody;
    }

    //mint gobhlins
    function hatchgobblin(uint256 _mintNum) external nonReentrant {
        uint256 totalgobnlinsss = totalSupply();
        require(halt, "Minting Paused");
        require(totalgobnlinsss + _mintNum <= gobhlins, "Supply limit reached");
        require(
            _mintNum <= littlegobblins,
            "Mint limit exceeding for the user"
        );
        require(msg.sender == tx.origin, "Caller not a person");
        require(
            howmanygobblins[msg.sender] + _mintNum <= littlegobblins,
            "User can't any mint more tokens"
        );
        _safeMint(msg.sender, _mintNum);
        howmanygobblins[msg.sender] += _mintNum;
    }

    //gift gobhlinss
    function handoutgobblins(address lords, uint256 _gobhlins)
        public
        onlyOwner
    {
        uint256 totalgobhlinsss = totalSupply();
        require(totalgobhlinsss + _gobhlins <= gobhlins);
        _safeMint(lords, _gobhlins);
    }

    // pause function
    function haltgobblins(bool _state) external onlyOwner {
        halt = _state;
    }

    // how many gobhlins can a person mint
    function rolloutgobblins(uint256 _num) external onlyOwner {
        littlegobblins = _num;
    }

    // set tokenURI
    function setgobblinbody(string memory parts) external onlyOwner {
        _gobblinbody = parts;
    }

    // withdraw function
    function beingcapitalist() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    // reserve gobhlins
    function reserveGobhlins(uint256 _num) external onlyOwner {
        uint256 totalgobhlinsss = totalSupply();
        require(totalgobhlinsss + _num <= gobhlins);
        _safeMint(msg.sender, _num);
    }

    // get token uri
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Non Existent Token");
        string memory currentBaseURI = _baseURI();

        return (
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : ""
        );
    }
}
