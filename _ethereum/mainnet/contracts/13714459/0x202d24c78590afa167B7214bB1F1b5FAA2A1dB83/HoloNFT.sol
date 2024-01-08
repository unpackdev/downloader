// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// By NightRabbit and nut4214

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract HoloNFT is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {

    uint16 constant private MAXIMUM_CREATOR_FEE = 3000;
    uint16 constant private MINIMUM_CREATOR_FEE = 0;
    uint16 constant private MAXIMUM_PUBLISHER_FEE = 9000;
    uint16 constant private MINIMUM_PUBLISHER_FEE = 0;

    mapping(uint256 => Token) private tokens; 
    mapping(address => bool) private operators;
    address private feeCollectorAddress;
    string private baseURI;

    struct Token {
        uint16 tokenPublisherFee;
        uint16 tokenCreatorFee; 
        bool tokenAllowSignature;
        address payable tokenCreatorAddress;
        string tokenBackupURI;
        bytes tokenSignature;
    }

    modifier onlyPartnerMarketAndOwner() {
        require(
            (operators[_msgSender()] || (owner() == _msgSender())),
            "HoloNFT: Sender is not a partner market nor an owner"
        );
        _;
    }

    constructor() ERC721("HoloNFT", "HoloNFT") {
        feeCollectorAddress = _msgSender();
    }

    // ************************************************
    // For partner market and contract's owner only
    // ************************************************

    function mintTo(
        address payable to,
        uint256 tokenId,
        address payable creator,
        uint16 creatorFee,
        bool allowSignature,
        bytes32 creatorSignature,
        uint16 publisherFee
    ) public onlyPartnerMarketAndOwner nonReentrant {
        mintToLogic(to, tokenId, creator, creatorFee, allowSignature, creatorSignature, publisherFee);
    }

    function lazyMintTo(
        address payable to,
        uint256 tokenId,
        address payable creator,
        uint16 creatorFee,
        bool allowSignature,
        bytes32 creatorSignature,
        bytes32 buyerSignature,
        uint16 publisherFee
    ) public onlyPartnerMarketAndOwner nonReentrant {

        mintToLogic(to, tokenId, creator, creatorFee, allowSignature, creatorSignature, publisherFee);
        if (allowSignature == true){
            tokens[tokenId].tokenSignature = abi.encodePacked(tokens[tokenId].tokenSignature, to, buyerSignature);
        }
    }
    
    function mintToLogic(
        address payable to,
        uint256 tokenId,
        address payable creator,
        uint16 creatorFee,
        bool allowSignature,
        bytes32 creatorSignature,
        uint16 publisherFee
    ) private onlyPartnerMarketAndOwner {

        require(creator != address(0), "HoloNFT: Creator is NULL");
        require(creatorFee >= MINIMUM_CREATOR_FEE && creatorFee <= MAXIMUM_CREATOR_FEE, "HoloNFT: Creator fee out of range");
        require(publisherFee >= MINIMUM_PUBLISHER_FEE && publisherFee <= MAXIMUM_PUBLISHER_FEE, "HoloNFT: Publisher fee out of range");

        tokens[tokenId].tokenCreatorFee = creatorFee;
        tokens[tokenId].tokenCreatorAddress = creator;
        tokens[tokenId].tokenAllowSignature = allowSignature;
        tokens[tokenId].tokenPublisherFee = publisherFee;

        if (creatorSignature != 0) {
            tokens[tokenId].tokenSignature = abi.encodePacked(creator, creatorSignature);
        }

        super._mint(to, tokenId);
    }

    function safeTransferFromWithSignature(
        address from,
        address to,
        uint256 tokenId,
        bytes32 signature
    ) public onlyPartnerMarketAndOwner nonReentrant {

        require(tokens[tokenId].tokenAllowSignature, "HoloNFT: Token's creator does not allow signature");

        safeTransferFrom(from, to, tokenId);

        if ((signature != 0) && (tokens[tokenId].tokenAllowSignature == true)) {
            tokens[tokenId].tokenSignature = abi.encodePacked(tokens[tokenId].tokenSignature, to, signature);
        }
    }

    // ************************************************
    // For token owner only
    // ************************************************

    function setBackupURIs(uint256 tokenId, string memory newBackupURI) public nonReentrant{

        require(ERC721.ownerOf(tokenId) == _msgSender(), "HoloNFT: Sender is not the token's owner");
        require(_exists(tokenId), "HoloNFT: TokenID does not exist");

        tokens[tokenId].tokenBackupURI = newBackupURI;
    }

    // ************************************************
    // For contract's owner only
    // ************************************************

    function setOperator(address account, bool approve) external onlyOwner {
        operators[account] = approve;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function burn(uint256 tokenId) external onlyOwner {
        super._burn(tokenId);
    }

    function setPublisherFee(uint256 tokenId, uint16 newFee) external onlyOwner {
        require(_exists(tokenId), "HoloNFT: TokenID does not exist");
        require(newFee >= MINIMUM_PUBLISHER_FEE && newFee <= MAXIMUM_PUBLISHER_FEE, "HoloNFT: Publisher fee out of range");
        tokens[tokenId].tokenPublisherFee = newFee;
    }

    function setPublisherFeeCollector(address payable account) external onlyOwner {
        require(account != address(0), "HoloNFT: Publisher fee collector can not be NULL");
        feeCollectorAddress = account;
    }

    // ************************************************
    // Public functions
    // ************************************************

    function getTokenDetail(uint256 tokenId)
        external
        view
        returns (
            bool,
            bytes memory,
            address,
            address,
            uint16
        )
    {
        bool allowSignature = tokens[tokenId].tokenAllowSignature;
        bytes memory signature = tokens[tokenId].tokenSignature;
        address owner = super.ownerOf(tokenId); 
        address creator = tokens[tokenId].tokenCreatorAddress; 
        uint16 creatorFee = tokens[tokenId].tokenCreatorFee; 

        return (allowSignature, signature, owner, creator, creatorFee);
    }

    function isAllowSignature(uint256 tokenId) public view returns (bool) {
        return tokens[tokenId].tokenAllowSignature;
    }

    function getTokenSignature(uint256 tokenId) public view returns (bytes memory) {
        return tokens[tokenId].tokenSignature;
    }

    function getBackupURI(uint256 tokenId) public view returns (string memory) {
        return tokens[tokenId].tokenBackupURI;
    }

    function getCreatorAddress(uint256 tokenId) public view returns (address payable) {
        return tokens[tokenId].tokenCreatorAddress;
    }

    function getCreatorFee(uint256 tokenId) public view returns (uint16) {
        return tokens[tokenId].tokenCreatorFee;
    }

    function getPublisherFeeCollectorAddress() public view returns (address) {
        return feeCollectorAddress;
    }

    function getPublisherFee(uint256 tokenId) public view returns (uint16) {
        return tokens[tokenId].tokenPublisherFee;
    }

    function isTokenExist(uint256 tokenId) public view returns (bool) {
        return super._exists(tokenId);
    }

    function isOperator(address account) public view returns (bool) {
        return operators[account];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        super._pause();
    }

    function unpause() public onlyOwner {
        super._unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

}
