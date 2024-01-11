// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./IERC2981.sol";

interface IZzoopersRandomizer {
    function getMetadataId(uint256 batchNo, uint256 zzoopersEVOTokenId)
        external
        returns (uint256);
}

/**
 * @title Zzoopers contract
 */
contract Zzoopers is ERC721, IERC2981, Ownable {
    using Strings for *;

    address private _zooboxAddress;
    IZzoopersRandomizer private _randomizer;

    uint256 _tokenId;
    mapping(uint256 => uint256) private _metadataIds; //tokenId => metadataId
    mapping(uint256 => string) private _baseURIs; //batchNo => baseURI
    string private _contractURI;

    uint256 constant LIMIT_AMOUNT = 5555;
    uint256 constant BATCH_SIZE = 1111;

    bool public _contractLocked = false;

    address private _mintFeeReceiver;
    address private _royaltyReceiver;
    uint256 private _royaltyRate = 65; //6.5%

    event ZzoopersRevealed(
        address indexed owner,
        uint256 tokenId,
        uint256 metadataId
    );

    constructor(
        address zooBoxAddress,
        address randomizerAddress,
        string memory contractUri
    ) ERC721("Zzoopers", "Zzoopers") Ownable() {
        _zooboxAddress = zooBoxAddress;
        _randomizer = IZzoopersRandomizer(randomizerAddress);
        _contractURI = contractUri;
        _tokenId = 1; //TokenId start from 1
    }

    function setZzoopersEVOAddress(address newZooboxAddress) public onlyOwner {
        require(!_contractLocked, "Zzoopers: Contract has been locked");
        _zooboxAddress = newZooboxAddress;
    }

    function setRandomizer(address randomizer) public onlyOwner {
        _randomizer = IZzoopersRandomizer(randomizer);
    }

    function mint(
        uint256 batchNo,
        uint256 zzoopersEVOTokenId,
        address to
    ) external returns (uint256 tokenId) {
        require(
            msg.sender == _zooboxAddress,
            "Zzoopers: Caller not authorized"
        );
        require(
            zzoopersEVOTokenId <= LIMIT_AMOUNT,
            "ZzoopersRandomizer: TokenId cannot larger than 5555"
        );

        uint256 metadataId = _randomizer.getMetadataId(
            batchNo,
            zzoopersEVOTokenId
        );
        require(
            metadataId <= LIMIT_AMOUNT,
            "ZzoopersRandomizer: MetadataId cannot larger than 5555"
        );
        tokenId = _tokenId;
        _safeMint(to, tokenId);
        _metadataIds[tokenId] = metadataId;

        _tokenId++;
        emit ZzoopersRevealed(msg.sender, tokenId, metadataId);
        return tokenId;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenId - 1;
    }

    function setBaseURI(uint256 batchNo, string calldata baseURI)
        public
        onlyOwner
    {
        require(
            batchNo >= 1 && batchNo <= 5,
            "Zzoopers: BatchNo must between: 1 and 5"
        );
        require(!_contractLocked, "Zzoopers: Contract has been locked");
        _baseURIs[batchNo] = baseURI;
    }

    function getMetadataId(uint256 tokenId) external view returns (uint256) {
        return _metadataIds[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Zzoopers: TokenId not exists");

        uint256 metadataId = _metadataIds[tokenId];
        uint256 batchNo = metadataId / BATCH_SIZE;
        if (metadataId % BATCH_SIZE != 0) {
            batchNo++;
        }

        return
            string(
                abi.encodePacked(
                    _baseURIs[batchNo],
                    Strings.toString(metadataId)
                )
            );
    }

    function setContractURI(string calldata contractUri) public onlyOwner {
        require(!_contractLocked, "Zzoopers: Contract has been locked");
        _contractURI = contractUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function lockContract() public onlyOwner {
        _contractLocked = true;
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
            "Zzoopers: newRoyaltyRate should between [0, 1000]"
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

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
