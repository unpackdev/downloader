// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";

contract HistoricalEraser is ERC721, ERC721Enumerable, Ownable, Pausable {

    using SafeMath for uint256;

    string public TOKEN_PROVENANCE = "";

    uint256 public constant MAX_TOKENS = 10000;

    uint256 public constant MAX_TOKENS_PER_PURCHASE = 30;

    uint256 private price = 80000000000000000; // 0.08 Ether

    bool public saleIsActive = false;

    constructor() ERC721("HistoricalEraser", "ERASER") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmZTxN2rKX4r943izhNfEEwKPEfLRgqaixnKH5NHRsvg9g/";
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        TOKEN_PROVENANCE = _provenanceHash;
    }

    function reserveTokens(address _to, uint256 _reserveAmount) public onlyOwner {
        uint supply = totalSupply();
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mint(uint256 _count) public payable {
        uint256 totalSupply = totalSupply();
        require(saleIsActive, "Sale is not active");
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1, "Exceeds maximum tokens you can purchase in a single transaction");
        require(totalSupply + _count < MAX_TOKENS + 1, "Exceeds maximum tokens available for purchase");
        require(msg.value >= price.mul(_count), "Ether value sent is not correct");

        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}
