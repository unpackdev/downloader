//SPDX-License-Identifier: Unlicense
// Creator: Pixel8Labs
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./Math.sol";
import "./ERC721A.sol";

contract NiftyCities is ERC721A, PaymentSplitter, Ownable, Pausable, ReentrancyGuard {
    uint private constant MAX_SUPPLY = 2222;
    uint private constant MAX_PER_TX = 20;
    uint256 public price = 0.05 ether;

    // Metadata
    string internal _tokenURI;

    constructor (
        string memory tokenURI_,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721A("Nifty Cities", "NFTCTY", MAX_PER_TX)
    PaymentSplitter(payees, shares) {
        _tokenURI = tokenURI_;
    }

    function mint(uint amount) external payable whenNotPaused nonReentrant {
        uint supply = totalSupply();
        require(amount <= MAX_PER_TX, "amount can't exceed 20");
        require(amount > 0, "amount too little");
        require(msg.value == price * amount, "insufficient fund");
        require(msg.sender != address(0), "empty address");
        require(supply + amount <= MAX_SUPPLY, "exceed max supply");

        _safeMint(msg.sender, amount);
    }

    function airdrop(address to, uint amount) external payable onlyOwner {
        uint supply = totalSupply();
        require(amount <= MAX_PER_TX, "amount can't exceed 20");
        require(amount > 0, "amount too little");
        require(supply + amount <= MAX_SUPPLY, "exceed max supply");

        _safeMint(to, amount);
    }

    function owned(address owner) external view returns (uint256[] memory) {
        uint balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        for(uint i = 0; i < balance; i++){
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    // Pausable
    function setPause(bool pause) external onlyOwner {
        if(pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    // Minting fee
    function setPrice(uint amount) external onlyOwner {
        price = amount;
    }
    function claim() external {
        release(payable(msg.sender));
    }

    // Metadata
    function setTokenURI(string calldata _uri) external onlyOwner {
        _tokenURI = _uri;
    }
    function baseTokenURI() external view returns (string memory) {
        return _tokenURI;
    }
    
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(
            _tokenURI,
            "/",
            Strings.toString(_tokenId),
            ".json"
        ));
    }
}
