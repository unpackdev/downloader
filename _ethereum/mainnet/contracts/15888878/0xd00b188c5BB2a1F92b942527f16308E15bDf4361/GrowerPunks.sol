// SPDX-License-Identifier: MIT

// .|'''''|                                        '||'''|,                   '||
// || .                                             ||   ||                    ||
// || |''|| '||''| .|''|, '\\    //` .|''|, '||''|  ||...|' '||  ||` `||''|,   || //`  (''''
// ||    ||  ||    ||  ||   \\/\//   ||..||  ||     ||       ||  ||   ||  ||   ||<<     `'')
// `|....|' .||.   `|..|'    \/\/    `|...  .||.   .||       `|..'|. .||  ||. .|| \\.  `...'
// 8=======================================================================================D

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

abstract contract PunksData {
    function punkAttributes(uint16 index) external view returns (string memory text) {}

    function punkImageSvg(uint16 index) external view returns (string memory svg) {}
}

abstract contract GrowerPrinter {
    function json(
        string memory growerPunk,
        string memory attrs,
        uint256 length,
        uint256 maxLength,
        uint256 tokenId
    ) external view returns (string memory jsonStr) {}

    function svg(
        string memory punk,
        string memory attrs,
        uint256 length
    ) external view returns (string memory svgStr) {}
}

error BurnNotActive();
error NoContractCalls();
error NoIdsLeft();
error NotEnoughETH();
error NotOnAllowlist();
error PublicSaleNotActive();
error SaleNotActive();
error TooManyFreeMints();
error TooManyMints();
error QuantityExceedsSupply();
error WithdrawalFailed();

