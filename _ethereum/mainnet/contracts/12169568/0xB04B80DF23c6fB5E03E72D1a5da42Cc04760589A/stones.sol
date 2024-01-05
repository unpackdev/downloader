// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./istones.sol";

struct SwapOffer {
    uint256 fromTokenId;
    uint256 toTokenId;
}

contract TheCryptoStonesToken is ERC721, AccessControl, Ownable, ReentrancyGuard, ICryptoStones {
    
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    
    // contains sha256(concat(sha256(image1), sha256(video1), sha256(image2), sha256(video2), ...)),
    // sorted by (mineral, cutting, translucency, size)
    uint256 public constant PROVENANCE_RECORD = 0xc4af0e0a1fc8d240ba88881b4e8b204d76b32380d7f54c1ad84e30004fdfeec9;

    bytes32 public constant META_UPDATER = keccak256("META_UPDATER");
    
    // using commit-reveal approach
    uint256 public constant COMMIT_START_TIMESTAMP = 1617580800;
    uint256 public constant REVEAL_TIMESTAMP = COMMIT_START_TIMESTAMP + (86400 * 14); // 14 days
    
    uint256 public constant MAX_SUPPLY = 4096;

    uint256 private constant WEI_PER_ETH = 10 ** 18;
    uint256 private constant PROPS_MASK = 0xFFF;
    uint256 private constant PROPS_MAX = 0x1000;
    uint256 private constant PROPS_SQR = 0x40;
    uint256 private constant PROPS_SQR2 = 0x1000;
    uint256 private constant PROPS_HASH_MUL = 2654435761;
    uint256 private constant PROPS_HASH_SHIFT = 20;
    uint256 private constant PROPS_ITERS = 5;

    mapping (uint256 => string) private _nftNames;
    mapping (string => bool) private _ntfReservedNames;

    mapping (uint256 => EnumerableSet.UintSet) private _sentOffers;
    mapping (uint256 => EnumerableSet.UintSet) private _receivedOffers;

    string private _metadataUri;
    uint256 private _lastCommitBlockIndex;
    uint256 private _seed;
    
    address[] private _parts;

    event NameSet (uint256 indexed tokenId, string name);

    constructor () ERC721("TheCryptoStones", "TCS") {
        address msgSender = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, msgSender);
        _setupRole(META_UPDATER, msgSender);
        
        // add authors
        address[] memory parts = new address[](12);
        parts[0] = 0x872DCA6BD398A393ee8f68F88eDa16577DA37B57;
        parts[1] = 0xA4F7A82ADF531fbD0f818317F141741D815DCcc0;
        parts[2] = 0xB216F04FdcF268Edb8DF72F610984c5932E590B4;
        parts[3] = 0x818A4db0A26c037147048C6202065700013ed4A8;
        parts[4] = 0x6d4957Fc0746328573a701333b8122362D08491e;
        parts[5] = 0xFfc86EA9D453496A334298a0EdDFFD046bed03B1;
        parts[6] = 0x343ce4e9b3d55cc6689C88B502b04E788d7de9A6;
        parts[7] = 0x315845e8e165C3F4b8BA57DD0d26Cfebf20a0F61;
        parts[8] = 0x5450fBAF5c5967B555470dfDfbc6cFbFB5dFAeb4;
        parts[9] = 0xf32881E6464b5315D3f8C0C079345C7f8852EBA0;
        parts[10] = 0xffeEe852F842735339F25C9A5BDCf075A99Eb5ec;
        parts[11] = 0x594099Fe99d3Ae33ff0308cdc405332b8Eb636f8;

        _parts = parts;
    }

    // ========== METADATA ==========

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        Stone memory stone = getStoneProps(tokenId);
        
        require(bytes(_metadataUri).length > 0, "Unknown token URI");
        
        return string(abi.encodePacked(_metadataUri,
                                       uint256(stone.mineral).toString(), '_',
                                       uint256(stone.cutting).toString(), '_',
                                       uint256(stone.translucency).toString(), '_',
                                       uint256(stone.size).toString()));
    }

    // we update metadata to set new names, i.e. the token images & videos are always the same (see PROVENANCE_RECORD)
    function setMetadataURI(string calldata baseURI) public {
        address msgSender = _msgSender();
        require(hasRole(META_UPDATER, msgSender));

        _metadataUri = baseURI;
    }

    // ========== PHASES ==========
    
    function isPreSaleAvailable() public view returns (bool) {
        uint256 currentSupply = totalSupply();
        return block.timestamp >= COMMIT_START_TIMESTAMP
            && block.timestamp < REVEAL_TIMESTAMP
            && currentSupply < MAX_SUPPLY
            && _seed == 0;
    }

    function isBoxOpen() public view returns (bool) {
        return _seed != 0;
    }

    function canOpenBox() public view returns (bool) {
        uint256 currentSupply = totalSupply();
        return (block.timestamp >= REVEAL_TIMESTAMP || currentSupply >= MAX_SUPPLY)
            && _seed == 0;
    }

    // open the box / start the public sale
    function openBox() public {
        require(canOpenBox(), "The box can't be open");

        address msgSender = _msgSender();
        uint256 boxItems = totalSupply();
        uint256 currentBlockInput = uint256(keccak256(abi.encodePacked(
            block.coinbase, msgSender, block.timestamp, block.difficulty, block.gaslimit)));

        uint256 lastCommitInput = uint256(keccak256(abi.encodePacked(boxItems, _lastCommitBlockIndex)));
        uint256 seed = uint256(blockhash(block.number-1)) ^ lastCommitInput ^ currentBlockInput;
        
        _seed = seed != 0 ? seed : boxItems + _lastCommitBlockIndex;
    }

    function reward() public {
        address[] memory parts = _parts;
        
        uint256 partBalance = address(this).balance / parts.length;
        if (partBalance > 0) {
            for (uint i = 0; i < parts.length; ++i) {
                address payable dest = payable(parts[i]);
                dest.transfer(partBalance);
            }
        }
    }

    // ========== NAMING STONES ==========

    // check whether the name is valid and available
    function isNameAvailable(string calldata name) public view returns (bool) {
        if (!validateName(name)) return false;
        
        string memory lowerCaseName = toLower(name);
        if (_ntfReservedNames[lowerCaseName]) return false;
        
        return true;
    }

    // get name of a stone
    function getTokenName(uint256 tokenId) public view returns (string memory) {
        return _nftNames[tokenId];
    }

    // set name of a stone
    function setTokenName(uint256 tokenId, string calldata name) public {
        address msgSender = _msgSender();

        address owner = ERC721.ownerOf(tokenId); // internal owner
        require(owner == msgSender, "Only owner can name an item");

        string memory oldName = _nftNames[tokenId];
        require(bytes(oldName).length == 0, "Name has been set already");

        require(validateName(name), "Name is invalid");

        string memory lowerCaseName = toLower(name);
        require(!_ntfReservedNames[lowerCaseName], "Name has been taken already");
        
        _nftNames[tokenId] = name;
        _ntfReservedNames[lowerCaseName] = true;
        
        emit NameSet(tokenId, name);
    }
    
    // ========== STONE PROPERTIES ==========
    
    function getProps(uint256 seed, uint256 nonce) private pure returns (uint256) {
        uint256 i = 0;
        uint256 x = nonce;
        while (i < PROPS_ITERS && x < PROPS_SQR2)
        {
            uint256 h = (uint256)(x / PROPS_SQR);
            uint256 l = x % PROPS_SQR;
            uint256 hash = ((h * PROPS_HASH_MUL) >> PROPS_HASH_SHIFT) % PROPS_SQR;
            l = (l + hash) % PROPS_SQR;
            x = (l * PROPS_SQR + h) ^ seed;
            x = (x + (PROPS_MAX - PROPS_SQR2)) % PROPS_MAX;
            ++i;
        }
        return x & PROPS_MASK;
    }
    
    // get properties of a stone
    function getStoneProps(uint256 tokenId) public view returns (Stone memory stone) {
        require(tokenId < MAX_SUPPLY, "Item is unknown");
        require(isBoxOpen(), "The box is closed");
        
        uint256 props = getProps(_seed, tokenId);
        stone.cutting =      uint8((props >> 0) & 0x0F);
        stone.mineral =      uint8((props >> 4) & 0x07);
        stone.translucency = uint8((props >> 7) & 0x03);
        stone.size =         uint8((props >> 9) & 0x07);
        
        stone.id = tokenId;
        stone.name = _nftNames[tokenId];

        if (_exists(tokenId)) {
            stone.owner = ERC721.ownerOf(tokenId);
        } else {
            stone.owner = address(0); // 0 if the item is unavailable
        }
    }

    // get properties of stones
    function getStonesProps(uint256[] calldata tokenIds) public view override returns (Stone[] memory) {
        require(isBoxOpen(), "The box is closed");

        Stone[] memory results = new Stone[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; ++i) {
            results[i] = getStoneProps(tokenIds[i]);
        }
        return results;
    }

    // get stones by an owner
    function getStonesByOwner(address owner) public view override returns (Stone[] memory) {
        require(isBoxOpen(), "The box is closed");
        
        uint256 tokens = ERC721.balanceOf(owner);
        Stone[] memory results = new Stone[](tokens);

        for (uint i = 0; i < tokens; ++i) {
            uint256 tokenId = ERC721.tokenOfOwnerByIndex(owner, i);
            results[i] = getStoneProps(tokenId);
        }
        return results;
    }

    // ========== BUYING ==========
    
    function getCurrentBasePrice() public view returns (uint256) {
        uint256 boxItems = totalSupply();
        uint256 basePrice = WEI_PER_ETH;
        
        if (boxItems < 100) {
            basePrice = WEI_PER_ETH / 10; // 0.1 ETH
        } else if (boxItems < 300) {
            basePrice = WEI_PER_ETH / 4;  // 0.25 ETH
        } else if (boxItems < 500) {
            basePrice = WEI_PER_ETH / 2;  // 0.5 ETH
        } else if (boxItems < 1000) {
            basePrice = WEI_PER_ETH;      // 1 ETH
        } else if (boxItems < 1500) {
            basePrice = WEI_PER_ETH * 2;  // 2 ETH
        } else if (boxItems < 2000) {
            basePrice = WEI_PER_ETH * 4;  // 4 ETH
        } else if (boxItems < 3000) {
            basePrice = WEI_PER_ETH * 6;  // 6 ETH
        } else if (boxItems < 4000) {
            basePrice = WEI_PER_ETH * 8;  // 8 ETH
        } else {
            basePrice = WEI_PER_ETH * 12; // 12 ETH
        }

        return basePrice;
    }
    
    // get price of a stone during the presale
    function getBoxPrice() public view returns (uint256) {
        require(isPreSaleAvailable(), "Presale is closed");
        
        return getCurrentBasePrice();
    }

    // get price of a stone during the public sale
    function getPublicPrice(uint256 tokenId) public view returns (uint256) {
        require(isBoxOpen(), "The box is closed");

        Stone memory stoneProps = getStoneProps(tokenId);
        uint256 basePrice = getCurrentBasePrice() * 2;
        
        // size correction
        for (uint i = 0; i < stoneProps.size; ++i) {
            basePrice += basePrice / 10;
        }
        // translucency correction
        for (uint i = 0; i < stoneProps.translucency; ++i) {
            basePrice += basePrice / 10;
        }

        return basePrice;
    }

    // get total price of selected stones during the public sale
    function getTotalPublicPrice(uint256[] calldata tokenIds) public view returns (uint256) {
        uint256 totalPrice = 0;

        for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];

            uint256 currentPrice = getPublicPrice(tokenId);
            totalPrice += currentPrice;
        }

        return totalPrice;
    }

    // buy stones during the presale
    function buyFromBox(uint256 count) public payable nonReentrant {
        require(count >= 1 && count <= 10, "Invalid number of items");

        uint256 currentPrice = getBoxPrice();
        require(msg.value >= currentPrice * count, "Invalid ether value");

        address msgSender = _msgSender();

        for (uint i = 0; i < count; ++i) {
            uint256 tokenId = totalSupply();
            require(tokenId < MAX_SUPPLY, "Exceeds max supply");

            _safeMint(msgSender, tokenId);
        }
        
        _lastCommitBlockIndex = block.number;
    }

    // buy stones during the public sale
    function buy(uint256[] calldata tokenIds) public payable nonReentrant {
        require(tokenIds.length >= 1 && tokenIds.length <= 10, "Invalid number of items");

        uint256 totalPrice = getTotalPublicPrice(tokenIds);
        require(msg.value >= totalPrice, "Invalid ether value");

        address msgSender = _msgSender();

        for (uint i = 0; i < tokenIds.length; ++i) {
            _safeMint(msgSender, tokenIds[i]); // it checks whether a token exists
        }
    }

    // ========== SWAPPING ==========
    
    // get offers sent to other tokens (offers by senders)
    function getSentSwapOffers(uint256[] calldata tokenIds) public view returns (SwapOffer[] memory) {
        uint256 offersCount = 0;
        for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            offersCount += _sentOffers[tokenId].length();
        }

        SwapOffer[] memory results = new SwapOffer[](offersCount);
        uint resultIndex = 0;

        for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            EnumerableSet.UintSet storage sentOffers = _sentOffers[tokenId];
            uint256 tokenOffersCount = sentOffers.length();

            for (uint j = 0; j < tokenOffersCount; ++j) {
                SwapOffer memory offer;
                offer.fromTokenId = tokenId;
                offer.toTokenId = sentOffers.at(j);
                
                results[resultIndex] = offer;
                ++resultIndex;
            }
        }
        
        return results;
    }

    // get offers received for a token (offers by receivers)
    function getReceivedSwapOffers(uint256[] calldata tokenIds) public view returns (SwapOffer[] memory) {
        uint256 offersCount = 0;
        for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            offersCount += _receivedOffers[tokenId].length();
        }

        SwapOffer[] memory results = new SwapOffer[](offersCount);
        uint resultIndex = 0;

        for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            EnumerableSet.UintSet storage receivedOffers = _receivedOffers[tokenId];
            uint256 tokenOffersCount = receivedOffers.length();

            for (uint j = 0; j < tokenOffersCount; ++j) {
                SwapOffer memory offer;
                offer.fromTokenId = receivedOffers.at(j);
                offer.toTokenId = tokenId;
                
                results[resultIndex] = offer;
                ++resultIndex;
            }
        }
        
        return results;
    }

    // ask for swaps
    function sendSwapOffers(SwapOffer[] calldata offers) public nonReentrant {
        address msgSender = _msgSender();

        for (uint i = 0; i < offers.length; ++i) {
            SwapOffer memory offer = offers[i];

            require(_isApprovedOrOwner(msgSender, offer.fromTokenId), "Caller is not owner nor approved");

            address fromAddress = ERC721.ownerOf(offer.fromTokenId);
            address toAddress = ERC721.ownerOf(offer.toTokenId);
            require(fromAddress != toAddress, "The owner is the same");

            if (_receivedOffers[offer.fromTokenId].contains(offer.toTokenId) &&
                _sentOffers[offer.toTokenId].contains(offer.fromTokenId)) {
                // approved -> swap tokens
                _safeTransfer(toAddress, fromAddress, offer.toTokenId, "");
                _safeTransfer(fromAddress, toAddress, offer.fromTokenId, "");
            } else {
                // add an offer
                _sentOffers[offer.fromTokenId].add(offer.toTokenId);
                _receivedOffers[offer.toTokenId].add(offer.fromTokenId);
            }
        }
    }
    
    // cancel swaps
    function cancelSwapOffers(SwapOffer[] calldata offers) public nonReentrant {
        address msgSender = _msgSender();

        for (uint i = 0; i < offers.length; ++i) {
            SwapOffer memory offer = offers[i];

            bool isApproved = false;
            if (_exists(offer.fromTokenId)) {
                isApproved = isApproved || _isApprovedOrOwner(msgSender, offer.fromTokenId);
            }
            if (_exists(offer.toTokenId)) {
                isApproved = isApproved || _isApprovedOrOwner(msgSender, offer.toTokenId);
            }

            require(isApproved, "Can't cancel the offer");

            // remove the offer
            _sentOffers[offer.fromTokenId].remove(offer.toTokenId);
            _receivedOffers[offer.toTokenId].remove(offer.fromTokenId);
        }
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override
    {
        super._beforeTokenTransfer(from, to, tokenId);

        // let's save some gas
        if (from != address(0)) {
            // delete all requests sent by a previous owner
            EnumerableSet.UintSet storage sentOffers = _sentOffers[tokenId];
            uint256 sentOffersCount = sentOffers.length();

            for (uint i = 0; i < sentOffersCount; ++i) {
                uint256 toTokenId = sentOffers.at(i);
                _receivedOffers[toTokenId].remove(tokenId);
            }
            
            delete _sentOffers[tokenId];

            if (to != address(0)) {
                // delete all requests received to the token from the new owner
                EnumerableSet.UintSet storage receivedOffers = _receivedOffers[tokenId];
                uint256 receivedOffersCount = receivedOffers.length();

                if (receivedOffersCount > 0) {
                    uint tokensToRemove = 0;
                    uint256[] memory fromTokenIdsToRemove = new uint256[](receivedOffersCount);

                    for (uint i = 0; i < receivedOffersCount; ++i) {
                        uint256 fromTokenId = receivedOffers.at(i);

                        if (_exists(fromTokenId)) {
                            address fromTokenOwner = ERC721.ownerOf(fromTokenId);
                            if (fromTokenOwner == to) {
                                fromTokenIdsToRemove[tokensToRemove] = fromTokenId;
                                ++tokensToRemove;
                            }
                        }
                    }

                    for (uint i = 0; i < tokensToRemove; ++i) {
                        uint256 fromTokenId = fromTokenIdsToRemove[i];

                        _receivedOffers[tokenId].remove(fromTokenId);
                        _sentOffers[fromTokenId].remove(tokenId);
                    }
                }
            } else {
                delete _receivedOffers[tokenId];
            }
        }
    }

    // ========== HELPERS ==========
    
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory byteStr = bytes(str);
        bytes memory resultStr = new bytes(byteStr.length);

        for (uint i = 0; i < byteStr.length; ++i) {
            if ((uint8(byteStr[i]) >= 65) && (uint8(byteStr[i]) <= 90)) { // uppercase
                resultStr[i] = bytes1(uint8(byteStr[i]) + 32);
            } else {
                resultStr[i] = byteStr[i];
            }
        }

        return string(resultStr);
    }

    function validateName(string memory str) public pure returns (bool) {
        bytes memory byteStr = bytes(str);

        if (byteStr.length < 1 || byteStr.length > 30) return false;
        if (byteStr[0] == 0x20) return false;
        if (byteStr[byteStr.length - 1] == 0x20) return false;

        bytes1 lastCh = byteStr[0];

        for (uint i = 0; i < byteStr.length; ++i) {
            bytes1 ch = byteStr[i];

            if (ch == 0x20 && lastCh == 0x20) return false; // double space

            if (
                !(ch >= 0x30 && ch <= 0x39) && // 0-9
                !(ch >= 0x41 && ch <= 0x5A) && // A-Z
                !(ch >= 0x61 && ch <= 0x7A) && // a-z
                !(ch == 0x20) // space
            )
                return false;

            lastCh = ch;
        }

        return true;
    }
}
