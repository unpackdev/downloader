// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./HDY721.sol";

contract Marketplace is Ownable, ReentrancyGuard{
    uint256 public royaltyFee;
    address public platformAddress;
    address public NFTAddress;

    //the denominator is used to calculate so the result will not return 0 if we
    //want to calculate the value that have a point(.) ex: 2.5 * 2
    uint256 denominator = 10000;

    mapping (address => bool) public statusAdmin;
    mapping (uint256 => bool) public statusNFT;

    struct Sig{bytes32 r; bytes32 s; uint8 v;}

    event SellEvent(address Caller, uint256 TokenID, uint256 Price, string transactionID, uint256 TimeStamp);
    event BuyEvent(address Caller, uint256 TokenID, uint256 Price, string transactionID, uint256 TimeStamp, bytes transferData);
    event CancelSellEvent(address Caller, uint256 TokenID, string transactionID, uint256 TimeStamp);
    event LowingPriceEvent(address Caller, uint256 TokenID, uint256 NewPrice, string transactionID, uint256 TimeStamp);
    event BuyPackEvent(address buyerAddress, uint256 packID, uint256 amountPack, uint256 transferredAmount, string transactionID, uint256 TimeStamp, bytes transferData);

    bool public Initialized;

    function init(address _platformAddress, address _NFTAddress) public onlyOwner {
        require(!Initialized, "Contract already initialized!");
        platformAddress = _platformAddress;
        NFTAddress = _NFTAddress;
        Initialized = true;
        statusAdmin[_platformAddress] = true;
        statusAdmin[msg.sender] = true;
        setRoyaltyFee(250);
    }

    function buyPack(uint256 packID, uint256 amount, uint256 pricePack, string memory transactionID, Sig memory buyPackRSV) external payable initializer {
        require(verifySigner(platformAddress, messageHash(abi.encodePacked(msg.sender, packID, amount, pricePack, transactionID)), buyPackRSV), "BuyPack rsv invalid");
        require(msg.sender != address(0), "Address Invalid!");
        require(pricePack == msg.value, "Transferred amount is not match with price pack!");
        (bool sent, bytes memory data) = payable(platformAddress).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit BuyPackEvent(msg.sender, packID, amount, msg.value, transactionID, block.timestamp, data);
    }

    function sell(uint256 tokenID, uint256 price, string memory transactionID, Sig memory sellRSV) public initializer onlyNFTOwner(tokenID) {
        require(statusNFT[tokenID] != true, "NFT Already selled!");
        require(verifySigner(platformAddress, messageHash(abi.encodePacked(msg.sender, tokenID, price, transactionID)), sellRSV), "Sell rsv invalid");
        statusNFT[tokenID] = true;
        HDY721(NFTAddress).setPriceNFT(msg.sender, tokenID, price);
        emit SellEvent(msg.sender, tokenID, price, transactionID, block.timestamp);
    }

    function sellWithMint(uint256 tokenID, string memory collectionName, string memory tokenURI, uint256 price, string memory transactionID, HDY721.Sig memory MintRSV, Sig memory sellRSV) public initializer{
        require(verifySigner(platformAddress, messageHash(abi.encodePacked(msg.sender, tokenID, price, transactionID)), sellRSV), "Sell rsv invalid");
        HDY721(NFTAddress).mint(msg.sender, tokenID, collectionName, tokenURI, MintRSV);
        statusNFT[tokenID] = true;
        HDY721(NFTAddress).setPriceNFT(msg.sender, tokenID, price);
        emit SellEvent(msg.sender, tokenID, price, transactionID, block.timestamp);
    }

    function buy(address seller, uint256 tokenID,uint256 price, string memory transactionID, Sig memory buyRSV) public payable initializer {
        require(statusNFT[tokenID], "NFT is not listed!");
        require(verifySigner(platformAddress, messageHash(abi.encodePacked(msg.sender, tokenID, price, transactionID)), buyRSV), "Buy rsv invalid");
        require(HDY721(NFTAddress).getPriceNFT(tokenID) == price, "The amount is not match with listing price!");
        require(msg.value == price, "msg.value is not matched with price!");
        require(HDY721(NFTAddress).ownerOf(tokenID) != msg.sender, "You can't buy your own NFT!");
        statusNFT[tokenID] = false;
        uint256 fee = (msg.value * royaltyFee) / denominator;
        (bool sent, bytes memory data) = payable(seller).call{value: msg.value - fee}("");
        require(sent, "Failed to send Ether");
        (bool feeSent, bytes memory feeData) = payable(platformAddress).call{value: fee}("");
        require(feeSent, "Failed to send fee!");
        HDY721(NFTAddress).safeTransferFrom(seller, msg.sender, tokenID);
        emit BuyEvent(msg.sender, tokenID, price, transactionID, block.timestamp, data);
    }

    function cancelSell(uint256 tokenID, string memory transactionID, Sig memory cancelRSV) public initializer onlyNFTOwner(tokenID) {
        require(verifySigner(platformAddress, messageHash(abi.encodePacked(msg.sender, tokenID)), cancelRSV), "Cancel rsv invalid");
        require(statusNFT[tokenID], "You can't cancel sell NFT that not selled!");
        statusNFT[tokenID] = false;
        emit CancelSellEvent(msg.sender, tokenID, transactionID, block.timestamp);
    }
    
    function lowingPrice(uint256 tokenID, uint256 newPrice, string memory transactionID, Sig memory lowingPriceRSV) public initializer onlyNFTOwner(tokenID) {
        require(verifySigner(platformAddress, messageHash(abi.encodePacked(msg.sender, tokenID, newPrice)), lowingPriceRSV), "LowingPrice rsv invalid");
        require(newPrice < HDY721(NFTAddress).getPriceNFT(tokenID), "Your submitted new price is higher than initialized price.");
        HDY721(NFTAddress).setPriceNFT(msg.sender, tokenID, newPrice);
        emit LowingPriceEvent(msg.sender, tokenID, newPrice, transactionID, block.timestamp);
    }

    function addAdmin(address addressAdmin) external onlyOwner initializer{
        require(addressAdmin != address(0), "Address invalid");
        statusAdmin[addressAdmin] = true;
    }

    function updatePlatform(address newPlatform) external onlyAdmin initializer {
        require(newPlatform != address(0), "Address invalid");
        platformAddress = newPlatform;
    }

    function updateNFTAddress(address nftAddress) external onlyAdmin initializer{
        require(nftAddress != address(0), "Address invalid");
        NFTAddress = nftAddress;
    }

    function revokeAdmin(address addressAdmin) external onlyOwner {
        require(addressAdmin != address(0), "Address invalid");
        statusAdmin[addressAdmin] = false;
    }

    function setRoyaltyFee(uint256 newFee) public onlyAdmin initializer{
        require((newFee >= 100) && (newFee <= 10000) , "The Denominator is 10000");
        royaltyFee = newFee;
    }

    function getRoyaltyFee() public view returns (uint256){
        return royaltyFee;
    }

    function verifySigner(address signer, bytes32 ethSignedMessageHash, Sig memory rsv) internal pure returns (bool)
    {
        return ECDSA.recover(ethSignedMessageHash, rsv.v, rsv.r, rsv.s) == signer;
    }

    function messageHash(bytes memory abiEncode)internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abiEncode)));
    }

    modifier initializer() {
        require(Initialized, "The contract is not initialized yet!");
        _;
    }

    modifier onlyAdmin() {
        require(statusAdmin[msg.sender], "The caller is not an admin.");
        _;
    }

    modifier onlyNFTOwner(uint256 tokenID) {
        require(HDY721(NFTAddress).ownerOf(tokenID) == msg.sender, "You're not an owner of this NFT");
        _;
    }
}