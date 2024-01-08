// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./TokenHolder.sol";
import "./INftRandomness.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";

contract FusionNft is ERC721Enumerable, Ownable, TokenHolder {
    // events
    event PaymentReceived(address from, uint256 amount);
    event NftMinted(address to, uint16 tokenId);

    // constants
    uint16 private constant _maxNfts = 15000;
    uint16 private constant _maxOwnerMint = 200; // 100 + 100 specials
    uint8 private constant _maxLevel = 3;
    uint16 private constant _firstMintDiscountAmount = 1000; // first x nfts get a discount
    uint256 private constant _firstMintDiscountPrice = 30000000000000000; // 0.03 ETH;
    uint256 private constant _mintPrice = 50000000000000000; // 0.05 ETH
    uint8[] private _traitVariations = [72, 12, 27, 19, 29, 28, 17, 21]; // maximum different types of each trait, without level (first) and special (last)

    // counter
    uint16 private _tokenId = 0;
    uint16 private _minted = 0;
    uint16 private _ownerMinted = 0;
    uint16 private _fused = 0;
    uint8 private _specialId = 0;

    mapping (uint16 => Traits) private _tokenIdToTraits;
    string private _baseTokenURI;
    INftRandomness private _randGen;
    bool private _isMintingAndFusingPaused = false;
    mapping (bytes32 => bool) private _existingTraitHashes;

    struct Traits {
        uint8 level;
        uint8 board;
        uint8 shell;
        uint8 eyes;
        uint8 mouth;
        uint8 skin;
        uint8 head;
        uint8 jewellery;
        uint8 shoes;
        uint8 special;
    }

    constructor (string memory name, string memory symbol, string memory baseURI, address randGenContract) ERC721(name, symbol) {
        setRandGenInternal(randGenContract);
        setBaseURI(baseURI);
    }

    modifier mintingAndFusingNotPaused() {
        require(!_isMintingAndFusingPaused, "F11");
        _;
    }

    function getTraitsHash(Traits memory traits) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(traits.level, traits.board, traits.shell, traits.eyes, traits.mouth, traits.skin, traits.head, traits.jewellery, traits.shoes));
    }

    function setRandGen(address randGenContract) external onlyOwner {
        setRandGenInternal(randGenContract);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, "contractMetadata"))
        : '';
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function stats() external view returns (uint16[] memory) {
        uint16[] memory res = new uint16[](4);
        res[0] = _minted;
        res[1] = _ownerMinted;
        res[2] = _fused;
        res[3] = uint16(totalSupply());
        return res;
    }

    function setRandGenInternal(address randGenContract) internal {
        uint codeLength;
        assembly {
            codeLength := extcodesize(randGenContract)
        }
        require(codeLength > 0, "F1");
        _randGen = INftRandomness(randGenContract);
    }

    function mint(address newOwner, uint16 amount) external payable mintingAndFusingNotPaused {
        require(_minted + amount <= _maxNfts - _maxOwnerMint, "F8");
        require(amount > 0, "F2");
        require(amount <= 5, "F3");
        require(msg.value >= getMintPrice(amount), "F4");
        for (uint16 i = 0; i < amount; i++) {
            _safeMint(newOwner, _tokenId);
            generateNewTraits(newOwner);
            emit NftMinted(newOwner, _tokenId);
            _minted ++;
            _tokenId ++; // has to be the last call in this function/loop
        }
    }

    function ownerMint(address newOwner, uint16 amount, bool special) external onlyOwner mintingAndFusingNotPaused {
        require(_ownerMinted + amount <= _maxOwnerMint, "F9");
        require(amount > 0, "F2");
        require(amount <= 5, "F3");
        for (uint16 i = 0; i < amount; i++) {
            _safeMint(newOwner, _tokenId);
            if (special) {
                saveNewSpecialTraits();
            } else {
                generateNewTraits(newOwner);
            }
            emit NftMinted(newOwner, _tokenId);
            _ownerMinted ++;
            _tokenId ++; // has to be the last call in this function/loop
        }
    }

    function getMintPrice(uint16 amount) internal view returns (uint256) {
        uint256 basePrice = _mintPrice;
        if (_minted < _firstMintDiscountAmount) {
            basePrice = _firstMintDiscountPrice;
        }
        if (amount == 1) {
            return basePrice;
        } else if (amount > 1 && amount <= 3) {
            return basePrice * 9 / 10 * amount;
        } else {
            return basePrice * 8 / 10 * amount;
        }
    }

    function fusion(address newOwner, uint16 first, uint16 second) external mintingAndFusingNotPaused {
        require(_tokenIdToTraits[first].level == _tokenIdToTraits[second].level, "F5");
        require(ownerOf(first) == ownerOf(second), "F6");
        require(ownerOf(first) == msg.sender, "F7");
        require(_tokenIdToTraits[first].level < _maxLevel, "F10");
        _safeMint(newOwner, _tokenId);
        generateFusionTraits(newOwner, first, second);
        emit NftMinted(newOwner, _tokenId);
        _burn(first);
        _burn(second);
        delete _tokenIdToTraits[first];
        delete _tokenIdToTraits[second];
        _fused ++;
        _tokenId ++; // has to be the last call in this function
    }

    function generateNewTraits(address newOwner) internal {
        bool uniqueTraitHashFound = false;
        Traits memory newTraits;
        bytes32 traitsHash;
        for (uint i = 0; i < 3; i++) {
            uint8[] memory rand = _randGen.getNewTraits(newOwner, _tokenId + uint16(i) + uint16(newTraits.board)); // random numbers between 0 and 255 // board trait is used to prevent subsequent clashes, is 0 on first try
            newTraits = Traits(
                1, // level
                rand[0] % _traitVariations[0],
                rand[1] % _traitVariations[1],
                rand[2] % _traitVariations[2],
                rand[3] % _traitVariations[3],
                rand[4] % _traitVariations[4],
                rand[5] < 29 ? 0 : rand[5] % _traitVariations[5], // ~15% #0 // < (<TARGET_PERCENTAGE_OF_0>-1/<TRAIT_VARIATIONS>)*<MAX_RAND_IND> -> < (0,1-1/28)*255
                rand[6] < 87 ? 0 : rand[6] % _traitVariations[6], // ~40% #0
                rand[7] < 26 ? 0 : rand[7] % _traitVariations[7], // ~15% #0
                0 // special
            );
            traitsHash = getTraitsHash(newTraits);
            uniqueTraitHashFound = !_existingTraitHashes[traitsHash];
            if (uniqueTraitHashFound) {
                break;
            }
        }
        require(uniqueTraitHashFound, "F13");
        _tokenIdToTraits[_tokenId] = newTraits;
        _existingTraitHashes[traitsHash] = true;
    }

    function saveNewSpecialTraits() internal {
        _specialId ++;
        require(_specialId < 101, "F12"); // max 100 specials, 1 - 100
        Traits memory newTraits = Traits(
            3,
            100, // chosen to be different from actual trait possibilities
            100,
            100,
            100,
            100,
            100,
            100,
            100,
            _specialId // special, 1 - 100
        );
        _tokenIdToTraits[_tokenId] = newTraits;
    }

    function generateFusionTraits(address newOwner, uint16 firstTokenId, uint16 secondTokenId) internal {
        bool uniqueTraitHashFound = false;
        Traits memory newTraits;
        bytes32 traitsHash;
        uint8[] memory firstArr = getTraits(firstTokenId);
        uint8[] memory secondArr = getTraits(secondTokenId);
        for (uint i = 0; i < 3; i++) {
            uint8[] memory newFusionTraits = _randGen.getFusionTraits(newOwner, _tokenId + uint16(i) + uint16(newTraits.board), firstArr, secondArr); // board trait is used to prevent subsequent clashes, is 0 on first try
            newTraits = Traits(
                newFusionTraits[0],
                newFusionTraits[1],
                newFusionTraits[2],
                newFusionTraits[3],
                newFusionTraits[4],
                newFusionTraits[5],
                newFusionTraits[6],
                newFusionTraits[7],
                newFusionTraits[8],
                newFusionTraits[9]
            );
            traitsHash = getTraitsHash(newTraits);
            uniqueTraitHashFound = !_existingTraitHashes[traitsHash];
            if (uniqueTraitHashFound) {
                break;
            }
        }
        require(uniqueTraitHashFound, "F13");
        _tokenIdToTraits[_tokenId] = newTraits;
        _existingTraitHashes[traitsHash] = true;
    }

    function getTraits(uint16 tokenId) public view returns (uint8[] memory) {
        uint8[] memory res = new uint8[](_traitVariations.length + 2); // +2 is because level and special is not mapped in _traitVariations
        Traits memory traits = _tokenIdToTraits[tokenId];
        res[0] = traits.level;
        res[1] = traits.board;
        res[2] = traits.shell;
        res[3] = traits.eyes;
        res[4] = traits.mouth;
        res[5] = traits.skin;
        res[6] = traits.head;
        res[7] = traits.jewellery;
        res[8] = traits.shoes;
        res[9] = traits.special;
        return res;
    }

    function tokenOfOwner(address owner) external view returns (uint16[] memory) {
        uint16 tokenCount = uint16(balanceOf(owner));

        if (tokenCount == 0) {
            return new uint16[](0);
        } else {
            uint16[] memory result = new uint16[](tokenCount);

            for (uint16 index = 0; index < tokenCount; index++) {
                result[index] = uint16(tokenOfOwnerByIndex(owner, index));
            }
            return result;
        }
    }

    function invertMintingAndFusingPauseState() public onlyOwner {
        _isMintingAndFusingPaused = !_isMintingAndFusingPaused;
    }


    function isMintingAndFusingPaused() external view returns (bool) {
        return _isMintingAndFusingPaused;
    }

    function payout(address payable receiver, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "AM8");
        (bool payoutSuccess, ) = receiver.call{value: amount}("");
        require(payoutSuccess, "OT15");
    }

    receive () external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }
}

