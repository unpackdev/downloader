pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./cosmic-lib.sol";

contract CosmicAddresses is ERC721A, Ownable {
    mapping(uint256 => address) private pData;
    bool public saleStarted;
    uint16 private constant MAX_MINT = 10000;
    uint160 private constant PRICE = 0.01 ether;

    constructor() ERC721A("Cosmic Address", "COSMICADDR"){
        saleStarted = false;
    }

    function mint() external payable{
        require(saleStarted, "Sale not started");
        require(_totalMinted() <= MAX_MINT, "Max mint reached");
        require(_numberMinted(msg.sender) < 1, "1 mint only sadly");
        require(msg.value == PRICE, "Wrong amount paid");

        pData[_nextTokenId()] = msg.sender;
        
        _mint(msg.sender, 1);
    }    

    function hasMinted() external view returns (bool){
        return _numberMinted(msg.sender) > 0;
    }

    function setSaleStarted(bool _saleStarted) external onlyOwner {
        saleStarted = _saleStarted;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory result;

        bytes memory p = abi.encodePacked(pData[tokenId]);

        return CosmicSVGRenderer.render(p);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}