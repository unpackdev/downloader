pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC721A.sol";

// find out more on apetoadz.com

contract ApeToadzFarm is ERC721A, Ownable {

    using Strings for uint256;

    // boolean
    bool public isMintOpen = true;

    //uint256s
    uint256 MAX_SUPPLY = 6669;
    uint256 FREE_MINTS = 669;
    uint256 PRICE = .02 ether;
    uint256 MAX_MINT_PER_TX = 20;

    // strings
    string private _baseURIExtended;

    constructor() ERC721A("ApeToadz", "APETOADZ", MAX_MINT_PER_TX, MAX_SUPPLY) { }

    function _intMint(address _to, uint _count) internal {
        uint _totalSupply = totalSupply();
        uint num_tokens = _count;
        if ((num_tokens + _totalSupply) > MAX_SUPPLY) {
            num_tokens = MAX_SUPPLY - _totalSupply;
        }
        _safeMint(_to, num_tokens);
    }

    function mint(address _to, uint _count) public payable {
        require(isMintOpen, "Mint not yet opened!");
        require(_count <= MAX_MINT_PER_TX, "Max mint per transaction exceeded");

        uint _totalSupply = totalSupply();
        if (_totalSupply > FREE_MINTS) {
            require(PRICE*_count <= msg.value, 'Not enough ether sent');
        }

        require(_totalSupply < MAX_SUPPLY, 'Max supply already reached');
        _intMint(_to, _count);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function dMint(uint _count) public onlyOwner {
        _intMint(msg.sender, _count);
    }

    function setMintOpen(bool _isMintOpen) public onlyOwner {
        isMintOpen = _isMintOpen;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    function setFreeMint(uint256 _freeMint) public onlyOwner {
        FREE_MINTS = _freeMint;
    }

}
