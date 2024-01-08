// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract LazyMonstersSpaceClub is Ownable, ERC721Enumerable, ERC721Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 1000;
    uint256 public constant PRICE = 0.08 * 10**18;
    uint256 public constant MAX_BY_MINT = 10;
    uint256 private constant devSharesIn100 = 35;
    address public feeAddress;
    string public baseTokenURI;

    constructor() ERC721("Lazy Monsters Space Club", "LAZY") {
        pause(true);
    }

    modifier notExceedMaxElements() {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setFeeAddress(address _address) public onlyOwner {
        feeAddress = _address;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count)
        public
        payable
        notExceedMaxElements
        whenNotPaused
    {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function _mintAnElement(address _to) private {
        _tokenIdTracker.increment();
        uint256 id = _totalSupply();
        _safeMint(_to, id);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE * _count;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        address payable to = payable(feeAddress);
        to.transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
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
}
