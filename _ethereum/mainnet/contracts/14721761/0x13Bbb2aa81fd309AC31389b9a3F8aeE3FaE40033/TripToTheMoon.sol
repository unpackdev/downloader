// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

/**
 *                    Trip To The Moon - NFT Collection 
 *                          Music Collectibles
 *          --------------                      -----------------
 *          |   ARTIST   |                      |   DEVELOPER   |
 *          --------------                      -----------------
 *           Akashi30.eth                           CryptoNik
 *     CryptoWeeb30 apedilla.com           linktr.ee/cryptoCodingMusic
 *        Music,Promotion,Etc!                       Coding!
 */

contract TripToTheMoonTokenContract is ERC721, Ownable {
    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    bool public isPublicMintEnabled;
    bool locked = false;
    string internal baseTokenUri;
    address payable public withdrawWallet;
    mapping(address => uint256) public walletMints;

    constructor(address  withdrawalAddress_, string memory contractURI_) payable ERC721('TripToTheMoon', 'TTTM') {
        mintPrice = 0.02 ether;
        totalSupply = 0;
        maxSupply = 10000;
        maxPerWallet = 25;
        baseTokenUri = contractURI_;
        withdrawWallet = payable(withdrawalAddress_);
        isPublicMintEnabled = true; 
    }

    // TokenUri

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), 'Token does not exist! (Hint ID starts @ 1 & ends @ tokensMinted/totalSupply)');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_)));
    }

    function viewBaseTokenUri() external view returns (string memory) {
        return baseTokenUri;
    }

    // Withdrawal 

    function getBalanceContractInGwei() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawToWithdrawWallet() external onlyOwner {
        require(!locked, "Reentrant call detected!");
        locked = true;
        (bool success, ) = withdrawWallet.call{ value: address(this).balance }('');
        locked = false;
        require(success, 'withdraw failed');
    }

    function withdrawUnlocked() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }('');
        require(success, 'withdraw failed');
    }

    function withdrawAmount(uint256 amount) external onlyOwner  {
        require(amount <= address(this).balance);
        require(!locked, "Reentrant call detected!");
        locked = true;
        (bool success, ) = msg.sender.call{ value: amount }('');
        locked = false;
        require(success, 'withdraw failed');
    }

    function withdrawAll() external onlyOwner  {
        require(!locked, "Reentrant call detected!");
        locked = true;
        (bool success, ) = msg.sender.call{ value: address(this).balance }('');
        locked = false;
        require(success, 'withdraw failed');
    }

    // Minting

    function setIsPublicMintEnabled(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function tokensMinted() external view returns (uint256) {
        return totalSupply;
    }

    function mintingPrice() external view returns (uint256) {
        return mintPrice;
    }

    function updateMintingPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function updateMaxPublicMintingSupply(uint256 newSupply)
        external
        onlyOwner
    {
        maxSupply = newSupply;
    }

    function mint(uint256 quantity_) public payable {
        require(isPublicMintEnabled, 'minting not enabled');
        require(msg.value == quantity_ * mintPrice, 'wrong mint value');
        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, 'exceed max per wallet');

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }
}
