// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./IERC2981.sol";
import "./ERC721.sol";

interface IZzoopersInterface {
    function mint(
        uint256 batchNo,
        uint256 zzoopersEVOTokenId,
        address to
    ) external returns (uint256);
}

/**
 * @title ZzoopersEVO contract
 */
contract ZzoopersEVO is ERC721A, IERC2981, Ownable {
    using MerkleProof for *;

    uint256 constant LIMIT_AMOUNT = 5555;
    uint256 constant BATCH_SIZE = 1111;

    bool private _salesStarted = false;
    bool private _publicSalesStarted = false;

    bytes32 private _whiteListMerkleRoot;
    IZzoopersInterface private _zzoopers;

    uint256 private _whiteListSalesPrice = 0.1 ether;
    uint256 private _publicSalesPrice = 0.15 ether;
    uint256 private _publicSalesCount = 0;
    uint256 private _migrateBatch = 0; //From 1 to 5;

    string private _zzoopersEVOBaseURI;
    string private _contractURI;

    address private _mintFeeReceiver;
    address private _royaltyReceiver;
    uint256 private _royaltyRate = 65; //6.5%

    event SetSalesPrice(
        uint256 newWhitelistSalesPrice,
        uint256 newPublicSalesPrice
    );

    event ZzoopersMigrated(
        address indexed owner,
        uint256 zzoopersEVOTokenId,
        uint256 zzoopersTokenId
    );

    constructor(
        bytes32 whiteListMerkleRoot,
        string memory baseURI,
        string memory contactURI
    ) ERC721A("ZzoopersEVO", "ZzoopersEVO") Ownable() {
        _whiteListMerkleRoot = whiteListMerkleRoot;
        _zzoopersEVOBaseURI = baseURI;
        _contractURI = contactURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1; //TokenId start from 1;
    }

    function toggleSalesStarted() public onlyOwner {
        _salesStarted = !_salesStarted;
    }

    function togglePublicSalesStarted() public onlyOwner {
        _publicSalesStarted = !_publicSalesStarted;
    }

    function setSalesPrice(
        uint256 whitelistSalesPrice,
        uint256 publicSalesPrice
    ) public onlyOwner {
        _whiteListSalesPrice = whitelistSalesPrice;
        _publicSalesPrice = publicSalesPrice;
        emit SetSalesPrice(whitelistSalesPrice, publicSalesPrice);
    }

    function getWhiteListSalesPrice() public view returns (uint256) {
        return _whiteListSalesPrice;
    }

    function getPublicSalesPrice() public view returns (uint256) {
        return _publicSalesPrice;
    }

    function getPublicSalesCount() public view returns (uint256) {
        return _publicSalesCount;
    }

    function setZzoopersAddress(address newZzoopersAddress) public onlyOwner {
        _zzoopers = IZzoopersInterface(newZzoopersAddress);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function whiteListMint(bytes32[] calldata merkleProof, uint256 quantity)
        public
        payable
    {
        require(_salesStarted, "ZzoopersEVO: Sales has not started");
        require(
            !isContract(msg.sender),
            "ZzoopersEVO: Cannot mint via contract"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                _whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "ZzoopersEVO: Not in whitelist"
        );
        require(
            _numberMinted(msg.sender) + quantity <= 2,
            "ZzoopersEVO: Can only mint 2 nfts per whitelist address"
        );
        require(
            msg.value >= _whiteListSalesPrice * quantity,
            "ZzoopersEVO: Not enough money"
        );
        require(
            _totalMinted() + quantity <= LIMIT_AMOUNT,
            "ZzoopersEVO: Limit reached"
        );
        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) public payable {
        require(
            _salesStarted && _publicSalesStarted,
            "ZzoopersEVO: Public sales has not started"
        );
        require(
            !isContract(msg.sender),
            "ZzoopersEVO: Cannot mint via contract"
        );
        require(
            msg.value >= _publicSalesPrice * quantity,
            "ZzoopersEVO: Not enough money"
        );
        require(
            _numberMinted(msg.sender) + quantity <= 10,
            "ZzoopersEVO: Can only mint 10 nfts per address"
        );
        require(
            _totalMinted() + quantity <= LIMIT_AMOUNT,
            "ZzoopersEVO: Limit reached"
        );

        _mint(msg.sender, quantity);
        _publicSalesCount += quantity;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function setMigrateBatch(uint256 batchNo) public onlyOwner {
        require(
            batchNo >= 1 && batchNo <= 5,
            "ZzoopersEVO: Batch limit reached"
        );
        require(_migrateBatch + 1 == batchNo, "ZzoopersEVO: Invalid batchNo ");

        _migrateBatch = batchNo;
    }

    function getMigrateBatch() public view returns (uint256) {
        return _migrateBatch;
    }

    //migrateToken migrate ZzoopersEVO NFT to Zzoopers NFT
    function migrateToken(uint256 tokenId) public returns (uint256) {
        require(_migrateBatch > 0, "ZzoopersEVO: migrate has not started");
        require(
            !isContract(msg.sender),
            "ZzoopersEVO: Cannot migrate via contract"
        );
        require(_exists(tokenId), "ZzoopersEVO: tokenId doesn't exist");
        require(
            msg.sender == ownerOf(tokenId),
            "ZzoopersEVO: Only NFT owner can migrate"
        );
        _burn(tokenId);
        uint256 zzoopersTokenId = _zzoopers.mint(
            _migrateBatch,
            tokenId,
            msg.sender
        );
        emit ZzoopersMigrated(msg.sender, tokenId, zzoopersTokenId);
        return zzoopersTokenId;
    }

    function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        _whiteListMerkleRoot = merkleRoot;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _zzoopersEVOBaseURI;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        _zzoopersEVOBaseURI = baseURI;
    }

    function setContractURI(string calldata contractUri) public onlyOwner {
        _contractURI = contractUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setMintFeeReceiver(address newMintFeeReceiver) public onlyOwner {
        _mintFeeReceiver = newMintFeeReceiver;
    }

    function setRoyaltyReceiver(address newRoyaltyReceiver) public onlyOwner {
        _royaltyReceiver = newRoyaltyReceiver;
    }

    function getMintFeeReceiver() public view returns (address) {
        if (_mintFeeReceiver == address(0)) {
            return this.owner();
        }
        return _mintFeeReceiver;
    }

    function getRoyaltyReceiver() public view returns (address) {
        if (_royaltyReceiver == address(0)) {
            return this.owner();
        }
        return _royaltyReceiver;
    }

    function setRoyaltyRate(uint256 newRoyaltyRate) public onlyOwner {
        require(
            newRoyaltyRate >= 0 && newRoyaltyRate <= 1000,
            "ZzoopersEVO: newRoyaltyRate should between [0, 1000]"
        );
        _royaltyRate = newRoyaltyRate;
    }

    function getRoyaltyRate() public view returns (uint256) {
        return _royaltyRate;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = getRoyaltyReceiver();
        royaltyAmount = (salePrice * _royaltyRate) / 1000;
        return (receiver, royaltyAmount);
    }

    function withdrawFunds() public onlyOwner {
        address receiver = getMintFeeReceiver();
        payable(receiver).transfer(address(this).balance);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
