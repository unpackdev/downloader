// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract PoSerGirlz is ERC721A, Ownable, ReentrancyGuard {

    enum Status {
        NotLive,
        PublicSale,
        Finished
    }

    uint256 public constant MAX_SUPPLY = 3333;
    Status public status;
    mapping(address => uint256) private _publicNumberMinted;
    string public baseURI = "";
    bool public isRevealed = false;
    uint256 public publicPrice = 0.01 ether;
    uint8 public maxPublicMint = 3;
    uint8 public maxFreeMint = 2;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721A(_tokenName, _tokenSymbol) {
    }

    function mint(uint256 _amount) public payable {
        require(status == Status.PublicSale, "Public sale is not active.");
        require(
            tx.origin == msg.sender,
            "Contract is not allowed to mint."
        );
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded");
        require(
            publicNumberMinted(msg.sender) + _amount <= maxPublicMint,
            "Max mint amount per wallet exceeded."
        );
        if (publicNumberMinted(msg.sender) + _amount > maxFreeMint) {
            require(msg.value >= publicPrice * (publicNumberMinted(msg.sender) + _amount - maxFreeMint), 'Not enough eth');
        }
        _safeMint(msg.sender, _amount);
        _publicNumberMinted[msg.sender] = _publicNumberMinted[msg.sender] + _amount;
        emit Minted(msg.sender, _amount);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function publicNumberMinted(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: number minted query for the zero address"
        );
        return _publicNumberMinted[owner];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!isRevealed) {
            return _baseURI();
        }
        return super.tokenURI(tokenId);
    }

    function setPublicPrice(uint256 _newPublicPrice) external onlyOwner {
        publicPrice = _newPublicPrice;
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setMaxPublicMint(uint8 _amount) external onlyOwner {
        maxPublicMint = _amount;
    }

    function setMaxFreeMint(uint8 _amount) external onlyOwner {
        maxFreeMint = _amount;
    }

    function withdrawBalance() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "WITHDRAW FAILED!");
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        emit BaseURIChanged(_newBaseURI);
    }

    function reveal(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        isRevealed = true;
    }

    function flipReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    receive() external payable {

    }

}
