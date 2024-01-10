// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Strings.sol";

contract Azukevin is ERC721A {
    bool public mint_status;
    uint256 public MAX_SUPPLY;
    address public owner;
    string private baseURI;
    uint256 public price;
    mapping(address => uint256) public qteMinted;

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        owner = msg.sender;
        setMintStatus(false);
        setMintMaxSupply(555);
        setBaseURI("ipfs://QmcQLnnaNuFzJskHc47YQYe1AQnzLFf5THPqJZLjSTQ7n6/");
        setMintPrice(15000000000000000);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setMintStatus(bool _status) public onlyOwner {
        mint_status = _status;
    }

    function setMintMaxSupply(uint256 _max_supply) public onlyOwner {
        MAX_SUPPLY = _max_supply;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function mint(uint256 amount) external payable {
        require(mint_status, "Mint has not started yet");
        require(
            qteMinted[msg.sender] + amount <= 5,
            "The maximum amount of NFT per wallet is 5"
        );
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "This will exceed the total supply."
        );
        if (totalSupply() + amount > 255) {
            require(msg.value >= price * amount, "Not enought ETH sent");
        }
        _safeMint(msg.sender, amount);
        qteMinted[msg.sender] = qteMinted[msg.sender] + amount;
    }

    function giveaway(address[] calldata _to, uint256 amount)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], amount);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
}
