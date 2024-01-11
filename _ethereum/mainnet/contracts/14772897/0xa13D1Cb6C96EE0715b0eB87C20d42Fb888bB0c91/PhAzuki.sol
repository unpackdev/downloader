pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract PhAzuki is ERC721A, Ownable {

    
    bool mintPaused;

    uint256 public immutable maxSupply;
    uint256 public saleTime;
    uint256 public mintPrice;

    string private _currentBaseURI;

     constructor(
        uint256 maxBatchSize_,
        uint256 maxSupply_,
        uint256 mintPrice_
    ) ERC721A("PhAzuki", "PHAZUKI", maxBatchSize_) {
        maxSupply = maxSupply_;
        mintPrice = mintPrice_;
    }

    modifier canMint() {
        require(mintPaused == false, "Mint Paused");
        require(saleTime !=0 && saleTime <= block.timestamp, "Mint Not Started");
        _;
    }

    function publicMint(uint256 _amount, address _to) public canMint payable {
        require(totalSupply() + _amount <= maxSupply, "All NFTs are minted");
        require(msg.value >= _amount * mintPrice, "Not Enough Money");
        _safeMint(_to, _amount);
        payable(owner()).transfer(msg.value);
    }


     function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory _URI)
        public
        onlyOwner
    {
        _currentBaseURI = _URI;
    }

    function pauseMint(bool _paused) public onlyOwner{
        mintPaused = _paused;
    }

    function setSaleTime(uint256 _time) public onlyOwner{
        saleTime = _time;
    }

    function setMintPrice(uint256 _price) public onlyOwner{
        mintPrice = _price;
    }

    function numberMinted(address _addr) public view returns (uint256) {
        return _numberMinted(_addr);
    }


      function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}