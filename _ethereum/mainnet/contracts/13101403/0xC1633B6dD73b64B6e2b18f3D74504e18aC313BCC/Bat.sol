// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract DeflationaryBats is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    // Multisig address
    address public constant MULTISIG = address(0xe6Cf2c1DAdeC4D1c42be348e74a8fe45cc52777B);

    // Commit merkle tree hash of NFTs
    bytes32 public constant MERKLE_ROOT_HASH = bytes32(0x6a76719211a8463a83b135088c92b2174b417f2fdc7c882eec5ad71eaefc485d);

    // Maximum Mint number
    uint256 public constant MAX_ELEMENTS = 1559;

    // Each user can mint max 20 per tx
    uint256 public constant MAX_BY_MINT = 20;

    // ********** //

    // Token Id (starts at 1, not 0)
    uint256 private _tokenIdTracker = 1;

    // Token URL, will initially be hosted on a server, and revealed as minted
    // once everything has been minted, it'll move to IPFS
    string public baseTokenURI = "https://nft.deflationarybats.com/";

    constructor() ERC721("Deflationary Bats", "DBAT") {
        // First Id is reserved for vitalik.eth
        _mintOne(address(this));

        // Gnosis multisig is the owner
        transferOwnership(MULTISIG);
    }

    modifier saleIsOpen() {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");

        uint256 price = 0;
        for (uint256 i = 1; i <= _count; i++) {
            price = price + getMintSalePriceById(total + i);
        }
        require(msg.value >= price, "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintOne(_to);
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function getMintSalePriceById(uint256 _tokenId) public pure returns (uint256) {
        if (_tokenId <= 500) {
            return 0.1 ether;
        }

        if (_tokenId <= 1000) {
            return 0.3 ether;
        }

        if (_tokenId <= 1250) {
            return 0.5 ether;
        }

        if (_tokenId <= 1500) {
            return 0.9 ether;
        }

        if (_tokenId <= 1550) {
            return 1.7 ether;
        }

        if (_tokenId <= 1556) {
            return 10 ether;
        }

        return 100 ether;
    }

    function claimFirstBat() public {
        // Vitalik.eth or the multisig can claim this
        if (!(msg.sender == 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045 || msg.sender == MULTISIG)) {
            return;
        }

        // If its already been claimed
        if (ownerOf(1) != address(this)) {
            return;
        }

        _transfer(address(this), msg.sender, 1);
    }

    // **** Permissioned functions **** //

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(MULTISIG, address(this).balance);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // **** Internal functions **** //

    function _totalSupply() internal view returns (uint256) {
        // Token ID starts at 1
        return _tokenIdTracker - 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // **** Private functions **** //

    function _mintOne(address _to) private {
        require(_tokenIdTracker <= MAX_ELEMENTS, "exceed max mintable");
        uint256 id = _tokenIdTracker;
        _safeMint(_to, id);
        emit BatMinted(id);

        _tokenIdTracker++;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "!transfer");
    }

    // **** Overriding functions **** //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // *** Events **** //

    event BatMinted(uint256 indexed id);
}
