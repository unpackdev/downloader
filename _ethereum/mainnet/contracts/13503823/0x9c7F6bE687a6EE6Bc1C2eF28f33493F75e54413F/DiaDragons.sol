// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./console.sol";

contract Diadragons is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    bool public _isSaleActive = false;
    bool public _isPresaleActive = true;
    uint256 public offsetIndex = 0;
    uint256 public offsetIndexBlock = 0;
    uint256 public revealTimeStamp = block.timestamp + (86400 * 7);

    // Constants
    uint256 public constant TIER1_PRICE = .050 ether;
    uint256 public constant TIER2_PRICE = .046 ether;
    uint256 public constant TIER3_PRICE = .040 ether;
    uint256 public constant TIER4_PRICE = .035 ether;

    uint256 public constant TIER1_NUM_TOKENS = 1;
    uint256 public constant TIER2_NUM_TOKENS = 5;
    uint256 public constant TIER3_NUM_TOKENS = 10;
    uint256 public constant TIER4_NUM_TOKENS = 50;

    uint256 public constant MAX_SUPPLY = 11111;
    string public DIADRAGONS_PROVENANCE = "";

    string public baseURI;
    string private _preRevealURI;

    event SaleStarted();
    event SaleStopped();
    event PresaleStarted();
    event PresaleStopped();
    event TokenMinted(uint256 supply);

    constructor() ERC721("DiaDragons", "DD") {}

    function startSale() public onlyOwner {
        _isSaleActive = true;
        emit SaleStarted();
    }

    function pauseSale() public onlyOwner {
        _isSaleActive = false;
        emit SaleStopped();
    }

    function isSaleActive() public view returns (bool) {
        return _isSaleActive;
    }

    function startPresale() public onlyOwner {
        _isPresaleActive = true;
        emit PresaleStarted();
    }

    function pausePresale() public onlyOwner {
        _isPresaleActive = false;
        emit PresaleStopped();
    }

    function isPresaleActive() public view returns (bool) {
        return _isPresaleActive;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    function getDiadragonsByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function mintDiadragons(uint256 numDiadragons) public payable {
        require(_isSaleActive, "Sale must be active to mint Diadragons");
        require(
            totalSupply().add(numDiadragons) <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(
            TIER1_PRICE.mul(numDiadragons) <= msg.value,
            "Not enough ether sent (<.05 ETH per DiaDragon)"
        );
        _mintDiadragons(numDiadragons, msg.sender);
        emit TokenMinted(totalSupply());
    }

    function mintDiaDragonTier1() public payable {
        require(_isPresaleActive, "Sale must be active to mint DiaDragons");
        require(
            totalSupply().add(TIER1_NUM_TOKENS) <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(TIER1_PRICE <= msg.value, "Not enough ether sent (<0.05 ETH)");
        _mintDiadragons(TIER1_NUM_TOKENS, msg.sender);
        emit TokenMinted(totalSupply());
    }

    function mintDiaDragonTier2() public payable {
        require(_isPresaleActive, "Sale must be active to mint DiaDragons");
        require(
            totalSupply().add(TIER2_NUM_TOKENS) <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(
            TIER2_PRICE.mul(TIER2_NUM_TOKENS) <= msg.value,
            "Not enough ether sent (<0.23 ETH)"
        );
        _mintDiadragons(TIER2_NUM_TOKENS, msg.sender);
        emit TokenMinted(totalSupply());
    }

    function mintDiaDragonTier3() public payable {
        require(_isPresaleActive, "Sale must be active to mint DiaDragons");
        require(
            totalSupply().add(TIER3_NUM_TOKENS) <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(
            TIER3_PRICE.mul(TIER3_NUM_TOKENS) <= msg.value,
            "Not enough ether sent (<0.4 ETH)"
        );
        _mintDiadragons(TIER3_NUM_TOKENS, msg.sender);
        emit TokenMinted(totalSupply());
    }

    function mintDiaDragonTier4() public payable {
        require(_isPresaleActive, "Sale must be active to mint DiaDragons");
        require(
            totalSupply().add(TIER4_NUM_TOKENS) <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(
            TIER4_PRICE.mul(TIER4_NUM_TOKENS) <= msg.value,
            "Not enough ether sent (<1.75 ETH)"
        );
        _mintDiadragons(TIER4_NUM_TOKENS, msg.sender);
        emit TokenMinted(totalSupply());
    }

    function reserveDiadragons(uint256 numDiadragons) public onlyOwner {
        require(
            totalSupply().add(numDiadragons) <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        _mintDiadragons(numDiadragons, msg.sender);
    }

    function airdropDiadragon(uint256 numDiadragons, address recipient)
        public
        onlyOwner
    {
        require(
            totalSupply().add(numDiadragons) <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        _mintDiadragons(numDiadragons, recipient);
        emit TokenMinted(totalSupply());
    }

    function airdropDiadragonToMany(address[] memory recipients)
        external
        onlyOwner
    {
        require(
            totalSupply().add(recipients.length) <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            airdropDiadragon(1, recipients[i]);
        }
    }

    function _mintDiadragons(uint256 numDiadragons, address recipient)
        internal
    {
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < numDiadragons; i++) {
            _safeMint(recipient, supply + i);
        }

        if (
            offsetIndexBlock == 0 &&
            (totalSupply() >= MAX_SUPPLY || block.timestamp >= revealTimeStamp)
        ) {
            offsetIndexBlock = block.number;
        }
    }

    function setOffsetIndex() public {
        require(offsetIndex == 0, "Starting index has already been set");
        require(offsetIndexBlock != 0, "Starting index block must be set");

        if (block.number.sub(offsetIndexBlock) > 255) {
            offsetIndex = uint256(blockhash(block.number - 1)).mod(MAX_SUPPLY);
        } else {
            offsetIndex = uint256(blockhash(offsetIndexBlock)).mod(MAX_SUPPLY);
        }

        if (offsetIndex == 0) {
            offsetIndex = 1;
        }
    }

    function emergencySetOffsetIndexBlock() public onlyOwner {
        require(offsetIndex == 0, "Starting index is already set");
        offsetIndexBlock = block.number;
    }

    function setProvenanceHash(string memory provenanceHash)
        external
        onlyOwner
    {
        DIADRAGONS_PROVENANCE = provenanceHash;
    }

    function setRevealTimestamp(uint256 newRevealTimeStamp) external onlyOwner {
        revealTimeStamp = newRevealTimeStamp;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPreRevealURI(string memory preRevealURI) external onlyOwner {
        _preRevealURI = preRevealURI;
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
        if (totalSupply() >= MAX_SUPPLY || block.timestamp >= revealTimeStamp) {
            uint256 offsetId = tokenId.add(MAX_SUPPLY.sub(offsetIndex)).mod(
                MAX_SUPPLY
            );
            return string(abi.encodePacked(_baseURI(), offsetId.toString()));
        } else {
            return _preRevealURI;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
