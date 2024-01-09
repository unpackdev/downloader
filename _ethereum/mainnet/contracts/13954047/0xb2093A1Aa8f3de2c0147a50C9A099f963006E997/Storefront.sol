// SPDX-License-Identifier: MIT
/// @title: No Pork on My Fork NFT Storefront
/// @author: DropHero LLC
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";

interface IMintableToken {
    function mintTokens(uint16 numberOfTokens, address to) external;
}

contract NoPorkStorefront is Pausable, Ownable, PaymentSplitter {
    uint256 _mintPrice = 0.04 ether;
    uint64 _saleStart;
    uint64 _presaleStart;
    uint16 _maxPurchaseCount = 10;
    uint16 _maxPresaleCount = 4;
    string _baseURIValue;
    bytes32 _merkleRoot;

    mapping(address => uint16) _presaleMints;

    IMintableToken token;

    constructor(
        uint64 saleStart_,
        address[] memory payees,
        uint256[] memory paymentShares,
        address tokenAddress,
        bytes32 merkleRoot_
    ) PaymentSplitter(payees, paymentShares) {
        _saleStart = saleStart_;
        _presaleStart = _saleStart - 4 * 60 * 60;
        token = IMintableToken(tokenAddress);
        _merkleRoot = merkleRoot_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setSaleStart(uint64 timestamp) external onlyOwner {
        _saleStart = timestamp;
    }

    function setPresaleStart(uint64 timestamp) external onlyOwner {
        _presaleStart = timestamp;
    }

    function saleStart() public view returns (uint64) {
        return _saleStart;
    }

    function presaleStart() public view returns (uint64) {
        return _presaleStart;
    }

    function saleHasStarted() public view returns (bool) {
        return _saleStart <= block.timestamp;
    }

    function presaleHasStarted() public view returns (bool) {
        return _presaleStart <= block.timestamp;
    }

    function presaleMints(address addr) external view returns(uint16) {
        return _presaleMints[addr];
    }

    function maxPurchaseCount() public view returns (uint16) {
        return _maxPurchaseCount;
    }

    function maxPresaleCount() public view returns (uint16) {
        return _maxPresaleCount;
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

    function merkleRoot() public view returns (bytes32) {
        return _merkleRoot;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    function mintTokens(uint16 numberOfTokens)
        external
        payable
        whenNotPaused
    {
        require(
            numberOfTokens <= _maxPurchaseCount,
            "MAX_PER_TX_EXCEEDED"
        );
        require(
            mintPrice(numberOfTokens) == msg.value,
            "VALUE_INCORRECT"
        );
        require(
            _msgSender()== tx.origin,
            "NOT_CALLED_FROM_EOA"
        );
        require(saleHasStarted(), "SALE_NOT_STARTED");

        token.mintTokens(numberOfTokens, _msgSender());
    }

    function mintPresale(uint16 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
        whenNotPaused
    {
        require(
            _presaleMints[_msgSender()] + numberOfTokens <= _maxPresaleCount,
            "MAX_PRESALE_PURCHASE_EXCEEDED"
        );
        require(
            mintPrice(numberOfTokens) == msg.value,
            "VALUE_INCORRECT"
        );
        require(presaleHasStarted(), "PRESALE_NOT_STARTED");

        require(
            MerkleProof.verify(merkleProof, _merkleRoot, keccak256(abi.encodePacked(_msgSender()))),
            "INVALID_MERKLE_PROOF"
        );

        token.mintTokens(numberOfTokens, _msgSender());
        _presaleMints[_msgSender()] += numberOfTokens;
    }
}
