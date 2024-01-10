// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFT.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

    error NotInWhitelist();
    error InvalidAmountOfEthers();
    error CantSendEthersToWallet();
    error LimitExceeded();
    error PrivateSaleNotStarted();
    error PublicSaleNotStarted();

contract Sale is Ownable {
    // main NFT token
    NFT private immutable _nft;

    //limits
    enum SaleType{PRIVATE, PUBLIC}
    mapping(SaleType => uint256) private _tokenLimit;
    mapping(address => mapping(SaleType => uint256)) private _mints;

    uint256 private immutable _privateSalePrice;
    uint256 private immutable _publicSalePrice;

    // whitelist
    bytes32 private _merkleRoot;

    // Address where funds are collected
    address payable private immutable _wallet;

    uint256 private _privateSaleStartedAt;

    uint256 private _privateSaleStoppedAt;

    constructor(
        address payable _walletAddress,
        uint256 privateSalePrice_,
        uint256 publicSalePrice_,
        bytes32 _initialMerkleRoot,
        uint256 _privateMintsLimit,
        uint256 _publicMintsLimit,
        NFT _nftAddress,
        uint256 privateSaleStartedAt_,
        uint256 privateSaleStoppedAt_
    ) {
        require(_walletAddress != address(0), "TokenDEX: wallet is the zero address");
        _privateSalePrice = privateSalePrice_;
        _publicSalePrice = publicSalePrice_;
        _wallet = _walletAddress;
        _merkleRoot = _initialMerkleRoot;
        _tokenLimit[SaleType.PRIVATE] = _privateMintsLimit;
        _tokenLimit[SaleType.PUBLIC] = _publicMintsLimit;
        _nft = _nftAddress;
        _privateSaleStartedAt = privateSaleStartedAt_;
        _privateSaleStoppedAt = privateSaleStoppedAt_;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        _merkleRoot = merkleRoot_;
    }

    function changeSaleTime(uint256 _startedAt, uint256 _stoppedAt) public onlyOwner {
        _privateSaleStartedAt = _startedAt;
        _privateSaleStoppedAt = _stoppedAt;
    }

    function isPrivateSaleStarted() public view returns (bool) {
        if (_privateSaleStartedAt == 0 || _privateSaleStoppedAt == 0) {
            return true;
        }
        return block.timestamp >= _privateSaleStartedAt && block.timestamp <= _privateSaleStoppedAt;
    }

    function isPublicSaleStarted() public view returns (bool) {
        if (_privateSaleStoppedAt == 0) {
            return true;
        }
        return block.timestamp > _privateSaleStoppedAt;
    }


    function privateBuy(uint256 amount, bytes32[] calldata _merkleProof)
    public
    payable
    validateLimit(SaleType.PRIVATE, amount)
    validateProof(_merkleProof) {
        if (!isPrivateSaleStarted()) {
            revert PrivateSaleNotStarted();
        }
        uint costWei = (amount * _privateSalePrice);
        if (msg.value < costWei) {
            revert InvalidAmountOfEthers();
        }
        (bool sent,) = _wallet.call{value : costWei}("");
        if (!sent) {
            revert CantSendEthersToWallet();
        }
        _nft.mintTo(msg.sender, amount);
    }

    function publicBuy(uint256 amount) public payable validateLimit(SaleType.PUBLIC, amount) {
        if (!isPublicSaleStarted()) {
            revert PublicSaleNotStarted();
        }
        uint costWei = (amount * _publicSalePrice);
        if (msg.value < costWei) {
            revert InvalidAmountOfEthers();
        }
        (bool sent,) = _wallet.call{value : costWei}("");
        if (!sent) {
            revert CantSendEthersToWallet();
        }
        _nft.mintTo(msg.sender, amount);
    }

    modifier validateLimit(SaleType _type, uint256 amount) {
        uint256 limit = _tokenLimit[_type];
        if (limit > 0) {
            uint256 currentAmount = _mints[msg.sender][_type];
            if (amount > limit) {
                revert LimitExceeded();
            }
            if (currentAmount == 0) {
                _mints[msg.sender][_type] = amount;
            } else {
                uint256 resultAmount = currentAmount + amount;
                if (resultAmount > limit) {
                    revert LimitExceeded();
                }
                _mints[msg.sender][_type] = resultAmount;
            }
        }
        _;
    }


    modifier validateProof(bytes32[] calldata _merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, _merkleRoot, leaf)) {
            revert NotInWhitelist();
        }
        _;
    }

    function getAvailableMints() public view returns (uint256, uint256) {
        uint256 privateSaleAvailable = _tokenLimit[SaleType.PRIVATE] - _mints[msg.sender][SaleType.PRIVATE];
        uint256 publicSaleAvailable = _tokenLimit[SaleType.PUBLIC] - _mints[msg.sender][SaleType.PUBLIC];
        return (privateSaleAvailable, publicSaleAvailable);
    }

    function getPrivateSalePrice() public view returns (uint256){
        return _privateSalePrice;
    }

    function getPublicSalePrice() public view returns (uint256){
        return _publicSalePrice;
    }
}
