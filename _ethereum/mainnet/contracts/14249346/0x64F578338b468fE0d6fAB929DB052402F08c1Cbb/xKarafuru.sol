// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Counters.sol";
import "Strings.sol";
import "MerkleProof.sol";

contract xKarafuru is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    uint256 public totalSupply;
    bool public reveal = false;
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant GIVEAWAY = 300;
    address public owner = msg.sender;
    string private baseURI_;
    bytes32 public rootMap;
    uint256 public public_price = 20000000000000000;
    uint256 public wl_price = 15000000000000000;
    uint32 public wl_mint_ts;
    uint32 public public_mint_ts;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        setMintTs(1645448400, 1645455600);
        setBaseURI("ipfs://QmUcDLKYfyWpMRdrWootjz8zgET6jMqAKWCFToTcgGvKre/");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI_ = _uri;
    }

    function setMintTs(uint32 _wl_mint_ts, uint32 _public_mint_ts)
        public
        onlyOwner
    {
        wl_mint_ts = _wl_mint_ts;
        public_mint_ts = _public_mint_ts;
    }

    function setRoot(uint256 _root) public onlyOwner {
        rootMap = bytes32(_root);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI_, Strings.toString(tokenId)));
    }

    function mint(bytes32[] calldata _merkleProof, uint256 amount)
        external
        payable
    {
        require(amount <= 15);
        require(
            totalSupply + amount <= MAX_SUPPLY - GIVEAWAY,
            "This will exceed the total supply."
        );
        bytes32 merkleRoot = rootMap;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (block.timestamp < wl_mint_ts) {
            require(false, "Mint is not open yet.");
        } else if (
            block.timestamp >= wl_mint_ts && block.timestamp < public_mint_ts
        ) {
            require(
                MerkleProof.verify(_merkleProof, merkleRoot, leaf),
                "You are not allowed to mint."
            );
            require(msg.value >= wl_price * amount);
        } else {
            if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
                require(msg.value >= wl_price * amount);
            } else {
                require(msg.value >= public_price * amount);
            }
        }

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
            totalSupply++;
        }
    }

    function mintByOwner(address _to, uint256 amount) external onlyOwner {
        require(
            totalSupply + amount <= MAX_SUPPLY,
            "This will exceed the total supply."
        );
        for (uint256 i = 0; i < amount; i++) {
            _mint(_to, _tokenIds.current());
            _tokenIds.increment();
            totalSupply++;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }
}
