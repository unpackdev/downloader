// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enum.sol";

contract Dice is ERC721Enum, Ownable, Pausable,  ReentrancyGuard {

    using Strings for uint256;
    string public baseURI;
    uint256 public cost = 0.044 ether;
    uint256 public maxSupply = 8888;
    uint256 public maxMint = 10;
    bool public status = false;

    constructor() ERC721S("Doodlemice", "DICE") {
        setBaseURI("");
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount) public payable nonReentrant{
        uint256 s = totalSupply();
        require(status, "Contract Not Enabled" );
        require(_mintAmount > 0, "Cant mint 0" );
        require(_mintAmount <= maxMint, "Cant mint more then maxmint" );
        require(s + _mintAmount <= maxSupply, "Cant go over supply" );
        require(msg.value >= cost * _mintAmount);
        for (uint256 i = 0; i < _mintAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
        require(quantity.length == recipient.length, "Provide quantities and recipients" );
        uint totalQuantity = 0;
        uint256 s = totalSupply();
        for(uint i = 0; i < quantity.length; ++i){
            totalQuantity += quantity[i];
        }
        require( s + totalQuantity <= maxSupply, "Too many" );
        delete totalQuantity;
        for(uint i = 0; i < recipient.length; ++i){
            for(uint j = 0; j < quantity[i]; ++j){
            _safeMint( recipient[i], s++, "" );
            }
        }
        delete s;   
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMint = _newMaxMintAmount;
    }
    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setSaleStatus(bool _status) public onlyOwner {
        status = _status;
    }
    function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
    }
}