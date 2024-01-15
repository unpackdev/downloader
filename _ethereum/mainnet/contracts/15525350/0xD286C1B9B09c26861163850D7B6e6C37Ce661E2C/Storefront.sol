// SPDX-License-Identifier: MIT
/// @title: Ric Rac Equestrian Club Storefront
/// @author: DropHero LLC
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";

interface IMintableToken {
    function mintTokens(uint16 numberOfTokens, address to) external;
    function totalSupply() external returns (uint256);
}

error MaxTokensPerTransactionExceeded(uint256 requested, uint256 maximum);
error InsufficientPayment(uint256 sent, uint256 required);
error MustMintFromEOA();
error SaleNotStarted();
error PresaleNotStarted();
error InvalidMerkleProof();

contract RicRacStorefront is Pausable, Ownable, PaymentSplitter {
    uint256 _mintPrice = 0.069 ether;
    uint64 _saleStart;
    uint16 _maxPurchaseCount = 20;
    string _baseURIValue;
    bytes32 _merkleRoot;

    IMintableToken token;

    constructor(
        uint64 saleStart_,
        address tokenAddress,
        bytes32 merkleRoot,
        address[] memory payees,
        uint256[] memory paymentShares
    ) PaymentSplitter(payees, paymentShares) {
        _saleStart = saleStart_;
        _merkleRoot = merkleRoot;
        token = IMintableToken(tokenAddress);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setTokenAddress(address tokenAddress) external onlyOwner {
        token = IMintableToken(tokenAddress);
    }

    function setSaleStart(uint64 timestamp) external onlyOwner {
        _saleStart = timestamp;
    }

    function saleStart() public view returns (uint64) {
        return _saleStart;
    }

    function presaleStart() public view returns (uint64) {
        return _saleStart - 2 * 60 * 60;
    }

    function saleHasStarted() public view returns (bool) {
        return _saleStart <= block.timestamp;
    }

    function presaleHasStarted() public view returns (bool) {
        return presaleStart() <= block.timestamp;
    }

    function maxPurchaseCount() public view returns (uint16) {
        return _maxPurchaseCount;
    }

    function setMaxPurchaseCount(uint16 count) external onlyOwner {
        _maxPurchaseCount = count;
    }

    function baseMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setBaseMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return _mintPrice * numberOfTokens;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    modifier whenValidTokenCount(uint8 numberOfTokens) {
        if (numberOfTokens > _maxPurchaseCount) {
            revert MaxTokensPerTransactionExceeded({
                requested: numberOfTokens,
                maximum: _maxPurchaseCount
            });
        }

        _;
    }

    modifier whenSufficientValue(uint8 numberOfTokens) {
        if (msg.value < mintPrice(numberOfTokens)) {
            revert InsufficientPayment({
                sent: msg.value,
                required: mintPrice(numberOfTokens)
            });
        }

        _;
    }

    function mintTokens(uint8 numberOfTokens)
        external
        payable
        whenNotPaused
        whenValidTokenCount(numberOfTokens)
        whenSufficientValue(numberOfTokens)
    {

        if (_msgSender() != tx.origin) {
            revert MustMintFromEOA();
        }

        if (!saleHasStarted()) {
            revert SaleNotStarted();
        }

        token.mintTokens(numberToMint(numberOfTokens), _msgSender());
    }

    function mintPresale(uint8 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
        whenNotPaused
        whenValidTokenCount(numberOfTokens)
        whenSufficientValue(numberOfTokens)
    {
        if (!presaleHasStarted()) {
            revert PresaleNotStarted();
        }

        if (!MerkleProof.verify(merkleProof, _merkleRoot, keccak256(abi.encodePacked(_msgSender())))) {
            revert InvalidMerkleProof();
        }

        token.mintTokens(numberToMint(numberOfTokens), _msgSender());
    }

    function numberToMint(uint8 numberRequested) public pure returns (uint8) {
        return numberRequested + (numberRequested / 5);
    }
}
