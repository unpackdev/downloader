// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./IERC721.sol";

import "./IOGCardDescriptor.sol";
import "./IENSHelpers.sol";
import "./ICryptoPunks.sol";

contract OGCards is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeMath for uint8;

    address private immutable _ogCardDescriptor;
    address private immutable _ensHelpers;
    address private immutable _cryptoPunks; // 0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb
    address private immutable _animalColoringBook; // 0x69c40e500b84660cb2ab09cb9614fa2387f95f64
    address private immutable _purrnelopes; // 0x9759226b2f8ddeff81583e244ef3bd13aaa7e4a1

    bool public publicClaimOpened = false;

    uint256 public baseCardsLeft = 250;
    uint256 public punkCardsLeft = 100;
    uint256 public acbCardsLeft = 30;
    uint256 public purrCardsLeft = 50;
    uint256 public gaCardsLeft = 50;

    uint256 private _nonce = 1234;

    mapping(address => bool) public hasClaimedBase;
    mapping(uint256 => bool) public punkClaimed;
    mapping(uint256 => bool) public acbClaimed;
    mapping(uint256 => bool) public purrClaimed;

    struct Card {
        bool isGiveaway;
        uint8 borderType;
        uint8 transparencyLevel;
        uint8 maskType;
        uint256 dna;
        uint256 mintTokenId;
        address[] holders;
    }

    mapping(uint256 => Card) public cardInfo;

    mapping(uint256 => mapping(address => bool)) private _alreadyHoldToken;
    mapping(address => string) private _ogName;

    // Events
    event OGCardMinted(uint256 tokenId);
    event OGAdded(address indexed og, string name);
    event OGRenamed(address indexed og, string name);
    event OGRemoved(address indexed og);

    constructor(address _cryptoPunks_, address _animalColoringBook_, address _purrnelopes_, address _ensHelpers_, address _ogCardDescriptor_) ERC721("OGCards", "OGC") {
        _cryptoPunks = _cryptoPunks_;
        _animalColoringBook = _animalColoringBook_;
        _ensHelpers = _ensHelpers_;
        _ogCardDescriptor = _ogCardDescriptor_;
        _purrnelopes = _purrnelopes_;

        // Claim 10 base cards
        for (uint8 i=0; i<10; i++) {
            _claim(msg.sender, 0, 0);
        }
        // Claim 4 giveaway cards
        for (uint8 i=0; i<4; i++) {
            _claim_(msg.sender, i, 0, true);
        }
    }

    function cardDetails(uint256 tokenId) external view returns (Card memory) {
        require(_exists(tokenId), "OGCards: This token doesn't exist");
        return cardInfo[tokenId];
    }

    // save bytecode by removing implementation of unused method
    function baseURI() public pure returns (string memory) {}

    function switchClaimOpened() external onlyOwner {
        publicClaimOpened = !publicClaimOpened;
    }

    // Withdraw all funds in the contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    modifier remainsSupply(uint256 cardsLeft) {
        require(cardsLeft > 0, "OGCards: no more cards of this type left");
        _;
    }

    modifier claimOpened() {
        require(publicClaimOpened, "OGCards: claim is not opened yet");
        _;
    }

    // Claim OGCards
    function claim() external claimOpened remainsSupply(baseCardsLeft) {
        require(!hasClaimedBase[msg.sender], "OGCards: you already claimed a base card");
        hasClaimedBase[msg.sender] = true;
        baseCardsLeft--;
        _claim(msg.sender, 0, 0);
    }

    function punkClaim(uint256 punkId) external claimOpened remainsSupply(punkCardsLeft) {
        require(msg.sender == ICryptoPunks(_cryptoPunks).punkIndexToAddress(punkId), "OGCards: you are not the owner of this punk");
        require(!punkClaimed[punkId], "OGCards: this punk already claimed his card");
        
        punkClaimed[punkId] = true;
        punkCardsLeft--;
        _claim(msg.sender, 1, punkId);
    }

    function acbClaim(uint256 acbId) external claimOpened remainsSupply(acbCardsLeft) {
        require(msg.sender == IERC721(_animalColoringBook).ownerOf(acbId), "OGCards: you are not the owner of this ACB");
        require(!acbClaimed[acbId], "OGCards: this ACB already claimed his card");

        acbClaimed[acbId] = true;
        acbCardsLeft--;
        _claim(msg.sender, 2, acbId);
    }

    function purrClaim(uint256 purrId) external claimOpened remainsSupply(purrCardsLeft) {
        require(msg.sender == IERC721(_purrnelopes).ownerOf(purrId), "OGCards: you are not the owner of this ACB");
        require(!purrClaimed[purrId], "OGCards: this Purrnelopes already claimed his card");

        purrClaimed[purrId] = true;
        purrCardsLeft--;
        _claim(msg.sender, 3, purrId);
    }

    function giveawayClaim(address to, uint8 maskType) external remainsSupply(gaCardsLeft) onlyOwner {
        gaCardsLeft--;
        _claim_(to, maskType, 0, true);
    }

    // List every tokens an owner owns
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // OGs
    function addOG(address _og, string memory _name) public onlyOwner {
        require(bytes(_name).length > 0, "OGCards: You must define a name for this OG");
        require(_og != address(0), "OGCards: Invalid address");

        if (isOG(_og)) {
            _ogName[_og] = _name;
            emit OGAdded(_og, _name);
        } else {
            _ogName[_og] = _name;
            emit OGRenamed(_og, _name);
        }
    }

    function addOGs(address[] memory _ogs, string[] memory _names) external onlyOwner {
        require(_ogs.length == _names.length, "OGCards: Invalid array length");
        
        for (uint256 i=0; i<_ogs.length; i++) {
            addOG(_ogs[i], _names[i]);
        }
    }

    function removeOG(address _og) external onlyOwner {
        require(isOG(_og), "OGCards: This OG doesn't exist");
        
        delete _ogName[_og];
        emit OGRemoved(_og);
    }

    function isOG(address _og) public view returns (bool) {
        return bytes(_ogName[_og]).length > 0;
    }

    function ogName(address _og) public view returns (string memory) {
        return _ogName[_og];
    }

    function holderName(address _holder) public view returns (string memory) {
        string memory ensDomain = IENSHelpers(_ensHelpers).getEnsDomain(_holder);
        if (isOG(_holder)) {
            return ogName(_holder);
        } else if (bytes(ensDomain).length != 0) {
            return ensDomain;
        }
        return _toAsciiString(_holder);
    }

    function ogHolders(uint256 tokenId)
        public
        view
        returns (address[] memory, string[] memory)
    {
        require(_exists(tokenId), "OGCards: This token doesn't exist");
        Card memory card = cardInfo[tokenId];
        
        uint256 count = 0;
        address[] memory ogs = new address[](card.holders.length);
        string[] memory names = new string[](card.holders.length);
        for (uint256 i = 0; i < card.holders.length; i++) {
            address holder = card.holders[i];
            if (isOG(holder)) {
                ogs[count] = holder;
                string memory name = holderName(holder);
                names[count] = name;
                count++;
            }
        }

        address[] memory trimmedOGs = new address[](count);
        string[] memory trimmedNames = new string[](count);
        for (uint j = 0; j < count; j++) {
            trimmedOGs[j] = ogs[j];
            trimmedNames[j] = names[j];
        }
        return (trimmedOGs, trimmedNames);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "OGCards: This token doesn't exist");
        return IOGCardDescriptor(_ogCardDescriptor).tokenURI(address(this), tokenId);
    }

    // Before any transfer, add the new owner to the holders list of this token
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // Save the holder only once per token
        if (!_alreadyHoldToken[tokenId][to]) {
            cardInfo[tokenId].holders.push(to);
            _alreadyHoldToken[tokenId][to] = true;
        }
    }

    function _claim(address _to, uint8 maskType, uint256 mintTokenId)
        internal
    {
        _claim_(_to, maskType, mintTokenId, false);
    }

    function _claim_(address _to, uint8 maskType, uint256 mintTokenId, bool isGiveaway)
        internal
    {
        uint256 mintIndex = totalSupply();

        uint256 dna = _random(mintIndex, 100000);

        uint256 randomBorder = _random(mintIndex, 101);
        uint8 borderType = (
         (isGiveaway ? 0 : 
            (randomBorder < 50 ? 1 : // 50%
                (randomBorder < 80 ? 2 : // 30%
                    (randomBorder < 94 ? 3 : // 14%
                        (randomBorder < 99 ? 4 : 5)))))); // 5% && 1%

        uint256 randomTransparency = _random(mintIndex, 6);
        uint8 transparencyLevel = uint8(100 - randomTransparency);

        cardInfo[mintIndex].isGiveaway = isGiveaway;
        cardInfo[mintIndex].borderType = borderType;
        cardInfo[mintIndex].transparencyLevel = transparencyLevel;
        cardInfo[mintIndex].maskType = maskType;
        cardInfo[mintIndex].dna = dna;
        cardInfo[mintIndex].mintTokenId = mintTokenId;

        _safeMint(_to, mintIndex);

        emit OGCardMinted(mintIndex);
    }

    function _toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);            
        }
        string memory stringAddress = string(abi.encodePacked('0x',s));
        return _getSlice(0, 8, stringAddress);
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _getSlice(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(end-begin);
        for(uint i=0;i<=end-begin-1;i++){
            a[i] = bytes(text)[i+begin];
        }
        return string(a);
    }

    function _random(uint256 _salt, uint256 _limit) internal returns (uint) {
        uint256 r = (uint256(keccak256(abi.encodePacked(blockhash(block.number-1), block.timestamp, msg.sender, _nonce, _salt)))) % _limit;
        _nonce++;
        return r;
    }
}