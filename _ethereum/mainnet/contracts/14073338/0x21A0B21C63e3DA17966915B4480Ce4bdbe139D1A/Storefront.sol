// SPDX-License-Identifier: MIT
/// @title: Homies In Dreamland NFT Storefront
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

contract HomiesStorefront is Pausable, Ownable, PaymentSplitter {
    struct PresaleWave {
        uint8 mintLimit;
        bytes32 merkleRoot;
    }

    uint256 _mintPrice = 0.1420 ether;
    uint64 _saleStart;
    uint16 _maxPurchaseCount = 5;
    string _baseURIValue;
    PresaleWave[] _presaleWaves;

    mapping(address => uint8) _presalePurchases;

    IMintableToken token;

    constructor(
        uint64 saleStart_,
        address[] memory payees,
        uint256[] memory paymentShares,
        address tokenAddress,
        bytes32 wave0root,
        bytes32 wave1root,
        bytes32 wave2root
    ) PaymentSplitter(payees, paymentShares) {
        _saleStart = saleStart_;
        token = IMintableToken(tokenAddress);

        _presaleWaves.push(PresaleWave({
            merkleRoot: wave0root,
            mintLimit: 4
        }));
        _presaleWaves.push(PresaleWave({
            merkleRoot: wave1root,
            mintLimit: 3
        }));
        _presaleWaves.push(PresaleWave({
            merkleRoot: wave2root,
            mintLimit: 2
        }));
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

    function saleStart() public view returns (uint64) {
        return _saleStart;
    }

    function presaleStart() public view returns (uint64) {
        return _saleStart - 6 * 60 * 60;
    }

    function saleHasStarted() public view returns (bool) {
        return _saleStart <= block.timestamp;
    }

    function presaleHasStarted() public view returns (bool) {
        return presaleStart() <= block.timestamp;
    }

    function currentPresaleWave() public view returns (uint8) {
        if (block.timestamp > _saleStart - 2 * 60 * 60) {
            return 2;
        }

        if (block.timestamp > _saleStart - 4 * 60 * 60) {
            return 1;
        }

        return 0;
    }

    function maxPresaleMints(uint8 waveIndex) public view returns (uint8) {
        uint8 currentWave = currentPresaleWave();
        uint8 total = 0;

        if (waveIndex > currentWave) {
            return total;
        }

        for(uint8 i = waveIndex; i <= currentWave; i++) {
            total += _presaleWaves[i].mintLimit;
        }

        return total;
    }

    function presalePurchases(address addr) external view returns(uint8) {
        return _presalePurchases[addr];
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

    function presaleWaves() public view returns (PresaleWave[] memory) {
        return _presaleWaves;
    }

    function updatePresaleWave(uint256 waveIndex, uint8 mintLimit, bytes32 merkleRoot)
        external
        onlyOwner
    {
        _presaleWaves[waveIndex] = PresaleWave({
            mintLimit: mintLimit,
            merkleRoot: merkleRoot
        });
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
            _msgSender() == tx.origin,
            "NOT_CALLED_FROM_EOA"
        );
        require(saleHasStarted(), "SALE_NOT_STARTED");

        token.mintTokens(numberOfTokens, _msgSender());
    }

    function mintPresale(uint8 numberOfTokens, bytes32[] calldata merkleProof, uint8 presaleWave)
        external
        payable
        whenNotPaused
    {
        require(presaleHasStarted(), "PRESALE_NOT_STARTED");
        require(currentPresaleWave() >= presaleWave, "PRESALE_WAVE_NOT_STARTED");

        require(
            _presalePurchases[_msgSender()] + numberOfTokens <= maxPresaleMints(presaleWave),
            "MAX_PRESALE_MINTS_EXCEEDED"
        );

        require(
            mintPrice(numberOfTokens) == msg.value,
            "VALUE_INCORRECT"
        );

        require(
            MerkleProof.verify(
                merkleProof,
                _presaleWaves[presaleWave].merkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "INVALID_MERKLE_PROOF"
        );

        _presalePurchases[_msgSender()] += numberOfTokens;
        token.mintTokens(numberOfTokens, _msgSender());
    }
}
