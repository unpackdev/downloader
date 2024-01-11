// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./MerkleProof.sol";

contract TPCOFFICIAL is ERC721A {
    using Strings for uint256;

    address public owner;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant MAX_WHITELIST_MINT = 10;
    uint256 public PUBLIC_SALE_PRICE = 0.09 ether;
    uint256 public WHITELIST_SALE_PRICE = 0.07 ether;

    string public baseTokenUri;
    string public placeholderTokenUri;

    bool public isRevealed = false;
    bool public publicSale = false;
    bool public whiteListSale = false;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("The Project Cats Official", "TPCO") {
        owner = msg.sender;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "TPC :: Cannot be called by a contract"
        );
        _;
    }
    modifier OnlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(publicSale, "TPC :: Not Yet Active.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "TPC :: Beyond Max Supply"
        );
        require(
            (totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
            "TPC :: Already minted 3 times!"
        );
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "TPC :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity)
        external
        payable
        callerIsUser
    {
        require(whiteListSale, "TPC :: Not Yet Active.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "TPC :: Cannot mint beyond max supply"
        );
        require(
            (totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT,
            "TPC :: Cannot mint beyond whitelist max mint!"
        );
        require(
            msg.value >= (WHITELIST_SALE_PRICE * _quantity),
            "TPC :: Payment is below the price"
        );
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "TPC :: You are not whitelisted"
        );

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external OnlyOwner {
        require(!teamMinted, "TPC :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 200);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 trueId = tokenId + 1;

        if (!isRevealed) {
            return placeholderTokenUri;
        }
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    function setTokenUri(string memory _baseTokenUri) external OnlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string memory _placeholderTokenUri)
        external
        OnlyOwner
    {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external OnlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function toggleWhiteListSale() external OnlyOwner {
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external OnlyOwner {
        publicSale = !publicSale;
    }

    function toggleReveal() external OnlyOwner {
        isRevealed = !isRevealed;
    }

    function transferOwner(address _to) public OnlyOwner {
        owner = _to;
    }

    function withdraw() external OnlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
