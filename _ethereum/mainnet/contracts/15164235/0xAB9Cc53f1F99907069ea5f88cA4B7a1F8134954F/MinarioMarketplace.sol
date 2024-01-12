// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Minario.sol";

contract MinarioMarketplace is Ownable, ReentrancyGuard{
    address public NFTAddress;
    address public platformAddress;
    address public signerAddress;
    address public walletPack;
    uint256 public chainID;

    mapping (address => bool) public statusAdmin;
    mapping (address => mapping (uint256 => uint256)) public priceNFT;
    mapping (address => mapping (uint256 => bool)) public statusNFT;
    mapping (bytes32 => bool) private preventReplayAttack;

    struct Sig{bytes32 r; bytes32 s; uint8 v;}
    struct Buy{address nftAddress; address seller; address buyer; uint256 tokenID; string transactionID;address ipHolderAddr; uint256 percIpHolder; address projOwnAddr; uint256 percProjOwn; uint256 platformFee;}

    event CancelSellEvent(address Caller, address nftAddress, uint256 TokenID, string transactionID, uint256 TimeStamp);
    event ChangePriceEvent(address Caller, address nftAddress, uint256 TokenID, uint256 NewPrice, string transactionID, uint256 TimeStamp);
    event BuyPackEvent(address buyerAddress, uint256 packID, uint256 amountPack, uint256 transferredAmount, string transactionID, uint256 TimeStamp, bytes transferData);
    event SellEvent(address Caller, address nftAddress, uint256 TokenID, uint256 Price, string transactionID, uint256 TimeStamp);
    event BuyEvent(address Caller, address nftAddress, uint256 TokenID, uint256 Price, string transactionID, uint256 TimeStamp);
    event MintEvent(address Caller, string pointerMoment, uint256 TimeStamp);
    event SwapEvent(uint256[] fromTokenID, uint256[] toTokenID, address fromNFTAddress, address toNFTAddress, address callerAddress, address swapWallet, string transactionID);

    bool public Initialized;

    function init(address _NFTAddress, address _signerAddress, address _walletPack, uint256 _chainID) public onlyOwner {
        require(!Initialized, "Contract already initialized!");
        require(_NFTAddress != address(0), "ADDRESS_NFT_INVALID");
        require(_signerAddress != address(0), "ADDRES_SIGNER_INVALID");
        signerAddress = _signerAddress;
        chainID = _chainID;
        NFTAddress = _NFTAddress;
        walletPack = _walletPack;
        Initialized = true;
        statusAdmin[msg.sender] = true;
    }

    function buyPack(address callerAddress, uint256 packID, uint256 amount, uint256 pricePack, string memory transactionID, Sig memory buyPackRSV) external payable initializer {
        bytes32 message = messageHash(abi.encodePacked(callerAddress, packID, amount, pricePack, transactionID, chainID, address(this)));
        require(!preventReplayAttack[message], "Message is already used!");
        require(verifySigner(signerAddress, message, buyPackRSV), "BuyPack rsv invalid");
        require(callerAddress != address(0), "Address Invalid!");
        require(pricePack * amount == msg.value, "Transferred amount is not match with price pack!");
        preventReplayAttack[message] = true;
        (bool sent, bytes memory data) = payable(walletPack).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit BuyPackEvent(callerAddress, packID, amount, msg.value, transactionID, block.timestamp, data);
    }

    function mint(address callerAddress, string memory pointerMoment, Sig memory mintRSV) public initializer{
        bytes32 message = messageHash(abi.encodePacked(msg.sender, pointerMoment, chainID, address(this)));
        require(!preventReplayAttack[message], "Message is already used!");
        require(verifySigner(signerAddress, message, mintRSV), "Mint rsv invalid");
        preventReplayAttack[message] = true;
        Minario(NFTAddress).mint(callerAddress, pointerMoment);
        emit MintEvent(callerAddress, pointerMoment, block.timestamp);
    }

    function sell(address callerAddress, address nftAddress, uint256 tokenID, uint256 price, string memory transactionID, Sig memory sellRSV) public initializer onlyNFTOwner(nftAddress, tokenID){
        require(!statusNFT[nftAddress][tokenID], "NFT Already Listed!");
        bytes32 message = messageHash(abi.encodePacked(msg.sender, nftAddress, tokenID, price, transactionID, chainID, address(this)));
        require(!preventReplayAttack[message], "Message is already used!");
        //TODO: add tokenID into RSV
        require(verifySigner(signerAddress, message, sellRSV), "Sell rsv invalid");
        preventReplayAttack[message] = true;
        statusNFT[nftAddress][tokenID] = true;
        priceNFT[nftAddress][tokenID] = price;
        emit SellEvent(callerAddress, nftAddress, tokenID, price, transactionID, block.timestamp);
    }

    function buy(address callerAddress, Buy memory buyStruct, Sig memory buyRSV) public payable initializer {
        require(statusNFT[buyStruct.nftAddress][buyStruct.tokenID], "NFT is not listed!");
        bytes32 message = messageHash(abi.encodePacked(callerAddress, buyStruct.nftAddress, buyStruct.tokenID, msg.value, buyStruct.transactionID, buyStruct.percIpHolder, buyStruct.ipHolderAddr, buyStruct.percProjOwn, buyStruct.projOwnAddr, chainID, address(this)));
        require(!preventReplayAttack[message], "Message is already used!");
        require(verifySigner(signerAddress, message, buyRSV), "Buy rsv invalid");
        require(priceNFT[buyStruct.nftAddress][buyStruct.tokenID] == msg.value, "MSG_VALUE is not match with listing price!");
        require(ERC721(buyStruct.nftAddress).ownerOf(buyStruct.tokenID) != callerAddress, "You can't buy your own NFT!");
        preventReplayAttack[message] = true;
        statusNFT[buyStruct.nftAddress][buyStruct.tokenID] = false;
        (bool feePlatformSent, ) = payable(platformAddress).call{value: (msg.value * buyStruct.platformFee) / 10000}("");
        require(feePlatformSent, "Failed to send fee!");
        (bool feeIPHolderSent, ) = payable(buyStruct.ipHolderAddr).call{value: (msg.value * buyStruct.percIpHolder) / 10000}("");
        require(feeIPHolderSent, "Failed to send fee!");
        (bool feeProjectOwnerSent, ) = payable(buyStruct.projOwnAddr).call{value: (msg.value * buyStruct.percProjOwn) / 10000}("");
        require(feeProjectOwnerSent, "Failed to send fee!");
        priceNFT[buyStruct.nftAddress][buyStruct.tokenID] = 0;
        (bool sent, ) = payable(buyStruct.seller).call{value: (msg.value * (10000 - (buyStruct.platformFee + buyStruct.percIpHolder + buyStruct.percProjOwn))) / 10000}("");
        require(sent, "Failed to send Ether");
        ERC721(buyStruct.nftAddress).safeTransferFrom(buyStruct.seller, buyStruct.buyer, buyStruct.tokenID);
        emit BuyEvent(buyStruct.buyer, buyStruct.nftAddress, buyStruct.tokenID, msg.value, buyStruct.transactionID, block.timestamp);
    }

    function cancelSell(address callerAddress, address nftAddress, uint256 tokenID, string memory transactionID, Sig memory cancelRSV) public initializer onlyNFTOwner(nftAddress, tokenID) {
        bytes32 message = messageHash(abi.encodePacked(msg.sender, nftAddress, tokenID, transactionID, chainID, address(this)));
        require(!preventReplayAttack[message], "Message is already used!");
        require(verifySigner(signerAddress, message, cancelRSV), "Cancel rsv invalid");
        require(statusNFT[nftAddress][tokenID], "You can't cancel sell NFT that not selled!");
        preventReplayAttack[message] = true;
        priceNFT[nftAddress][tokenID] = 0;
        statusNFT[nftAddress][tokenID] = false;
        emit CancelSellEvent(callerAddress, nftAddress, tokenID, transactionID, block.timestamp);
    }
    
    function changePrice(address callerAddress, address nftAddress, uint256 tokenID, uint256 newPrice, string memory transactionID, Sig memory changePriceRSV) public initializer onlyNFTOwner(nftAddress, tokenID) {
        bytes32 message = messageHash(abi.encodePacked(msg.sender, nftAddress, tokenID, newPrice, transactionID, chainID, address(this)));
        require(!preventReplayAttack[message], "Message is already used!");
        require(verifySigner(signerAddress, message, changePriceRSV), "ChangePrice rsv invalid");
        require(statusNFT[nftAddress][tokenID], "You can't change price NFT that not selled!");
        preventReplayAttack[message] = true;
        priceNFT[nftAddress][tokenID] = newPrice;
        emit ChangePriceEvent(callerAddress, nftAddress, tokenID, newPrice, transactionID, block.timestamp);
    }

    function mintedSwapNFT(uint256[] memory fromTokenID, uint256[] memory toTokenID, address fromNFTAddress, address toNFTAddress, address swapWallet, string memory transactionID, Sig memory swapRSV) external{
        bytes32 message = messageHash(abi.encodePacked(msg.sender, fromNFTAddress, toNFTAddress, swapWallet, transactionID, chainID, address(this)));
        require(!preventReplayAttack[message], "Transaction ID is already used!");
        require(verifySigner(msg.sender, message, swapRSV), "RSV FAIL");
        for (uint256 index = 0; index < fromTokenID.length; index++) {
            require(ERC721(fromNFTAddress).ownerOf(fromTokenID[index]) == msg.sender, "Wallet From is not match!");
        }
        for (uint256 index = 0; index < toTokenID.length; index++) {
            require(ERC721(toNFTAddress).ownerOf(toTokenID[index]) == swapWallet, "Wallet To is not match!");
        }
        preventReplayAttack[message] = true;
        for (uint256 index = 0; index < fromTokenID.length; index++) {
            ERC721(fromNFTAddress).safeTransferFrom(msg.sender, swapWallet, fromTokenID[index]);
        }
        for (uint256 index = 0; index < toTokenID.length; index++) {
            ERC721(toNFTAddress).safeTransferFrom(swapWallet, msg.sender, toTokenID[index]);
        }
        emit SwapEvent(fromTokenID, toTokenID, fromNFTAddress, toNFTAddress, msg.sender, swapWallet, transactionID);
    }

    function addAdmin(address addressAdmin) external onlyOwner initializer{
        checkValidAddress(addressAdmin);
        statusAdmin[addressAdmin] = true;
    }

    function updatePlatform(address newPlatform) external onlyAdmin initializer {
        checkValidAddress(newPlatform);
        platformAddress = newPlatform;
    }

    function updateSigner(address newSigner) external onlyAdmin initializer {
        checkValidAddress(newSigner);
        signerAddress = newSigner;
    }

    //@dev this is for updating dfdunk nft address
    function updateNFTAddress(address nftAddress) external onlyAdmin initializer{
        checkValidAddress(nftAddress);
        NFTAddress = nftAddress;
    }

    function updateWalletPack(address newWalletPack) external onlyAdmin initializer {
        checkValidAddress(newWalletPack);
        walletPack = newWalletPack;
    }

    function revokeAdmin(address addressAdmin) external onlyOwner {
        checkValidAddress(addressAdmin);
        statusAdmin[addressAdmin] = false;
    }

    function checkValidAddress(address checked) private pure {
        require(checked != address(0), "Address invalid");
    }

    function verifySigner(address signer, bytes32 ethSignedMessageHash, Sig memory rsv) internal pure returns (bool)
    {
        return ECDSA.recover(ethSignedMessageHash, rsv.v, rsv.r, rsv.s) == signer;
    }

    function messageHash(bytes memory abiEncode)internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abiEncode)));
    }

    function _initializer() private view {
        require(Initialized, "The contract is not initialized yet!");
    }

    modifier initializer() {
        _initializer();
        _;
    }

    function  _onlyAdmin() private view{
        require(statusAdmin[msg.sender], "The caller is not an admin.");
    }

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    modifier onlyNFTOwner(address nftAddress, uint256 tokenID) {
        require(ERC721(nftAddress).ownerOf(tokenID) == msg.sender, "You're not an owner of this NFT");
        _;
    }
}