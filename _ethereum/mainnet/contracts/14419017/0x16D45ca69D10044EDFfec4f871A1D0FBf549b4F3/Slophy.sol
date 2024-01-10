// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract Slophy is ERC721Enumerable, Ownable {

    // Import dependencies
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    // Counters
    Counters.Counter private _tokenIds;
    // Uint
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    // Bool
    bool public isPublicMintEnabled = false;
    // String
    string internal baseTokenUri;
    // Address
    address payable public withdrawWallet;
    mapping(address => uint256) public walletMints;

    constructor (
        string memory preRevealbaseURI
    ) payable ERC721('Slophy', 'Slophy'){
        mintPrice = 0.19 ether;
        maxSupply = 5007; // index start from 0
        maxPerWallet = 2;
        baseTokenUri = preRevealbaseURI;
    }

    // Only owner: Call this function to enable the sale or pause
    function setIsPublicMintEnabled(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }
    // Only owner: Set the baseTokenUri -> Used for the revealed
    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }
    // Reserve NFT for the team! :)
    function reserveNFTs(uint256 quantity_) public onlyOwner {
        // Reserve Slophy NFT for the team
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(quantity_) < maxSupply, "Not enough NFTs left to reserve");
        for (uint i = 0; i < quantity_; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, totalMinted);
            totalMinted = totalMinted + 1;
        }
    }
    // Get the mint price
    function getPrice() public view returns (uint256){
        return mintPrice;
    }
    // Get the tokenUri of the NFT
    function tokenURI(uint256 tokenId_) public view override returns (string memory){
        require(_exists(tokenId_), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), '.json'));
    }
    // Mint function!
    function mint(uint256 quantity_) public payable {
        require(isPublicMintEnabled, 'Minting not enabled');
        require(msg.value == quantity_ * mintPrice, 'Wrong mint value');
        require(_tokenIds.current() + quantity_ <= maxSupply, 'Sold out!');
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, 'Exceed max wallet');

        for (uint256 i = 0; i < quantity_; i++){
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }
    // Withdraw all
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, 'No ether left to withdraw');

        (bool success, ) = (msg.sender).call{ value : balance }('');
        require(success, 'withdraw failed');
    }
    //Withdraw certain amount
    function withdrawAmount(uint withdrawAmount_) external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, 'No ether left to withdraw');
        require(balance > withdrawAmount_, 'Amount not available');
        (bool success, ) = (msg.sender).call{ value : withdrawAmount_ }('');
        require(success, 'withdraw failed');
    }
}