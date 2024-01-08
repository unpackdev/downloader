pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract NftFarmSeries1 is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    bool public _isSaleActive = false;
    string private _baseURIExtended;

    // Constants
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public NFT_PRICE = .05 ether;

    event SaleStarted();
    event SaleStopped();
    event TokenMinted(uint256 supply);

    constructor() ERC721('BigBang Collection by Makeable.art', 'MAR-BB') {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function getNFTsByOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _baseMint (uint256 num_tokens, address to) internal {
        require(totalSupply().add(num_tokens) <= MAX_SUPPLY, 'Sale would exceed max supply');
        uint256 supply = totalSupply();
        for (uint i=0; i < num_tokens; i++) {
            _safeMint(to, supply + i);
        }
        emit TokenMinted(totalSupply());
    }

    function mint(address _to, uint _count) public payable {
        require(_isSaleActive, 'Sale must be active to mint BigBang NFTs');
        require(NFT_PRICE*_count <= msg.value, 'Not enough ether sent (0.05 ETH for each token)');
        require(_count <= 20, 'Exceeding 20 NFTs max mintable limit for contract call');
        _baseMint(_count, _to);
    }

    function ownerMint(address[] memory recipients, uint256[] memory amount) public onlyOwner {
        require(recipients.length == amount.length, 'Arrays needs to be of equal length');
        uint256 totalToMint = 0;
        for (uint256 i=0; i<amount.length; i++) {
            totalToMint = totalToMint + amount[i];
        }
        require(totalSupply().add(totalToMint) <= MAX_SUPPLY, 'Mint will exceed total supply');

        for (uint256 i=0; i<recipients.length; i++) {
            _baseMint(amount[i], recipients[i]);
        }
    }

    function pauseSale() public onlyOwner {
        _isSaleActive = false;
        emit SaleStopped();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setPrice(uint256 price) external onlyOwner {
        NFT_PRICE = price;
    }

    function startSale() public onlyOwner {
        _isSaleActive = true;
        emit SaleStarted();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}