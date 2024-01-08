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
        bytes32 gene;
        uint256 parentOneId; // parentOneId and parentTwoId will be on all mint-by-breed HB (not first generation)
        uint256 parentTwoId;
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
    bool _breedPaused = true;

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

    function setBreedPaused(bool _pauseBreeding) external onlyOwner {
       _breedPaused =  _pauseBreeding;
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

            hyperBeetles[hbCounter.current()].gene = bytes32(abi.encodePacked(random.generate(hbCounter.current())));

            _safeMint(_to, hbCounter.current());
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

    function breed(uint256 _parentOneId, uint256 _parentTwoId)
        external
        whenNotPaused
    {
        require(_breedPaused != true, 'Breed: paused');
        require(ownerOf(_parentOneId) == msg.sender, 'Breed: sender not owner');
        require(ownerOf(_parentTwoId) == msg.sender, 'Breed: sender not owner');

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
            hb.gene = bytes32(abi.encodePacked(random.generate(hbCounter.current())));
            hb.parentOneId = _parentOneId;
            hb.parentTwoId = _parentTwoId;
            _safeMint(msg.sender, tokenId);
        }

        burn(_parentOneId);
        burn(_parentTwoId);

        emit Breed(
            msg.sender,
            _parentOneId,
            _parentTwoId,
            breedCounter.current()
        );
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
