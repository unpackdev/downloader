// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./MerkleProof.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract EagerBeaverQueen is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // total number of tokenIds minted
    Counters.Counter public tokenCount;

    // last id of NFT minted
    Counters.Counter public currentId;

    // mapping to keep track of all tokenURIs
    mapping(uint256 => string) private _tokenURIs;

    bytes32 public _merkleRoot =
        0x7e51034f82762fa3fa646105de61d65a8bb6997b76bbf98d66b9c459ab63d333;

    /**
     * @dev _baseTokenURI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */

    string _baseTokenURI;
    string _unrevealedURI =
        "https://eb.mypinata.cloud/ipfs/QmRqwMoAArWmrCjrQYJJ6T6t5dGkXaNMrGaNhybNBGxygo/EB0322_hidden.json";

    //  _price is the price of one Eager Beaver Queen NFT
    uint256 public _price = 0.15 ether;

    // _revealed is used to indicate if the NFTs have been revealed or not
    bool private _hasMintedForCreators;

    // _revealed is used to indicate if the NFTs have been revealed or not
    bool public _revealed;

    // _paused is used to pause the contract in case of an emergency
    bool public _paused;

    // max number of EagerBeaver Queens
    uint256 public maxTokenIds = 500;

    // timestamp to keep track of if presale started
    uint256 public timeToStartPresale = 1647500400;

    // timestamp for when presale would end
    uint256 public timeToEndPresale = 1647586800;

    modifier onlyWhenNotPaused() {
        require(!_paused, "Contract currently paused");
        _;
    }

    modifier onlyWhenHasNotMintedForCreators() {
        require(!_hasMintedForCreators, "Contract currently paused");
        _;
    }

    modifier onlyWhenNotRevealed() {
        require(!_revealed, "NFTs have already been revealed");
        _;
    }

    /**
     * @dev ERC721 constructor takes in a `name` and a `symbol` to the token collection.
     * name in our case is `EagerBeaver-Queen` and symbol is `EBQ`.
     */

    constructor() ERC721("EagerBeaver-Queen", "EBQ") {
        mintForCreators(333);
        _hasMintedForCreators = true;
    }

    function mintForCreators(uint256 tokenId)
        private
        onlyOwner
        onlyWhenHasNotMintedForCreators
    {
        tokenCount.increment();
        _safeMint(0x9ed3A670627dca21dAd982d47Bfd8a09E69f52Ec, tokenId);
    }

    /**
     * @dev one time action to set baseURI in order to reveal NFT collection
     */
    function revealCollection(string memory revealedBaseURI)
        public
        onlyOwner
        onlyWhenNotRevealed
    {
        _baseTokenURI = revealedBaseURI;
        _revealed = true;
    }

    /**
     * @dev presaleMint allows an user to mint one NFT per transaction during the presale.
     */
    function presaleMint(bytes32[] calldata _merkleProof)
        public
        payable
        onlyWhenNotPaused
        returns (uint256)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, _merkleRoot, leaf),
            "You are not whitelisted"
        );
        require(
            totalSupply() < maxTokenIds,
            "Exceeded maximum Eager Beaver Queen supply"
        );
        require(
            balanceOf(msg.sender) < 2,
            "Cannot mint more than 2 NFTs during presale"
        );
        require(msg.value >= _price, "Invalid Ether amount sent");
        currentId.increment();
        tokenCount.increment();
        // skip any already minted NFTs
        while (_exists(currentId.current())) {
            currentId.increment();
        }
        uint256 tokenId = currentId.current();
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    /**
     * @dev mint allows an user to mint 1 NFT per transaction after the presale has ended.
     */
    function mint() public payable onlyWhenNotPaused returns (uint256) {
        require(
            block.timestamp > timeToEndPresale,
            "Presale has not ended yet"
        );
        require(
            totalSupply() < maxTokenIds,
            "Exceeded maximum Eager Beaver Queen supply"
        );
        require(msg.value >= _price, "Invalid Ether amount sent");

        currentId.increment();
        tokenCount.increment();
        // skip any already minted NFTs
        while (_exists(currentId.current())) {
            currentId.increment();
        }
        uint256 tokenId = currentId.current();
        _safeMint(msg.sender, tokenId);
        return tokenId;
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
        string memory baseURI = _baseURI();

        if (!_revealed) return _unrevealedURI;

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return tokenCount.current();
    }

    /**
     * @dev setPaused makes the contract paused or unpaused
     */
    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
