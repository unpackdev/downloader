// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Strings.sol";
import "MerkleProof.sol";

contract Infectables is ERC721A {
    uint256 public mint_status;

    uint256 public MAX_SUPPLY;
    uint256 public TEAM_SUPPLY = 200;
    uint256 public PUBLIC_SUPPLY = 1000;
    uint256 public FREE_SUPPLY = 3800;

    address public owner;
    string private baseURI;

    uint256 public public_price;

    mapping(address => uint256) public NbMinted;
    bytes32 public FreeMintRootMap;

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        owner = msg.sender;
        setMintStatus(0);
        setMintMaxSupply(5000);
        setMintPublicPrice(30000000000000000);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setMintStatus(uint256 _status) public onlyOwner {
        mint_status = _status;
    }

    function setMintMaxSupply(uint256 _max_supply) public onlyOwner {
        MAX_SUPPLY = _max_supply;
    }

    function setMintFreeSupply(uint256 _free_supply) public onlyOwner {
        FREE_SUPPLY = _free_supply;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setMintPublicPrice(uint256 _price) public onlyOwner {
        public_price = _price;
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

    function setFreeMintRoot(uint256 _root) public onlyOwner {
        FreeMintRootMap = bytes32(_root);
    }

    function isList(bytes32 merkleRoot, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function canMint(bool isWL) public view returns (bool) {
        if (mint_status == 0) return false;
        if (mint_status == 1 && isWL) return true;
        if (mint_status == 2) return true;
        return false;
    }

    function getPrice(
        bool isWL,
        uint256 amount,
        address addr
    ) public view returns (uint256) {
        if (isWL && NbMinted[addr] == 0 && totalSupply() <= FREE_SUPPLY) {
            return ((amount - 1) * public_price);
        }
        return amount * public_price;
    }

    function mint(bytes32[] calldata _merkleProof, uint256 amount)
        external
        payable
    {
        require(
            amount <= 2 && NbMinted[msg.sender] < 2,
            string(
                abi.encodePacked("The maximum amount of NFT per Wallet is 2")
            )
        );
        bool isWL = isList(FreeMintRootMap, _merkleProof);
        require(canMint(isWL), "You are not allowed to mint");
        require(
            totalSupply() + amount <= MAX_SUPPLY - TEAM_SUPPLY,
            "This will exceed the total supply."
        );
        require(
            msg.value >= getPrice(isWL, amount, msg.sender),
            "Not enought ETH sent"
        );
        _safeMint(msg.sender, amount);
        NbMinted[msg.sender] = NbMinted[msg.sender] + amount;
    }

    function giveaway(address[] calldata _to, uint256 amount)
        external
        onlyOwner
    {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "This will exceed the total supply."
        );
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], amount);
        }
    }

    function withdraw(address[] calldata _to, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            payable(_to[i]).transfer(amount);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
}
