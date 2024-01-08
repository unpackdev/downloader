//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract GrowingPains is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public _nextTokenId;

    // Core constants.
    string public constant NAME = "Julian Mudd - Growing Pains";
    string public constant SYMBOL = "JMGP";
    address public constant WITHDRAW_ADDRESS = 0x81933D6959dE2cc22E5073b3fb32dE108b6F02D9;

    // Minting constants.
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_MINT_AMOUNT = 20;
    uint256 public constant RESERVED_AMOUNT = 10;

    // Core variables.
    string public baseURI = "https://gp.metadata.julianmudd.com/api/v1/tokens/";
    uint256 public price = 0.05 ether;
    bool public isMintEventActive = false;

    // Provenance (will be set once the minting event is finished).
    string public provenanceHash = "";

    // Events.
    event Mint(uint256 fromTokenId, uint256 amount, address owner);
    event Reserve(uint256 fromTokenId, uint256 amount, address owner);

    constructor() ERC721(NAME, SYMBOL) {
        _nextTokenId.increment();
    }

    // Mint.
    function mint(uint256 mintAmount) public payable {
        uint256 totalSupplyPreMint = totalSupply();

        require(isMintEventActive, "Mint event is not currently active");
        require(mintAmount <= MAX_MINT_AMOUNT, "Mint would exceed maximum token amount per mint");
        require((totalSupplyPreMint + mintAmount) <= MAX_SUPPLY, "Mint would exceed maximum supply");
        require(msg.value >= (mintAmount * price), "ETH value sent is not correct");

        uint i;
        for (i = 0; i < mintAmount; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }

        emit Mint(totalSupplyPreMint, mintAmount, msg.sender);
    }

    // Reserve.
    function reserve() public onlyOwner {
        uint256 totalSupplyPreReserve = totalSupply();

        require((totalSupplyPreReserve + RESERVED_AMOUNT) <= MAX_SUPPLY, "Reserve would exceed maximum supply");

        uint i;
        for (i = 0; i < RESERVED_AMOUNT; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }

        emit Reserve(totalSupplyPreReserve, RESERVED_AMOUNT, msg.sender);
    }

    // Total supply.
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    // Provenance (set it once the minting event is finished as we dynamically generate all the assets).
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    // Price (in case it needs to be changed).
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // Base URI.
    // Overrides _baseURI in ERC721.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    // Emergency measure, should be used only in case something happens with the metadata API.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    // Mint event status.
    function startMintEvent() public onlyOwner() {
        isMintEventActive = true;
    }

    function pauseMintEvent() public onlyOwner() {
        isMintEventActive = false;
    }

    // Withdraw.
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(WITHDRAW_ADDRESS).transfer(balance);
    }
}
