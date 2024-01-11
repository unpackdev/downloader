// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract MimicShhansAi is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MAX_MINT = 5;
    uint256 public FREE_MINT_SUPPLY = 3000;
    uint256 public COST = 0.005 ether;
    mapping( address => uint256 ) public addressMintedBalance;
    
    string private _baseTokenURI = "";
    string private _baseTokenHiddenURI = "ipfs://QmdtzvGN38CdfiVva8BA5Qh4EdDKoqBLQCk8mZYcTeE5jj/hidden.json";
    bool public isReady = true;
    bool public isRevealed = false;

    constructor () ERC721A("MimicShhansAi", "MSAI") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contracts cannot call");
        _;
    }

    function mint(uint256 _quantity) external payable nonReentrant callerIsUser{
        uint256 supply = totalSupply();
        require(isReady, "Sale is passive");
        require(_quantity > 0, "Cannot mint none");
        require((supply + _quantity) <= MAX_SUPPLY, "No enough NFTs left");
        require((addressMintedBalance[msg.sender] +_quantity) <= MAX_MINT, "Cannot mint more than 5");

        if(supply <= FREE_MINT_SUPPLY) {
            uint256 avaNum = FREE_MINT_SUPPLY - supply; 

            if(_quantity >= avaNum) { 
                require(msg.value >= COST * (_quantity-avaNum), "Insufficient Funds");
            }

        } else {
            require(msg.value >= COST * _quantity, "Insufficient Funds");
        }

        addressMintedBalance[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setFreeSupply(uint256 _supply) external onlyOwner {
        FREE_MINT_SUPPLY = _supply;
    }
    function setCost(uint256 _cost) external onlyOwner {
        COST = _cost;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        _baseTokenURI = _URI;
    }
    function setNotRevealedURI(string memory _URI) external onlyOwner {
        _baseTokenHiddenURI = _URI;
    }

    function setReady(bool _state) external onlyOwner {
        isReady = _state;
    }

    function setRevealed(bool _state) external onlyOwner {
        isRevealed = _state;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require( _exists(_tokenId),"no token");

        if (isRevealed == false) {
            return _baseTokenHiddenURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : "";
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool ok, ) = payable(owner()).call{value: address(this).balance}("");
        require(ok);
    }
}