// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Strings.sol";
import "./BitMaps.sol";
import "./ERC721A.sol";

contract NekoClans is ERC721A, EIP712, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;
    enum SalePhase {
        WhiteList,
        Free,
        Public
    }
    bool private initialized = false;
    uint256 public collectionSize;
    uint256 public freeMintCount;
    string public baseURI;
    address private signerAddress;
    address private withdrawAddress;
    uint64 public priceWl;
    uint64 public maxMintWl;
    uint64 public priceFree;
    uint64 public maxMintFree;
    uint64 public pricePublic;
    uint64 public maxMintPublic;

    mapping(SalePhase => mapping(address => uint256)) public mintedCount;

    constructor() ERC721A("NekoClans", "NekoClans") EIP712("NekoClans", "1") {
        signerAddress = owner();
        withdrawAddress = owner();
        collectionSize = 5666;
        freeMintCount = 2000;
    }

    function setSignerAddress(address newSignerAddress) external onlyOwner {
        signerAddress = newSignerAddress;
    }

    function setWithdrawAddress(address newWithdrawAddress) external onlyOwner {
        withdrawAddress = newWithdrawAddress;
    }

    function checkAndUpdateMintedCount(SalePhase phase, uint256 quantity)
        private
    {
        if (phase == SalePhase.WhiteList) {
            unchecked {
                require(
                    mintedCount[phase][msg.sender] + quantity <= maxMintWl,
                    "maxMintWl:Too many nft to adopt."
                );
                mintedCount[phase][msg.sender] += quantity;
            }
        } else if (phase == SalePhase.Free) {
            unchecked {
                require(
                    mintedCount[phase][msg.sender] + quantity <= maxMintFree,
                    "maxMintFree:Too many nft to adopt."
                );
                mintedCount[phase][msg.sender] += quantity;
            }
        } else if (phase == SalePhase.Public) {
            unchecked {
                require(
                    mintedCount[phase][msg.sender] + quantity <= maxMintPublic,
                    "maxMintPublic:Too many nft to adopt."
                );
                mintedCount[phase][msg.sender] += quantity;
            }
        } else {}
    }

    modifier checkPrice(SalePhase phase, uint256 quantity) {
        if (phase == SalePhase.WhiteList) {
            unchecked {
                require(msg.value == quantity * priceWl, "Incorrect price.");
            }
        } else if (phase == SalePhase.Free) {
            unchecked {
                require(msg.value == quantity * priceFree, "Incorrect price.");
            }
        } else if (phase == SalePhase.Public) {
            unchecked {
                require(
                    msg.value == quantity * pricePublic,
                    "Incorrect price."
                );
            }
        } else {}
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier isWithdrawAddress() {
        require(
            withdrawAddress == msg.sender,
            "The caller is incorrect address."
        );
        _;
    }

    function _hash(string memory _prefix, address _address)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_prefix, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return (_recover(hash, signature) == signerAddress);
    }

    function _recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function whiteListAdopt(
        uint256 quantity,
        bytes32 hash,
        bytes calldata signature
    ) external payable callerIsUser checkPrice(SalePhase.WhiteList, quantity) {
        checkAndUpdateMintedCount(SalePhase.WhiteList, quantity);
        require(_hash("whiteList", msg.sender) == hash, "Invalid hash.");
        require(_verify(hash, signature), "Invalid signature.");
        unchecked {
            require(
                _totalMinted() + quantity <= collectionSize,
                "Max supply reached."
            );
        }
        _safeMint(msg.sender, quantity);
    }

    function freeAdopt(uint256 quantity)
        external
        payable
        callerIsUser
        checkPrice(SalePhase.Free, quantity)
    {
        checkAndUpdateMintedCount(SalePhase.Free, quantity);
        unchecked {
            require(
                _totalMinted() + quantity <= collectionSize,
                "Max supply reached."
            );
        }
        unchecked {
            require(
                _totalMinted() + quantity <= freeMintCount,
                "Free mint supply reached."
            );
        }
        _safeMint(msg.sender, quantity);
    }

    function publicAdopt(uint256 quantity)
        external
        payable
        callerIsUser
        checkPrice(SalePhase.Public, quantity)
    {
        checkAndUpdateMintedCount(SalePhase.Public, quantity);
        unchecked {
            require(
                _totalMinted() + quantity <= collectionSize,
                "Max supply reached."
            );
        }
        _safeMint(msg.sender, quantity);
    }

    function firstMint() external onlyOwner {
        require(!initialized, "Contract is already initialized!");
        initialized = true;
        _safeMint(owner(), 1);
    }

    function setWhitelistInfo(uint64 _priceWl, uint64 _maxMintWl)
        external
        onlyOwner
    {
        priceWl = _priceWl;
        maxMintWl = _maxMintWl;
    }

    function setFreeInfo(uint64 _priceFree, uint64 _maxMintFree)
        external
        onlyOwner
    {
        priceFree = _priceFree;
        maxMintFree = _maxMintFree;
    }

    function setPublicInfo(uint64 _pricePublic, uint64 _maxMintPublic)
        external
        onlyOwner
    {
        pricePublic = _pricePublic;
        maxMintPublic = _maxMintPublic;
    }

    function setSaleInfo(uint64 _priceWl, uint64 _maxMintWl,uint64 _priceFree, uint64 _maxMintFree,uint64 _pricePublic, uint64 _maxMintPublic)
        external
        onlyOwner
    {
        priceWl = _priceWl;
        maxMintWl = _maxMintWl;
        priceFree = _priceFree;
        maxMintFree = _maxMintFree;
        pricePublic = _pricePublic;
        maxMintPublic = _maxMintPublic;
    }

    function setFreeMintCount(uint64 _freeMintCount) external onlyOwner {
        freeMintCount = _freeMintCount;
    }

    function setCollectionSize(uint64 _collectionSize) external onlyOwner {
        collectionSize = _collectionSize;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function withdraw(address beneficiary) external onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    function withdraw() external isWithdrawAddress callerIsUser {
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function getNftInfo(address _address)
        external
        view
        returns (
            uint256 _whitelistMinted,
            uint256 _freeMinted,
            uint256 _publicMinted,
            uint64 _priceWl,
            uint64 _maxMintWl,
            uint64 _priceFree,
            uint64 _maxMintFree,
            uint64 _pricePublic,
            uint64 _maxMintPublic,
            uint256 totalMinted
        )
    {
        return (
            mintedCount[SalePhase.WhiteList][_address],
            mintedCount[SalePhase.Free][_address],
            mintedCount[SalePhase.Public][_address],
            priceWl,
            maxMintWl,
            priceFree,
            maxMintFree,
            pricePublic,
            maxMintPublic,
            _totalMinted()
        );
    }    
}
