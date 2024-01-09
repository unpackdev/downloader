// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./IERC721.sol";

contract LLKO1155 is ERC1155, Ownable {

    event Mint(address owner, uint qty);

    bool public mintOpen = false;
    uint public nonce = 6;
    IERC721 public LLKO;

    mapping(address => mapping(uint => bool)) private claimed;
    mapping(uint => uint) public assetNonce;
    uint public maxSupply = 60;

    modifier notClaimed(uint idx){
        require(!claimed[msg.sender][idx],"You cannot claim this again");
        _;
    }

    modifier llkoHolder(){
        require(LLKO.balanceOf(msg.sender) > 0, "you must have at least one LLKO NFT");
        _;
    }

    modifier isAsset(uint idx){
        require(idx > 0 && idx <= nonce, "asset not found");
        _;
    }

    modifier stock(uint idx){
        require(assetNonce[idx] < maxSupply, "asset sold out");
        _;
    }

    modifier opened(){
        require(mintOpen, "mint is closed");
        _;
    }

    string public name = "LLKO1155";
    string public symbol = "LLC";
    
    constructor() ERC1155("https://llko1155.herokuapp.com/") {
    }

    function setUri(string calldata newUri) external onlyOwner {
        _setURI(newUri);
    }

    function setNonce(uint newNonce) external onlyOwner {
        require(newNonce > nonce, "new nonce must be greater than actual nonce");
        nonce = newNonce;
    }

    function setLLKOAddress(address newAddress) external onlyOwner {
        LLKO = IERC721(newAddress);
    }

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function claim(uint asset) external opened llkoHolder notClaimed(asset) isAsset(asset) stock(asset) {
        claimed[msg.sender][asset] = true;
        assetNonce[asset]++;
        _mint(msg.sender, asset, 1, "");
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "no balance");
        payable(_msgSender()).transfer(address(this).balance);
    }
}