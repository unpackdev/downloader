//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract OneHundredTwentyChequeredSphere is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    event Withdraw(address indexed operator);

    uint256 public constant MAX_SUPPLY = 2020;

    string public baseURI;
    uint256 public fee = 0.08 ether;
    bool public isBurnable = false;

    address public proxyRegistryAddress;

    Counters.Counter private _nextTokenId;
    string private _contractURI;

    modifier onlyHolder(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "Only Holder");
        _;
    }

    modifier whenBurnable() {
        require(isBurnable, "Not Burnable");
        _;
    }

    constructor(
        string memory _baseUri,
        string memory _baseContractUri,
        address _proxyAddress
    ) ERC721("OneHundredTwentyChequeredSphere", "OHTCS") {
        baseURI = _baseUri;
        _contractURI = _baseContractUri;
        proxyRegistryAddress = _proxyAddress;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractUri) external onlyOwner {
        _contractURI = contractUri;
    }

    function setIsBurnable(bool status) external onlyOwner {
        isBurnable = status;
    }

    // Open Sea implmentation
    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        baseURI = baseUri;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint() public payable whenNotPaused {
        require(fee <= msg.value, "Insufficient fee");
        require(_nextTokenId.current() < MAX_SUPPLY, "Exceeds max supply");
        _nextTokenId.increment();
        _mint(_msgSender(), _nextTokenId.current());
    }

    function mintTo(address beneficiary) public payable whenNotPaused {
        require(fee <= msg.value, "Insufficient fee");
        require(_nextTokenId.current() < MAX_SUPPLY, "Exceeds max supply");
        _nextTokenId.increment();
        _mint(beneficiary, _nextTokenId.current());
    }

    function burn(uint256 tokenId) public onlyHolder(tokenId) whenBurnable {
        _burn(tokenId);
    }

    // Open Sea implmentation
    function setOSRegistryAddress(address newAddress) external onlyOwner {
        proxyRegistryAddress = newAddress;
    }

    // Open Sea implmentation
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Not Enough Balance Of Contract");
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer Failed");
        emit Withdraw(msg.sender);
    }

    receive() external payable {}

    fallback() external payable {}
}
