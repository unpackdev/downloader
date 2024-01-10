// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

contract MetaPunksGoldenFriends is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    string private _uri; 
    uint256 public isActive;
    uint256 public MAX_MINT;
    uint256 public immutable MAX_NFT;
    uint256 public unitPrice;

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory initURI
    ) ERC721A(_name, _symbol, 10000) {
        _uri = initURI;
        isActive = 0;
        MAX_MINT = 3;
        MAX_NFT = 10001;
        unitPrice = 0;
    }

    function _baseURI() internal view  override(ERC721A) returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) public virtual onlyOwner{
        _uri = newuri;
    }

    function setIsActive(uint256 _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setUnitPrice(
        uint256 _unitPrice
    ) external onlyOwner {
        unitPrice = _unitPrice;
    }    

    function setMaxMint(uint256 _max_mint) external onlyOwner {
        MAX_MINT = _max_mint;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function mint(uint256 _quantity, address _to) public payable {
        require(isActive == 9, 'MSG09');
        require(totalSupply().add(_quantity) <= MAX_NFT, "MSG10001");
        require(numberMinted(_to).add(_quantity) <= MAX_MINT, 'MSG20');
        require(msg.value >= unitPrice.mul(_quantity), "MSG666");

        _safeMint(_to, _quantity);
    }

    function release() public virtual nonReentrant onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "MSG000");
        payable(msg.sender).transfer(amount);
    }
}