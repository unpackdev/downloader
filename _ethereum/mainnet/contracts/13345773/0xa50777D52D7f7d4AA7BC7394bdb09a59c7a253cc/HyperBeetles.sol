// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./HyperRandom.sol";

contract HyperBeetles is
    ERC721,
    Ownable,
    ERC721Enumerable,
    ERC721Pausable,
    ERC721Burnable,
    ContextMixin
{
    // Imports
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using HyperRandom for HyperRandom.Random;

    // Structs
    struct HyperBeetle {
        bytes32 momGene; // When genes are required but no parents yet minted (first generation)
        bytes32 dadGene; // Genes will be on all HB.
        uint256 momId;   // momId and dadId will be on all mint-by-breed HB (not first generation)
        uint256 dadId;
        bytes32 gene;
    }

    // Data
    uint256 constant mintPrice = 0.06 ether;
    uint256 constant maxOriginSaleClaims = 1859;
    uint256 public totalOriginSaleClaims;
    uint256 constant maxClaims = 20000 - maxOriginSaleClaims; // limit direct mints to 20,000; does not limit mint-by-breed
    uint256 public totalClaims;
    uint256 constant breedRewardTriplet = 500;
    uint256 constant breedRewardTwin = 100;
    uint256 lastRandom;
    Counters.Counter private hbCounter;
    Counters.Counter private breedCounter;
    string baseURI = 'https://www.hyperbeetles.com/ipfs/';
    address proxyRegistryAddress;
    HyperRandom.Random internal random;
    address ceoAddress;

    // Mappings
    mapping(uint256 => HyperBeetle) public hyperBeetles;

    // Events
    event Claimed(address indexed account, uint256 amount);
    event Breed(
        address indexed account,
        uint256 tokenOne,
        uint256 tokenTwo,
        uint256 breedCount
    );
    event MintTo(address indexed from, address indexed to, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setCeoAddress(address _ceo) external onlyOwner {
        ceoAddress = _ceo;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function pause() external {
        require(
            (msg.sender == owner()) || (msg.sender == ceoAddress),
            'Unauthorized'
        );
        _pause();
    }

    function unpause() external {
        require(
            (msg.sender == owner()) || (msg.sender == ceoAddress),
            'Unauthorized'
        );
        _unpause();
    }

    function mintTo(address _address, uint256 _amount) external {
        require(
            (msg.sender == owner()) || (msg.sender == ceoAddress),
            'Unauthorized'
        );
        require(
            (_amount + totalClaims) <= maxClaims,
            'Mint: exceeds max claims'
        );

        if (_address == address(0)) {
            _address = msg.sender;
        }

        totalClaims += _amount;
        mint(_address, _amount);
        emit MintTo(msg.sender, _address, _amount);
    }

    function mint(address _to, uint256 _amount) internal {
        for (uint256 i = 0; i < _amount; i++) {
            hbCounter.increment();
            uint256 tokenId = hbCounter.current(); // tokenId will be 1 on first mint

            // Claims and direct mints rely on zero-mint parent genes
            bytes32 mGene;
            bytes32 dGene;
            (mGene, dGene) = generateParentGenes();

            HyperBeetle storage hb = hyperBeetles[tokenId];
            hb.gene = bytes32(generateChildGenes(mGene, dGene));
            hb.momGene = mGene;
            hb.dadGene = dGene;

            _safeMint(_to, tokenId);
        }
    }

    function claim(uint256 _amount) external payable whenNotPaused {
        require(
            msg.value == _amount.mul(mintPrice),
            'Claim: wrong value for transaction'
        );

        require(
            (_amount + totalClaims) <= maxClaims,
            'Claim: exceeds max claims'
        );

        uint8 multiplier = 1;
        if (totalOriginSaleClaims < maxOriginSaleClaims) {
            multiplier = 2;
            totalOriginSaleClaims += _amount;
        }
        totalClaims += _amount;
        mint(msg.sender, _amount * multiplier);

        emit Claimed(msg.sender, _amount);
    }

    function breed(uint256 _momTokenId, uint256 _dadTokenId)
        external
        whenNotPaused
    {
        require(ownerOf(_momTokenId) == msg.sender, 'Breed: sender not owner');
        require(ownerOf(_dadTokenId) == msg.sender, 'Breed: sender not owner');
        require(_exists(_momTokenId), 'Breed: nonexistent mom token');
        require(_exists(_dadTokenId), 'Breed: nonexistent dad token');

        HyperBeetle storage mom = hyperBeetles[_momTokenId];
        bytes32 geneOne = mom.gene;
        require((geneOne[0] & 0xf0) == 0x00, 'Mom not female');

        HyperBeetle storage dad = hyperBeetles[_dadTokenId];
        bytes32 geneTwo = dad.gene;
        bytes1 b = geneTwo[0];
        require((b >> 4) == 0x01, 'Dad not male');

        uint256 childCount = 1;
        breedCounter.increment();

        if (breedCounter.current() % breedRewardTriplet == 0) {
            childCount = 3;
        } else if (breedCounter.current() % breedRewardTwin == 0) {
            childCount = 2;
        }

        for (uint256 i = 0; i < childCount; i++) {
            hbCounter.increment();
            uint256 tokenId = hbCounter.current();
            HyperBeetle storage hb = hyperBeetles[tokenId];
            hb.gene = bytes32(generateChildGenes(mom.gene, dad.gene));
            hb.momGene = mom.gene; // For consistency with first generation
            hb.dadGene = dad.gene;
            hb.momId = _momTokenId;
            hb.dadId = _dadTokenId;
            _safeMint(msg.sender, tokenId);
        }

        burn(_momTokenId);
        burn(_dadTokenId);

        emit Breed(
            msg.sender,
            _momTokenId,
            _dadTokenId,
            breedCounter.current()
        );
    }

    function generateChildGenes(bytes32 momGene, bytes32 dadGene)
        internal
        returns (bytes memory b)
    {
        b = new bytes(32);

        for (uint256 i = 0; i < 32; i++) {
            bytes1 momStrand = momGene[i];
            bytes1 dadStrand = dadGene[i];

            bytes1 momValue = momStrand >> 4;
            bytes1 momWeight = momStrand & 0x0f;

            bytes1 dadValue = dadStrand >> 4;
            bytes1 dadWeight = dadStrand & 0x0f;

            bool momWins = geneBattle(momWeight, dadWeight);
            bytes1 weight = (momWins) ? momWeight : dadWeight;
            b[i] = (momWins) ? momValue : dadValue;
            b[i] = b[i] << 4;
            b[i] = b[i] | weight;
        }
    }

    /*
     * @dev Return 'true' means mom gene wins
     */
    function geneBattle(bytes1 _momDominance, bytes1 _dadDominance)
        internal
        returns (bool)
    {
        uint8 momDom = uint8(_momDominance);
        uint8 dadDom = uint8(_dadDominance);
        uint8 dieSides = momDom + dadDom;
        bool equalWeight = (momDom == dadDom);

        if ((equalWeight) || (dieSides < 2)) {
            dieSides = 2;
        }

        uint256 randomNumber = random.generate(dieSides) % dieSides;

        // 2-sided die; 50:50 tie-breaker
        if (equalWeight) {
            if (randomNumber == 0) {
                return true;
            }
            return false;
        }

        // Weighted chance
        if (randomNumber < momDom) {
            return true;
        }

        return false;
    }

    /**
     * @dev Only used when minting/breeding the first generation.
     */
    function generateParentGenes()
        internal
        returns (bytes32 momGene, bytes32 dadGene)
    {
        bytes32 momRand = bytes32(
            abi.encodePacked(random.generate(hbCounter.current()))
        );
        bytes memory momBytes = new bytes(32);
        bytes32 dadRand = bytes32(
            abi.encodePacked(random.generate(totalClaims))
        );
        bytes memory dadBytes = new bytes(32);

        for (uint256 i = 0; i < 32; i++) {
            if (i == 0) {
                momBytes[i] = momRand[i] & 0x0f;
                dadBytes[i] = (dadRand[i] & 0x0f) | 0x10;
            } else {
                momBytes[i] = momRand[i];
                dadBytes[i] = dadRand[i];
            }
        }

        momGene = bytes32(abi.encodePacked(momBytes));
        dadGene = bytes32(abi.encodePacked(dadBytes));
    }

    function breedCount() external view returns (uint256) {
        return breedCounter.current();
    }

    /**
     * @dev Because we use the counter for IDs, returns the most-recently created token ID.
     */
    function totalMinted() external view returns (uint256) {
        return hbCounter.current();
    }

    function withdrawEther(address payable _to, uint256 _amount) external {
        require(
            (msg.sender == owner()) || (msg.sender == ceoAddress),
            'Unauthorized'
        );
        require(_to != address(0), 'Withdraw: to null address');

        if (_amount == 0) {
            _amount = address(this).balance;
        }

        _to.transfer(_amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        view
        override(Context)
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function renounceOwnership() public view override onlyOwner {
        revert(
            'Security: Renouncing ownership is not possible with this contract.'
        );
    }
}
