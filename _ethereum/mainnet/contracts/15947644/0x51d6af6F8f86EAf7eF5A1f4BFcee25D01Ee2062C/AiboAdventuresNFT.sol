// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
// import "./Counters.sol";
import "./Strings.sol";
import "./DefaultOperatorFilterer.sol";

// import "./MerkleProof.sol";
import "./MerkleProof.sol";

contract AiboAdventuresNFT is
    ERC721,
    Ownable,
    DefaultOperatorFilterer
{
    event Received(address, uint256);
    event Fallback(address, uint256);

    event SetMaxSupply(address addr, uint256 _maxSupply);
    event SetAibolistPrice(address addr, uint256 _price);
    event SetPubliclistPrice(address addr, uint256 _price);
    event SetPlPrice(address addr, uint256 _price);

    event SetAibolistLimit(address addr, uint256 _count);
    event SetPubliclistLimit(address addr, uint256 _count);
    event SetSaleLimit(address addr, uint256 _count);

    event WithdrawAll(address addr, uint256 cro);

    event SetBaseURI(string baseURI);
    event SetGoldenList(address _user);
    event SetAibolistList(address _user);
    event SetPubliclistList(address _user);
    event EggType(string _eggtype, address addr);
    event SetPlList(address _user);

    using Strings for uint256;

    uint256 private MAX_SUPPLY;
    uint256 private MAX_GOOD_OR_EVIL_COUNT;

    uint256 private AibolistPrice;
    uint256 private PubliclistPrice;
    uint256 private SalePrice;

    uint256 private AibolistLimit;
    uint256 private PubliclistLimit;
    uint256 private SaleLimit;

    uint256 private AibolistTotalLimit;
    uint256 private PubliclistTotalLimit;
    uint256 private TeamTotalLimit;

    uint256 private _aibolistMintedCnt;
    uint256 private _publiclistMintedCnt;
    uint256 private _salelistMintedCnt;
    uint256 private _teamMintedCnt;

    uint256 private _nftMintedCount;
    uint256 private _goodNftMintedCount;
    uint256 private _evilNftMintedCount;
    uint256 private mintType;
    string private _baseURIExtended;
    string private _baseExtension;
    bool private revealed;
    string private notRevealedGoodEggUri;
    string private notRevealedEvilEggUri;

    bool private paused;

    mapping(address => uint256) _AibolistMintedCountList;
    mapping(address => uint256) _PubliclistMintedCountList;
    mapping(address => uint256) _SaleMintedCountList;
    mapping(uint256 => uint256) _uriToTokenId;

    bytes32 private merkleAibolistListRoot;
    bytes32 private merklePubliclistListRoot;

    constructor() ERC721 ("Aibo Adventures", "AA"){

        MAX_SUPPLY = 7799;
        MAX_GOOD_OR_EVIL_COUNT = 4500;

        AibolistPrice = 0.027 ether;
        PubliclistPrice = 0.037 ether;
        SalePrice = 0.037 ether;

        AibolistLimit = 3;
        PubliclistLimit = 3;
        SaleLimit = 3;
        TeamTotalLimit = 249;
        AibolistTotalLimit = 4750;
        PubliclistTotalLimit = 2800;

        mintType = 0;

        merkleAibolistListRoot = 0xc72d2373ed597cc1eccd45955203671adfd9ffe47c2050a819670fc66635011c;
        merklePubliclistListRoot = 0xc72d2373ed597cc1eccd45955203671adfd9ffe47c2050a819670fc66635011c;

        _baseURIExtended = "https://ipfs.infura.io/";
        _baseExtension = ".json";
        _nftMintedCount = 0;
        _goodNftMintedCount = 0;
        _evilNftMintedCount = 0;

        paused = true;
        revealed = false;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setMintType(uint256 nftMintType) external onlyOwner {
        mintType = nftMintType;
    }

    function getMintType() external view returns (uint256) {
        return mintType;
    }

    function setAibolistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleAibolistListRoot = _merkleRoot;
    }

    function getAibolistMerkleRoot() external view returns (bytes32) {
        return merkleAibolistListRoot;
    }

    function setPubliclistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merklePubliclistListRoot = _merkleRoot;
    }

    function getPubliclistMerkleRoot() external view returns (bytes32) {
        return merklePubliclistListRoot;
    }

    function setTeamTotalLimit(uint256 _totallimitVal) external onlyOwner {
        TeamTotalLimit = _totallimitVal;
    }

    function getTeamTotalLimit() external view returns (uint256) {
        return TeamTotalLimit;
    }

    function setAibolistTotalLimit(uint256 _totallimitVal) external onlyOwner {
        AibolistTotalLimit = _totallimitVal;
    }

    function getAibolistTotalLimit() external view returns (uint256) {
        return AibolistTotalLimit;
    }

    function setPubliclistTotalLimit(uint256 _totallimitVal)
        external
        onlyOwner
    {
        PubliclistTotalLimit = _totallimitVal;
    }

    function getPubliclistTotalLimit() external view returns (uint256) {
        return PubliclistTotalLimit;
    }

    function setAibolistLimit(uint256 _mintlimitVal) external onlyOwner {
        AibolistLimit = _mintlimitVal;
        emit SetAibolistLimit(msg.sender, _mintlimitVal);
    }

    function getAibolistLimit() external view returns (uint256) {
        return AibolistLimit;
    }

    function setPubliclistLimit(uint256 _mintlimitVal) external onlyOwner {
        PubliclistLimit = _mintlimitVal;
        emit SetPubliclistLimit(msg.sender, _mintlimitVal);
    }

    function getPubliclistLimit() external view returns (uint256) {
        return PubliclistLimit;
    }

    function setSaleLimit(uint256 _mintlimitVal) external onlyOwner {
        SaleLimit = _mintlimitVal;
        emit SetSaleLimit(msg.sender, _mintlimitVal);
    }

    function getSaleLimit() external view returns (uint256) {
        return SaleLimit;
    }

    function setAibolistPrice(uint256 _price) external onlyOwner {
        AibolistPrice = _price;
        emit SetAibolistPrice(msg.sender, _price);
    }

    function getAibolistPrice() external view returns (uint256) {
        return AibolistPrice;
    }

    function setPubliclistPrice(uint256 _price) external onlyOwner {
        PubliclistPrice = _price;
        emit SetPubliclistPrice(msg.sender, _price);
    }

    function getPubliclistPrice() external view returns (uint256) {
        return PubliclistPrice;
    }

    function setSalePrice(uint256 _price) external onlyOwner {
        SalePrice = _price;
        emit SetPlPrice(msg.sender, _price);
    }

    function getSalePrice() external view returns (uint256) {
        return SalePrice;
    }

    function getAibolistMintedCountList() external view returns (uint256) {
        return _AibolistMintedCountList[msg.sender];
    }

    function getPubliclistMintedCountList() external view returns (uint256) {
        return _PubliclistMintedCountList[msg.sender];
    }

    function getSaleMintedCountList() external view returns (uint256) {
        return _SaleMintedCountList[msg.sender];
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
        emit SetMaxSupply(msg.sender, _maxSupply);
    }

    function getMaxSupply() external view returns (uint256) {
        return MAX_SUPPLY;
    }

    function totalSupply() external view returns (uint256) {
        return _nftMintedCount;
    }

    function getGoodMintedCount() external view returns (uint256) {
        return _goodNftMintedCount;
    }

    function getEvilMintedCount() external view returns (uint256) {
        return _evilNftMintedCount;
    }

    function getNftMintPrice(uint256 amount) external view returns (uint256) {
        if (mintType == 0) {
            return amount * AibolistPrice;
        } else if (mintType == 1) {
            return amount * PubliclistPrice;
        } else {
            return amount * SalePrice;
        }
    }

    function getUserWhiteListed(bytes32[] calldata _merkleProof)
        external
        view
        returns (uint256)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint256 value;
        if (mintType == 0) {
            require(
                MerkleProof.verify(
                    _merkleProof,
                    merkleAibolistListRoot,
                    leaf
                ) == true,
                "Not registered at Aibolist"
            );
            value = 1;
        } else if (mintType == 1) {
            require(
                MerkleProof.verify(
                    _merkleProof,
                    merklePubliclistListRoot,
                    leaf
                ) == true,
                "Not registered at Publiclist"
            );
            value = 2;
        } else {
            value = 3;
        }
        return value;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
        emit SetBaseURI(baseURI);
    }

    function getBaseURI() external view returns (string memory) {
        return _baseURIExtended;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setNotRevealedURI(string memory _gooduri, string memory _eviluri)
        external
        onlyOwner
    {
        notRevealedGoodEggUri = _gooduri;
        notRevealedEvilEggUri = _eviluri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        if (revealed == false) {
            if (_uriToTokenId[tokenId] <= MAX_GOOD_OR_EVIL_COUNT) {
                return notRevealedGoodEggUri;
            } else {
                return notRevealedEvilEggUri;
            }
        } else {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _uriToTokenId[tokenId].toString(),
                            _baseExtension
                        )
                    )
                    : "";
        }
    }

    function withdrawAll() external onlyOwner {
        address payable mine = payable(msg.sender);
        uint256 balance = address(this).balance;

        if (balance > 0) {
            mine.transfer(address(this).balance);
        }

        emit WithdrawAll(msg.sender, balance);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Fallback(msg.sender, msg.value);
    }

    function teamMint(
        uint256 _mintAmount,
        uint256 _nftType,
        address toMember
    ) external onlyOwner {
        require(
            _nftMintedCount + _mintAmount <= MAX_SUPPLY,
            "Already Finished Minting"
        );
        require(
            _teamMintedCnt + _mintAmount <= TeamTotalLimit,
            "Overflow of TeamTotalLimit"
        );
        require(_mintAmount > 0, "mintAmount must be bigger than 0");

        if (_nftType == 1) {
            require(
                _goodNftMintedCount + _mintAmount <= MAX_GOOD_OR_EVIL_COUNT,
                "Overflow of MAX good eggs"
            );

            require(
                _goodNftMintedCount + _evilNftMintedCount + _mintAmount <=
                    MAX_SUPPLY,
                "Overflow of MAX_SUPPLY"
            );
            emit EggType("GoodEgg", toMember);

            uint256 idx;
            for (idx = 0; idx < _mintAmount; idx++) {
                _nftMintedCount++;
                _goodNftMintedCount++;
                _uriToTokenId[_nftMintedCount + idx] = _goodNftMintedCount;
                _safeMint(toMember, _nftMintedCount);
            }
        } else {
            require(
                _evilNftMintedCount + _mintAmount <= MAX_GOOD_OR_EVIL_COUNT,
                "Overflow of MAX evil eggs"
            );

            require(
                _goodNftMintedCount + _evilNftMintedCount + _mintAmount <=
                    MAX_SUPPLY,
                "Overflow of MAX_SUPPLY"
            );
            emit EggType("EvilEgg", toMember);

            uint256 idx;
            for (idx = 0; idx < _mintAmount; idx++) {
                _nftMintedCount++;
                _evilNftMintedCount++;
                _uriToTokenId[_nftMintedCount + idx] =
                    MAX_GOOD_OR_EVIL_COUNT +
                    _evilNftMintedCount;
                _safeMint(toMember, _nftMintedCount);
            }
        }
        _teamMintedCnt = _teamMintedCnt + _mintAmount;
    }

    function mint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof,
        uint256 _nftType
    ) external payable {
        require(!paused, "The contract is paused");
        require(
            _nftMintedCount + _mintAmount <= MAX_SUPPLY,
            "Already Finished Minting"
        );

        require(_mintAmount > 0, "mintAmount must be bigger than 0");

        uint256 currentPrice;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (mintType == 0) {
            require(
                MerkleProof.verify(
                    _merkleProof,
                    merkleAibolistListRoot,
                    leaf
                ) == true,
                "Not registered at Aibolist"
            );
            require(
                _AibolistMintedCountList[msg.sender] + _mintAmount <=
                    AibolistLimit,
                "Overflow of aibolist mint limit"
            );
            require(
                _aibolistMintedCnt + _mintAmount <= AibolistTotalLimit,
                "Overflow of AibolistTotalLimit"
            );
            currentPrice = AibolistPrice;
            _AibolistMintedCountList[msg.sender] += _mintAmount;
            _aibolistMintedCnt += _mintAmount;
        } else if (mintType == 1) {
            require(
                MerkleProof.verify(
                    _merkleProof,
                    merklePubliclistListRoot,
                    leaf
                ) == true,
                "Not registered at Publiclist"
            );
            require(
                _PubliclistMintedCountList[msg.sender] + _mintAmount <=
                    PubliclistLimit,
                "Overflow of public mint limit"
            );
            require(
                _publiclistMintedCnt + _mintAmount <= PubliclistTotalLimit,
                "Overflow of PubliclistTotalLimit"
            );
            currentPrice = PubliclistPrice;
            _PubliclistMintedCountList[msg.sender] += _mintAmount;
            _publiclistMintedCnt += _mintAmount;
        } else {
            require(
                _SaleMintedCountList[msg.sender] + _mintAmount <= SaleLimit,
                "Overflow of sale mint limit"
            );
            require(
                _salelistMintedCnt + _mintAmount <=
                    MAX_SUPPLY - PubliclistTotalLimit - AibolistTotalLimit,
                "Overflow of SalelistTotalLimit"
            );
            currentPrice = SalePrice;
            _SaleMintedCountList[msg.sender] += _mintAmount;
            _salelistMintedCnt += _mintAmount;
        }
        currentPrice = currentPrice * _mintAmount;
        require(currentPrice <= msg.value, "Not Enough Money");

        if (_nftType == 1) {
            require(
                _goodNftMintedCount + _mintAmount <= MAX_GOOD_OR_EVIL_COUNT,
                "Overflow of MAX good eggs"
            );

            require(
                _goodNftMintedCount + _evilNftMintedCount + _mintAmount <=
                    MAX_SUPPLY,
                "Overflow of MAX_SUPPLY"
            );
            emit EggType("GoodEgg", msg.sender);

            uint256 idx;
            for (idx = 0; idx < _mintAmount; idx++) {
                _nftMintedCount++;
                _goodNftMintedCount++;
                _uriToTokenId[_nftMintedCount + idx] = _goodNftMintedCount;
                _safeMint(msg.sender, _nftMintedCount);
            }
        } else {
            require(
                _evilNftMintedCount + _mintAmount <= MAX_GOOD_OR_EVIL_COUNT,
                "Overflow of MAX evil eggs"
            );

            require(
                _goodNftMintedCount + _evilNftMintedCount + _mintAmount <=
                    MAX_SUPPLY,
                "Overflow of MAX_SUPPLY"
            );
            emit EggType("EvilEgg", msg.sender);

            uint256 idx;
            for (idx = 0; idx < _mintAmount; idx++) {
                _nftMintedCount++;
                _evilNftMintedCount++;
                _uriToTokenId[_nftMintedCount + idx] =
                    MAX_GOOD_OR_EVIL_COUNT +
                    _evilNftMintedCount;
                _safeMint(msg.sender, _nftMintedCount);
            }
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