contract GrowerPunks is ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {
    PunksData punksData;
    GrowerPrinter growerPrinter;

    // collection
    uint256 public constant COLLECTION_SIZE = 10000;
    string public contractMetadataURI;

    // owner
    address payable public withdrawalAddress;

    // mint parameters
    uint256 public qtyReserved;
    uint256 public qtyFree;
    uint256 public qtyFreeAllowlist;
    uint256 public mintPriceFive;
    uint256 public mintPriceThirty;
    uint256 public mintPriceFiveAllowlist;
    uint256 public mintPriceThirtyAllowlist;
    bytes32 private _merkleRoot;

    // mint + burn state
    bool public burnActive = false;
    bool public saleActive = false;
    bool public publicSaleActive = false;
    uint256 private _index;
    uint256[COLLECTION_SIZE + 1] public _tokenIds;
    uint256 public numberMintedReserve = 0;
    mapping(address => uint256) private _numberMinted;

    // grower stuff
    uint256 public maxLength = 180;
    mapping(uint256 => uint256) public punkLength;

    constructor(
        string memory _contractMetadataURI,
        address _growerPrinterAddress,
        address _punksDataAddress,
        uint256 _qtyReserved,
        uint256 _qtyFree,
        uint256 _qtyFreeAllowlist,
        uint256 _mintPriceFive,
        uint256 _mintPriceThirty,
        uint256 _mintPriceFiveAllowlist,
        uint256 _mintPriceThirtyAllowlist
    ) ERC721("GrowerPunks", "GROWR") {
        contractMetadataURI = _contractMetadataURI;
        growerPrinter = GrowerPrinter(_growerPrinterAddress);
        punksData = PunksData(_punksDataAddress);
        qtyReserved = _qtyReserved;
        qtyFree = _qtyFree;
        qtyFreeAllowlist = _qtyFreeAllowlist;
        mintPriceFive = _mintPriceFive;
        mintPriceThirty = _mintPriceThirty;
        mintPriceFiveAllowlist = _mintPriceFiveAllowlist;
        mintPriceThirtyAllowlist = _mintPriceThirtyAllowlist;
    }

    // etc

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    // public/read

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function getNumberMinted(address _owner) public view returns (uint256) {
        return _numberMinted[_owner];
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        // get punk SVG and attributes
        string memory punkSVG = punksData.punkImageSvg(uint16(_tokenId));
        string memory attrs = punksData.punkAttributes(uint16(_tokenId));
        // cap length
        uint256 cappedLength = punkLength[_tokenId] > maxLength ? maxLength : punkLength[_tokenId];
        // grow the punk
        string memory grownSVG = growerPrinter.svg(punkSVG, attrs, cappedLength);
        // build metadata and encode image as base64
        string memory json = growerPrinter.json(grownSVG, attrs, cappedLength, maxLength, _tokenId);
        // encode and return final base64 payload
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    // public/write

    function allowlistMintFree(bytes32[] calldata _proof) external nonReentrant {
        checkSender();
        checkSaleActive();
        checkAllowlist(_proof);
        checkQty(qtyFreeAllowlist, qtyFreeAllowlist);
        mintGrowers(msg.sender, qtyFreeAllowlist);
    }

    function allowlistMintFive(bytes32[] calldata _proof) external payable nonReentrant {
        checkSender();
        checkSaleActive();
        checkAllowlist(_proof);
        checkValue(mintPriceFiveAllowlist);
        checkQty(5, 72);
        mintGrowers(msg.sender, 5);
    }

    function allowlistMintThirty(bytes32[] calldata _proof) external payable nonReentrant {
        checkSender();
        checkSaleActive();
        checkAllowlist(_proof);
        checkValue(mintPriceThirtyAllowlist);
        checkQty(30, 72);
        mintGrowers(msg.sender, 30);
    }

    function publicMintFree() external nonReentrant {
        checkSender();
        checkSaleActive();
        checkPublicSaleActive();
        checkQty(qtyFree, qtyFree);
        mintGrowers(msg.sender, qtyFree);
    }

    function publicMintFive() external payable nonReentrant {
        checkSender();
        checkSaleActive();
        checkPublicSaleActive();
        checkQty(5, 72);
        checkValue(mintPriceFive);
        mintGrowers(msg.sender, 5);
    }

    function publicMintThirty() external payable nonReentrant {
        checkSender();
        checkSaleActive();
        checkPublicSaleActive();
        checkQty(30, 72);
        checkValue(mintPriceThirty);
        mintGrowers(msg.sender, 30);
    }

    function burn(uint256 _tokenId) public virtual override(ERC721Burnable) {
        if (!burnActive) {
            revert BurnNotActive();
        }
        super.burn(_tokenId);
    }

    // onlyOwner

    function setMaxLength(uint256 _maxLength) external onlyOwner {
        maxLength = _maxLength;
    }

    function setBurnActive(bool _burnActive) external onlyOwner {
        burnActive = _burnActive;
    }

    function setSaleActive(bool _saleAtive) external onlyOwner {
        saleActive = _saleAtive;
    }

    function setPublicSaleActive(bool _publicSaleActive) external onlyOwner {
        publicSaleActive = _publicSaleActive;
    }

    function setQtyFree(uint256 _qtyFree) external onlyOwner {
        qtyFree = _qtyFree;
    }

    function setQtyFreeAllowlist(uint256 _qtyFreeAllowlist) external onlyOwner {
        qtyFreeAllowlist = _qtyFreeAllowlist;
    }

    function setMintPriceFive(uint256 _mintPriceFive) external onlyOwner {
        mintPriceFive = _mintPriceFive;
    }

    function setMintPriceThirty(uint256 _mintPriceThirty) external onlyOwner {
        mintPriceThirty = _mintPriceThirty;
    }

    function setMintPriceFiveAllowlist(uint256 _mintPriceFiveAllowlist) external onlyOwner {
        mintPriceFiveAllowlist = _mintPriceFiveAllowlist;
    }

    function setMintPriceThirtyAllowlist(uint256 _mintPriceThirtyAllowlist) external onlyOwner {
        mintPriceThirtyAllowlist = _mintPriceThirtyAllowlist;
    }

    function setPunksData(address _punksDataAddress) external onlyOwner {
        punksData = PunksData(_punksDataAddress);
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        _merkleRoot = _newMerkleRoot;
    }

    function setWithdrawalAddress(address payable _withdrawalAddress) external onlyOwner {
        withdrawalAddress = _withdrawalAddress;
    }

    function reservedMint(uint256 _qty, address _toAddress) external onlyOwner {
        if (numberMintedReserve + _qty > qtyReserved) {
            revert TooManyMints();
        }
        numberMintedReserve += _qty;
        mintGrowers(_toAddress, _qty);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = withdrawalAddress.call{value: balance}("");
        if (!success) {
            revert WithdrawalFailed();
        }
    }

    // private

    function checkAllowlist(bytes32[] calldata _proof) private view {
        if (MerkleProof.verify(_proof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))) == false) {
            revert NotOnAllowlist();
        }
    }

    function checkSaleActive() private view {
        if (saleActive == false) {
            revert SaleNotActive();
        }
    }

    function checkPublicSaleActive() private view {
        if (publicSaleActive == false) {
            revert PublicSaleNotActive();
        }
    }

    function checkQty(uint256 _qty, uint256 _maxQty) private view {
        if (getNumberMinted(msg.sender) + _qty > _maxQty) {
            if (_qty < 5) {
                revert TooManyFreeMints();
            } else {
                revert TooManyMints();
            }
        }
        if (_index + _qty > COLLECTION_SIZE - qtyReserved + numberMintedReserve) {
            revert QuantityExceedsSupply();
        }
    }

    function checkSender() private view {
        if (msg.sender != tx.origin) {
            revert NoContractCalls();
        }
    }

    function checkValue(uint256 _expected) private view {
        if (msg.value < _expected) {
            revert NotEnoughETH();
        }
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        if (punkLength[_tokenId] < maxLength) {
            unchecked {
                uint256 newPunkLength = (punkLength[_tokenId] * (((_tokenId % 4) + 1) * 50 + 1150)) / 1000;
                punkLength[_tokenId] = punkLength[_tokenId] == newPunkLength ? punkLength[_tokenId] + 1 : newPunkLength;
            }
        }
    }

    function mintGrowers(address _to, uint256 _qty) private {
        _numberMinted[msg.sender] += _qty;
        uint256 i;
        while (i < _qty) {
            uint256 random = uint256(
                keccak256(abi.encodePacked(_index++, msg.sender, block.timestamp, blockhash(block.number - 1)))
            );
            uint256 newTokenId = randTokenId(random);
            _safeMint(_to, newTokenId);
            punkLength[newTokenId] = randLength(newTokenId);
            unchecked {
                i++;
            }
        }
    }

    function randLength(uint256 _tokenId) private view returns (uint256) {
        uint256 num = (_tokenId % 15) + 10;
        uint256 swerve = totalSupply() + 5;
        return uint256(keccak256(abi.encodePacked(num, swerve))) % num;
    }

    function randTokenId(uint256 random) private returns (uint256 id) {
        uint256 len = _tokenIds.length - _index;
        if (len == 0) {
            revert NoIdsLeft();
        }
        uint256 randomIndex = random % len;
        id = _tokenIds[randomIndex] != 0 ? _tokenIds[randomIndex] : randomIndex;
        _tokenIds[randomIndex] = uint16(_tokenIds[len - 1] == 0 ? len - 1 : _tokenIds[len - 1]);
        _tokenIds[len - 1] = 0;
        return id + 1;
    }
}
