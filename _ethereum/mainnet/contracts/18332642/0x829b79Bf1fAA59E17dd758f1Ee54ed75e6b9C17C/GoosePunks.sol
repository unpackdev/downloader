// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

// File: contracts/GoosePunks.sol

/**
 * @title GoosePunks contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract GoosePunks is Ownable, ReentrancyGuard, ERC721Royalty {
    using Counters for Counters.Counter;

    event FlipSale(bool state);
    event PriceChange(uint256 price);
    event ClaimFund(address _address, uint256 amount);
    event Withdraw(address _address, uint256 amount);

    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant MAX_SUPPLY = 879;
    uint256 public constant MAX_PER_ADDRESS = 5;
    address public artistAddress = 0xE0753cfcAbB86c2828B79a3DDD4Faf6AF0db0EB4; // dlc.eth

    // State variables
    // ------------------------------------------------------------------------
    Counters.Counter public supply;
    string public baseURI;
    bool public isSaleActive = false;
    uint256 public price = 0 ether;
    uint96 public royaltyFee;
    uint256 public artistRoyalty = 0;
    uint256 public ownerRoyalty = 0;
    mapping(address => uint256) public minted;

    // Modifiers
    // ------------------------------------------------------------------------
    modifier mintCompliance(uint256 numberOfTokens) {
        require(isSaleActive, "Sale must be active to mint");
        require(
            supply.current() + numberOfTokens <= MAX_SUPPLY,
            "Max supply exceeded!"
        );
        require(
            minted[_msgSender()] + numberOfTokens <= MAX_PER_ADDRESS,
            "Exceeds per address supply"
        );
        require(
            price * numberOfTokens == msg.value,
            "Ether value is not correct"
        );
        _;
    }

    modifier onlyArtist() {
        require(msg.sender == artistAddress, "Only artist can withdraw");
        _;
    }

    modifier onlyEOA() {
        require(address(msg.sender).code.length == 0, "Must be an EOA");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint96 _royaltyFee
    ) ERC721(_name, _symbol) {
        royaltyFee = _royaltyFee;
        _setDefaultRoyalty(address(this), _royaltyFee);
    }

    receive() external payable {
        splitRoyalty(msg.value);
    }

    function splitRoyalty(uint256 amount) private {
        artistRoyalty += amount / 2;
        ownerRoyalty += amount / 2;
    }

    // URI functions
    // ------------------------------------------------------------------------
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    // Operational functions
    // ------------------------------------------------------------------------
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);

        artistRoyalty = 0;
        ownerRoyalty = 0;

        emit Withdraw(msg.sender, balance);
    }

    function claimArtistRoyalty() external onlyArtist {
        payable(artistAddress).transfer(artistRoyalty);

        emit ClaimFund(artistAddress, artistRoyalty);
        artistRoyalty = 0;
    }

    function claimOwnerRoyalty(address _address) external onlyOwner {
        payable(_address).transfer(ownerRoyalty);

        emit ClaimFund(_address, ownerRoyalty);
        ownerRoyalty = 0;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;

        emit PriceChange(price);
    }

    function setRoyaltyFee(uint96 _royaltyFee) public onlyOwner {
        royaltyFee = _royaltyFee;
        _setDefaultRoyalty(address(this), _royaltyFee);
    }

    // Sale switch functions
    // ------------------------------------------------------------------------
    function flipSale() external onlyOwner {
        isSaleActive = !isSaleActive;

        emit FlipSale(isSaleActive);
    }

    // Mint functions
    // ------------------------------------------------------------------------
    function mint(
        uint256 numberOfTokens
    ) public payable nonReentrant onlyEOA mintCompliance(numberOfTokens) {
        minted[_msgSender()] += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            supply.increment();
            _safeMint(_msgSender(), supply.current());
        }
    }

    function getTotalMinted(address _address) public view returns (uint256) {
        return minted[_address];
    }
}
