// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "LibPart.sol";
import "LibRoyaltiesV2.sol";
import "RoyaltiesV2.sol";

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721Burnable.sol";
import "Pausable.sol";
import "Ownable.sol";
import "Counters.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";

import "Whitelist.sol";

contract DragonRascal is
    RoyaltiesV2,
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    uint256 public balanceLimit; // max dragons per address
    uint96 public royaltyRate; // in basis points, i.e. 500 == 5%
    address public royaltiesReceiver; // where the royalities are paid
    uint256 public price; // price per dragon
    uint256 public tokenLimit; // total available dragons
    string public baseURI; // the prefix for tokenURI
    string public suffixURI; // the suffix for the tokenURI

    Whitelist[] public whitelists;
    uint256 public mintStart; // the time public mint starts

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory _initBaseURI,
        address _royaltiesRecipient,
        uint256 _mintStart
    ) ERC721("Dragon Rascals", "DRAGON") {
        balanceLimit = 10;
        royaltyRate = 500; // 5%
        royaltiesReceiver = _royaltiesRecipient;
        price = 100000000000000000; // 0.1 ether
        tokenLimit = 8888;
        baseURI = _initBaseURI;
        suffixURI = ".json";
        _tokenIdCounter.increment(); // start tokenId at 1
        mintStart = _mintStart;
    }

    function setMintStart(uint256 _mintStart) external onlyOwner {
        mintStart = _mintStart;
    }

    // start is sale period start
    // end is period end or 0 for no end
    // addresses is the array to whitelist
    // entries is the corresponding number of tokens availble to mint
    function createWhitelist(
        uint256 start,
        uint256 end,
        address[] calldata addresses,
        uint256[] calldata entries
    ) external onlyOwner {
        Whitelist whitelist = new Whitelist(start, end);
        whitelist.set(addresses, entries);
        whitelists.push(whitelist);
    }

    // Set the prefix for the tokenURI
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // Set the suffix for the tokenURI
    function setSuffixURI(string memory _suffixURI) external onlyOwner {
        suffixURI = _suffixURI;
    }

    // Set the price per dragon
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    // Set the total available dragons
    function setTokenLimit(uint256 _tokenLimit) external onlyOwner {
        tokenLimit = _tokenLimit;
    }

    // Set the maximum number of tokens per address
    function setBalanceLimit(uint256 _balanceLimit) external onlyOwner {
        balanceLimit = _balanceLimit;
    }

    // Set the royalties rate in basis points
    function setRoyaltyRate(uint96 _royaltyRate) external onlyOwner {
        royaltyRate = _royaltyRate;
    }

    // Set the recipient address for royalties
    function setRoyaltiesReceiver(address _royaltiesReceiver)
        external
        onlyOwner
    {
        royaltiesReceiver = _royaltiesReceiver;
    }

    function withdraw(address _recipient) external payable onlyOwner {
        require(_recipient != address(0), "zero address");
        payable(_recipient).transfer(address(this).balance);
    }

    function _isMintable(uint256 qty) private returns (bool) {
        for (uint8 i = 0; i < whitelists.length; i++) {
            if (whitelists[i].isMintable(qty, msg.sender)) {
                return true;
            }
        }
        // not on a whitelist
        return
            (block.timestamp > mintStart) &&
            ((balanceOf(msg.sender) + qty) <= balanceLimit);
    }

    function _doMint(address to, uint256 qty) private {
        for (uint256 i = 0; i < qty; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            emit RoyaltiesSet(tokenId, _getRoyalties(tokenId));
            emit Transfer(owner(), to, tokenId);
        }
    }

    function airdrop(address to, uint256 qty) external onlyOwner {
        _doMint(to, qty);
    }

    // Mint qty tokens to address to
    function mint(address to, uint256 qty) external payable nonReentrant {
        require((qty + totalSupply()) <= tokenLimit, "sold out");
        require(_isMintable(qty), "denied");
        // skip payment check for owner so we can airdop
        require(msg.value >= (price * qty), "insufficient funds");
        _doMint(to, qty);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // the tokenURI is the concat of baseURI + tokenId + suffixURI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        ownerOf(tokenId); // raises on non-existent tokenId
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), suffixURI)
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) ||
            (interfaceId == _INTERFACE_ID_ERC2981) ||
            super.supportsInterface(interfaceId);
    }

    // ERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltiesReceiver, (_salePrice * royaltyRate) / 10000);
    }

    function _getRoyalties(uint256 tokenId)
        private
        view
        returns (LibPart.Part[] memory)
    {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = royaltyRate;
        _royalties[0].account = payable(royaltiesReceiver);
        return _royalties;
    }

    function getRaribleV2Royalties(uint256 id)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        return _getRoyalties(id);
    }
}
