//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract FOMONOMO is ERC721A, Ownable {
    using Strings for uint256;
    bytes32 public whitelistRoot;
    bytes32 public freelistRoot;

    enum SaleStatus {
        Whitelist,
        Freelist,
        Public,
        Closed
    }

    uint256 public PRICE_PER_TOKEN = 0.15 ether;
    uint256 public MAX_SUPPLY = 1000;
    uint256 public SAVED_FOR_OG = 211;
    uint256 public maxWhitelistMint = 1;
    SaleStatus public saleStatus = SaleStatus.Closed;
    mapping(address => uint8) private _whitelist;
    mapping(address => uint8) private _freelist;
    mapping(address => uint8) private _publicCount;

    constructor(bytes32 _whitelistRoot, bytes32 _freelistRoot)
        ERC721A("FOMONOMO", "FN")
    {
        whitelistRoot = _whitelistRoot;
        freelistRoot = _freelistRoot;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setSaleStatus(SaleStatus _newStatus) external onlyOwner {
        saleStatus = _newStatus;
    }

    function setMaxWhitelistMint(uint256 _maxMint) external onlyOwner {
        maxWhitelistMint = _maxMint;
    }

    // whitelist mint
    function mintWhiteList(uint8 numberOfTokens, bytes32[] memory proof)
        public
        payable
    {
        require(saleStatus == SaleStatus.Whitelist, "White list is not active");
        require(
            MerkleProof.verify(
                proof,
                whitelistRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on the whitelist"
        );
        uint256 ts = totalSupply();
        require(
            numberOfTokens + _whitelist[msg.sender] <= maxWhitelistMint,
            "Exceeded max available to purchase"
        );

        require(
            ts + numberOfTokens <= MAX_SUPPLY - SAVED_FOR_OG,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _whitelist[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    // free mint
    function mintFreeList(bytes32[] memory proof) public payable {
        require(saleStatus == SaleStatus.Freelist, "OG mint is not active");
        require(
            MerkleProof.verify(
                proof,
                freelistRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on the OG list"
        );

        require(
            _freelist[msg.sender] == 0,
            "Exceeded max available to purchase"
        );

        _freelist[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function reserve(uint256 n) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + n <= MAX_SUPPLY, "not enough tokens");
        _safeMint(msg.sender, n);
    }

    // metadata URI
    string private _baseTokenURI =
        "ipfs://QmXzfMNJczpZ4qexBrYaoCFSietisqnNTdWVH4bmeVZhQM/";

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // mint
    function mint(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(
            saleStatus == SaleStatus.Public,
            "Public sale must be active to mint tokens"
        );
        require(
            ts + numberOfTokens <= MAX_SUPPLY - SAVED_FOR_OG,
            "Purchase would exceed max tokens"
        );
        require(
            numberOfTokens + _publicCount[msg.sender] < 6,
            "Exceeded max available to purchase"
        );
        require(
            PRICE_PER_TOKEN * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _publicCount[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function withdrawMoney() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}