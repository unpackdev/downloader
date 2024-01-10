pragma solidity ^0.8.7;

contract sale_configuration {
    uint256 _maxSupply;
    uint256 _clientMintLimit;
    uint256 _ecMintLimit;
    uint256 _fullPrice;
    uint256 _discountPrice; // obsolete
    uint256 _communityPrice; // obsolete
    uint256 _presaleStart; // obsolete
    uint256 _presaleEnd; // obsolete
    uint256 _saleStart;
    uint256 _saleEnd;
    uint256 _dustPrice; // obsolete
    uint256 _discountedPerAddress; // obsolete
    uint256 _totalDiscount; // obsolete
    uint256 _maxDiscount; // obsolete
    uint256 _maxPerSaleMint;
    uint256 _freePerAddress;
    address _signer;

    uint256 _maxFreeEC; // obsolete
    uint256 _totalFreeEC; // obsolete
    uint256 _ecMintPosition;
    uint256 _clientMintPosition;
    address _ecVault;
}
