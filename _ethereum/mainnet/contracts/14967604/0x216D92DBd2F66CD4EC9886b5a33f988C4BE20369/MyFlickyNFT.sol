pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./SafeMath.sol";
import "./console.sol";

contract MyFlickyNFT is ERC721A, Ownable, IERC2981 {
    using Counters for Counters.Counter;

    using SafeMath for uint256;

    address private gateKeeper = 0x1bCcFFdb1279aA7C4985Ec45f3358A739B594404;

    mapping (address => uint256) private operatorCounts;
    
    mapping (uint256 => uint256) private tokenIdsToMetadataIds;
    mapping (uint256 => bool) private metadataIdTaken;


    string public baseURI = "ipfs://QmaVXsgQAmyhGMAqpQxpqZ8mCM4vihY6zMxt5SyBDmrceS/";
    bool public revealed = false;

    bool public allowlistOnly = true;

    address private royaltyReciever;

    string private constant ALLOWLIST_MINT = "ALLOWLIST_MINT";
    string private constant GENERAL_MINT = "GENERAL_MINT";
    string private constant MAP_MINT = "MAP_MINT";
    string private constant RESERVED_MINT = "RESERVED_MINT";

    uint256 private constant RESERVED_TOTAL = 180;
    uint256 private constant MAP_TOTAL = 500;
    uint256 private constant ALLOWLIST_TOTAL = 3475;
    uint256 private constant PUBLIC_MINT_TOTAL = 1400;

    uint256 public reservedCount = 0;
    uint256 public mapCount = 0;
    uint256 public allowlistCount = 0;
    uint256 public publicMintCount = 0;

    function getCounts() 
        public
        view
        returns (uint256, uint256, uint256, uint256) 
    {
        return (reservedCount, mapCount, allowlistCount, publicMintCount);
    }

    function getCost()
        public view
        returns (uint256)
    {
        if (allowlistOnly) {
            return 0.07 ether;
        } else {
            return 0.075 ether;
        }
    }

    function setAllowlistOnly(bool _allowlistOnly) 
        public 
        onlyOwner 
    {
        allowlistOnly = _allowlistOnly;
    }

    function getAllowlistState()
        public view
        returns (bool)
    {
        return allowlistOnly;
    }

    function getBaseURI() 
        public 
        view 
        returns (string memory) 
    {
        return baseURI;
    }

    function setBaseURI(string memory _baseURI) 
        public 
        onlyOwner 
    {
        baseURI = _baseURI;
    }

    function setRevealed(bool _revealed) 
        public 
        onlyOwner 
    {
        revealed = _revealed;
    }

    function getRevealed() 
        public 
        view 
        returns (bool) 
    {
        return revealed;
    }

    
    function compareStrings(string memory a, string memory b) 
        public 
        pure 
        returns (bool) 
    {
        return (keccak256(bytes(a)) == keccak256(bytes(b)));
    }

    function recoverSignerAddress(uint256 _metadataIndex, string memory _nftType, uint8 v, bytes32 r, bytes32 s) 
        public
        pure
        returns (address)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 recreatedMessage = keccak256(abi.encodePacked(_metadataIndex, _nftType));
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, recreatedMessage));
        return ecrecover(prefixedHashMessage, v, r, s);
    }

    function wasSignedByGateKeeper(uint256 _metadataIndex, string memory _nftType, uint8 v, bytes32 r, bytes32 s)
        public
        view
        returns (bool)
    {
        return recoverSignerAddress(_metadataIndex, _nftType, v, r, s) == gateKeeper;
    }

    function getGateKeeper() 
        public
        view
        returns (address)
    {
        return gateKeeper;
    }

    function setGateKeeper(address _gateKeeper)
        public
        onlyOwner
        returns (bool)
    {
        gateKeeper = _gateKeeper;
        return true;
    }


    mapping (uint256 => string) private tokenURIs;

    constructor() ERC721A("Flicky", "FLKY") {}

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI)
        internal
        virtual
    {
        tokenURIs[_tokenId] = _tokenURI;
    }

    function tokenURI(uint256 _tokenId) 
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI_ = getBaseURI();
        uint256 metadataId = tokenIdsToMetadataIds[_tokenId];

        if (revealed) {
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(metadataId), ".json")) : "";
        } else {
            return baseURI_;
        }

    }


    function _incrementTypeCount(string memory _nftType)
        private
    {
        if (compareStrings(_nftType, ALLOWLIST_MINT)) {
            publicMintCount = publicMintCount.add(1);
            allowlistCount = allowlistCount.add(1);
        }
        if (compareStrings(_nftType, GENERAL_MINT)) {
            publicMintCount = publicMintCount.add(1);
        }
        if (compareStrings(_nftType, MAP_MINT)) {
            mapCount = mapCount.add(1);
        }
        if (compareStrings(_nftType, RESERVED_MINT)) {
            reservedCount = reservedCount.add(1);
        }
    }

    function _canTypeBeMinted(string memory _nftType)
        private
        view
        returns (bool)
     {
        if (compareStrings(_nftType, ALLOWLIST_MINT)) {
            if (allowlistCount < ALLOWLIST_TOTAL && publicMintCount < PUBLIC_MINT_TOTAL) {
                return true;
            } else {
                return false;
            }
        }
        require(!allowlistOnly, "Only allowlisted participants may mint");
        if (compareStrings(_nftType, GENERAL_MINT)) {
            if (publicMintCount < PUBLIC_MINT_TOTAL) {
                return true;
            } else {
                return false;
            }
        }
        if (compareStrings(_nftType, MAP_MINT)) {
            if (mapCount < MAP_TOTAL) {
                return true;
            } else {
                return false;
            }
        }
        if (compareStrings(_nftType, RESERVED_MINT)) {
            if (reservedCount < RESERVED_TOTAL) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }

    function mint(uint256 _metadataId, string memory _nftType, uint8 v, bytes32 r, bytes32 s)
        public
        payable
        returns (uint256)
    {
        require(!metadataIdTaken[_metadataId], "A token with this id has already been minted");
        require(wasSignedByGateKeeper(_metadataId, _nftType, v, r, s), "May only mint with approved signature from gatekeeper.");        
        require(_canTypeBeMinted(_nftType), "The maximum amount of that type of Flicky have already been minted");
        require(msg.value >= getCost(), "Insufficient eth was paid");

        uint256 tokenId = _currentIndex;
        tokenIdsToMetadataIds[tokenId] = _metadataId;
        metadataIdTaken[_metadataId] = true;        
        _safeMint(_msgSender(), 1);
        _incrementTypeCount(_nftType);

        return tokenId;
    }

    function multipleMint(uint256[] memory _metadataIds, string[] memory _nftTypes, uint256 _numToMint, 
        uint8[] memory v_sigs, bytes32[] memory r_sigs, bytes32[] memory s_sigs)
        public
        payable
    {
        require(_numToMint <= 10 && _numToMint > 0);
        require(msg.value >= (getCost() * _numToMint), "Insufficient eth was paid");
        uint256 tokenId = _currentIndex;
        for (uint i = 0; i < _numToMint; i++) {
            uint256 metadataId = _metadataIds[i];
            string memory nftType = _nftTypes[i];
            require(!metadataIdTaken[metadataId], "A token with this id has already been minted");
            require(_canTypeBeMinted(nftType), "The maximum amount of that type of Flicky have already been minted");
            uint8 v = v_sigs[i];
            bytes32 r = r_sigs[i];
            bytes32 s = s_sigs[i];
            require(wasSignedByGateKeeper(metadataId, nftType, v, r, s), "May only mint with approved signature from gatekeeper.");              
            tokenIdsToMetadataIds[tokenId] = metadataId;
            metadataIdTaken[metadataId] = true;
            tokenId.add(1);
            _incrementTypeCount(nftType);
        }

        _safeMint(_msgSender(), _numToMint);
    }

    function efficientBulkMintMapAndReservedNfts(address to)
        public
        onlyOwner
    {
        require(mapCount == 0);
        require(reservedCount == 0);
        reservedCount = 180;
        mapCount = 500;
        _safeMint(to, MAP_TOTAL + RESERVED_TOTAL);
    }

    function setRoyalityReciever(address _royaltyReceiver)
        public
        onlyOwner
    {
        royaltyReciever = _royaltyReceiver;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        override
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 basePercent = 500;
        uint256 fivePercent = SafeMath.div(SafeMath.mul(salePrice, basePercent), 10000);
        return (royaltyReciever, fivePercent);
    }


    function setApprovalForAll(address operator, bool approved) 
        public 
        virtual 
        override 
    {
        super.setApprovalForAll(operator, approved);
        operatorCounts[_msgSender()] = operatorCounts[_msgSender()].add(1);
    }

    function resetOperatorApprovals(address[] memory _operatorsToReset) 
        public 
    {
        require(operatorCounts[_msgSender()] > 0, "Operator approvals must be greater than 0");
        for (uint256 i = 0; i < _operatorsToReset.length; i++) {
            require(super.isApprovedForAll(_msgSender(), _operatorsToReset[i]), "Operator must be approved to rest");
            super.setApprovalForAll(_operatorsToReset[i], false);
            operatorCounts[_msgSender()] = operatorCounts[_msgSender()].sub(1);
        }
    }

    function getOperatorCount() public view returns (uint256) {
        return operatorCounts[_msgSender()];
    }

    function withdraw() 
        public 
        onlyOwner 
    {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}