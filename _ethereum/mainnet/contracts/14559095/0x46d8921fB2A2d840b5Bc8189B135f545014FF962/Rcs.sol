// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Strings.sol";
import "MerkleProof.sol";

contract Rcs is ERC721A {
    bool public mint_status;
    bool public free_status;
    uint256 public MAX_SUPPLY;
    uint256 public MAX_MINT_PER_TX;
    address public owner;
    string private baseURI;

    uint256 public wl_price;
    uint256 public public_price;

    mapping(address => uint256) public qteMinted;

    mapping(address => bool) public FreeMintClaimed;
    mapping(uint256 => bytes32) public FreeMintRootMap;

    bytes32 public wlRoot;

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        owner = msg.sender;
        setMintStatus(true);
        setMintMaxSupply(4888);
        setMaxMintPerTx(3);
        setFreeStatus(false);
        setBaseURI("ipfs://QmXmuBWHcGSLnfHvDMgLvfaVJL1cPoWkbrm8asSZHHb6EC/");
        setMintPublicPrice(80000000000000000);
        setMintWlPrice(50000000000000000);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setMintStatus(bool _status) public onlyOwner {
        mint_status = _status;
    }

    function setFreeStatus(bool _status) public onlyOwner {
        free_status = _status;
    }

    function setMaxMintPerTx(uint256 _max) public onlyOwner {
        MAX_MINT_PER_TX = _max;
    }

    function setMintMaxSupply(uint256 _max_supply) public onlyOwner {
        MAX_SUPPLY = _max_supply;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setMintPublicPrice(uint256 _price) public onlyOwner {
        public_price = _price;
    }

    function setMintWlPrice(uint256 _price) public onlyOwner {
        wl_price = _price;
    }

    function setWlRoot(uint256 _root) public onlyOwner {
        wlRoot = bytes32(_root);
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

    function setFreeMintRoot(uint256 _root, uint256 _amount) public onlyOwner {
        FreeMintRootMap[_amount] = bytes32(_root);
    }

    function claim(bytes32[] calldata _merkleProof, uint256 amount) public {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "This will exceed the total supply."
        );
        require(!FreeMintClaimed[msg.sender], "Address has already claimed.");
        bytes32 merkleRoot = FreeMintRootMap[amount];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "You are not allowed to claim."
        );
        _safeMint(msg.sender, amount);
        FreeMintClaimed[msg.sender] = true;
    }

    function isWl(address addr, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 merkleRoot = wlRoot;
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function getPrice(
        address addr,
        bytes32[] calldata _merkleProof,
        uint256 amount
    ) public view returns (uint256) {
        if (free_status) return 0;
        if (isWl(addr, _merkleProof)) {
            uint256 wl = (amount - qteMinted[addr]);
            if (wl >= 0)
                return (wl * wl_price) + ((amount - wl) * public_price);
        }
        return amount * public_price;
    }

    function mint(bytes32[] calldata _merkleProof, uint256 amount)
        external
        payable
    {
        require(mint_status, "Mint has not started yet");
        require(
            amount <= MAX_MINT_PER_TX,
            string(
                abi.encodePacked(
                    "The maximum amount of NFT per tx is ",
                    MAX_MINT_PER_TX
                )
            )
        );
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "This will exceed the total supply."
        );
        require(
            msg.value >= getPrice(msg.sender, _merkleProof, amount),
            "Not enought ETH sent"
        );
        _safeMint(msg.sender, amount);
        if (isWl(msg.sender, _merkleProof))
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
