// ██   ██    ███    ███    ██  ██████     ███     ██████ 
//  ██ ██   ██   ██  ████   ██  ██   ██  ██   ██  ██    ██
//   ███    ███████  ██ ██  ██  ██   ██  ███████  ██    ██
//  ██ ██   ██   ██  ██  ██ ██  ██   ██  ██   ██  ██    ██
// ██   ██  ██   ██  ██    ███  ██████   ██   ██   ██████

// ██████████
// ██  ████  
// ██████    
// ██████    
// ████    ██
// ██        

// −✕⦿  ✳︎  ⨰  ∟⧺¬  ✕○◻︎∷※  -xo

// the way of xandao has a north star to help humanity live healthier and happier
// across body, mind, environment, community, and sprit. 
// -xo

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;                

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable2Step.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./XandaoMeta.sol";
import "./XandaoTypes.sol";

contract TheXanDAO is ERC721, ERC721Burnable, Ownable2Step, XandaoMeta {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _xn;
    mapping(string => uint256) private _xnToTokenId;
    mapping(uint256 => TokenInfo) public tokens;
    uint256 public tokensCount;
    string[] XN_VERSIONS = [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
        "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
        "u", "v", "w", "x", "y", "z", "aa", "ab", "ac", "ad",
        "ae", "af", "ag", "ah", "ai", "aj"
    ];

    bool lock = false;

    uint256 constant DAO_SHARE = 90;
    address private constant DAO_ADDRESS = 0x00643E0dA7afE48df308ACD428CCDAC76F837c06;
    address private constant OPS_ADDRESS = 0x8e3DeC81106624B655DcFaD6daE62f0eF5246590;

    event TokenMinted(address indexed creator, uint256 tokenId, string xn);
    event TokenUpgraded(address indexed creator, uint256 tokenId, string xn, uint256 originTokenId);

    // mapping(uint256 => uint256) private _tokenIdLenToMintPrice;
    mapping(uint8 => uint64) private _tokenIdLenToMintPrice;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        // _xn.increment();
        // Initialize the token prices by token ID length
        _tokenIdLenToMintPrice[36] = 0.006 ether;
        _tokenIdLenToMintPrice[35] = 0.007 ether;
        _tokenIdLenToMintPrice[34] = 0.009 ether;
        _tokenIdLenToMintPrice[33] = 0.011 ether;
        _tokenIdLenToMintPrice[32] = 0.013 ether;
        _tokenIdLenToMintPrice[31] = 0.016 ether;
        _tokenIdLenToMintPrice[30] = 0.020 ether;
        _tokenIdLenToMintPrice[29] = 0.024 ether;
        _tokenIdLenToMintPrice[28] = 0.029 ether;
        _tokenIdLenToMintPrice[27] = 0.035 ether;
        _tokenIdLenToMintPrice[26] = 0.043 ether;
        _tokenIdLenToMintPrice[25] = 0.053 ether;
        _tokenIdLenToMintPrice[24] = 0.064 ether;
        _tokenIdLenToMintPrice[23] = 0.078 ether;
        _tokenIdLenToMintPrice[22] = 0.095 ether;
        _tokenIdLenToMintPrice[21] = 0.116 ether;
        _tokenIdLenToMintPrice[20] = 0.141 ether;
        _tokenIdLenToMintPrice[19] = 0.172 ether;
        _tokenIdLenToMintPrice[18] = 0.209 ether;
        _tokenIdLenToMintPrice[17] = 0.255 ether;
        _tokenIdLenToMintPrice[16] = 0.311 ether;
        _tokenIdLenToMintPrice[15] = 0.379 ether;
        _tokenIdLenToMintPrice[14] = 0.461 ether;
        _tokenIdLenToMintPrice[13] = 0.562 ether;
        _tokenIdLenToMintPrice[12] = 0.684 ether;
        _tokenIdLenToMintPrice[11] = 0.834 ether;
        _tokenIdLenToMintPrice[10] = 1.016 ether;
        _tokenIdLenToMintPrice[9] = 1.237 ether;
        _tokenIdLenToMintPrice[8] = 1.507 ether;
        _tokenIdLenToMintPrice[7] = 1.836 ether;
        _tokenIdLenToMintPrice[6] = 2.237 ether;
        _tokenIdLenToMintPrice[5] = 2.725 ether;
        _tokenIdLenToMintPrice[4] = 3.319 ether;
        _tokenIdLenToMintPrice[3] = 4.043 ether;
        _tokenIdLenToMintPrice[2] = 4.925 ether;
        _tokenIdLenToMintPrice[1] = 6.000 ether;
        tokensCount = 0;
    }

    function getXN() public view returns(uint256) {
        return _xn.current();
    }

    function getAllTokenIds() public view returns (uint256[] memory){
        uint256[] memory ret = new uint256[](tokensCount);
        uint256 cur_xn = _xn.current();
        uint256 i = 0;
        for (uint256 xn = 0; xn < cur_xn; xn++) {
            for (uint8 j = 0; i < 36; j++) {
                string memory fullXn = generateFullXn(xn, XN_VERSIONS[j]);
                if (_xnToTokenId[fullXn] != 0) {
                    ret[i] = _xnToTokenId[fullXn];
                    i++;
                } else {
                    break;
                }
            }
        }
        return ret;
    }

    function getMintPrice(uint256 rawTokenId) public view returns (uint64) {
        (, uint8 tokenLen) = _checkTokenId(rawTokenId);
        uint64 mintPrice = _tokenIdLenToMintPrice[tokenLen];
        return mintPrice;
    }

    // send eth to dao.xandao.eth(90%) and pixels.xandao.eth(10%)
    function _shareIncome(uint256 amount) private {
        uint256 daoAmount = amount * DAO_SHARE / 100;
        payable(DAO_ADDRESS).transfer(daoAmount);
        payable(OPS_ADDRESS).transfer(amount - daoAmount);
    }

    function upgradeToken(
        uint256 rawTokenId,
        string memory description,
        string memory creatorName,
        uint256 rawOriginTokenId
    ) public payable {
        require(!lock);
        lock = true;
        uint256 descLen = bytes(description).length;
        require(
            descLen < 36 && descLen > 0,
            "Description must be between 1 and 36 characters"
        );

        uint256 nameLen = bytes(creatorName).length;
        require(
            nameLen < 36 && nameLen > 0,
            "Creator name must be between 1 and 36 characters"
        );

        (uint256 originTokenId, uint8 originTokenIdLen) = _checkTokenId(rawOriginTokenId);
        (uint256 tokenId, uint8 tokenIdLen) = _checkTokenId(rawTokenId);

        require(
            originTokenIdLen > tokenIdLen,
            "Tokens can only be upgraded"
        );

        uint64 mintPrice = _tokenIdLenToMintPrice[tokenIdLen] - _tokenIdLenToMintPrice[originTokenIdLen];
        require(
            msg.value >= mintPrice,
            "eth paid is less than the mint price"
        );

        require(
            _exists(originTokenId),
            "nonexistent original token"
        );

        require(
            ownerOf(originTokenId) == msg.sender,
            "not token owner"
        );

        // get origin XN by tokenId
        TokenInfo memory originTokenObj = tokens[originTokenId];

        // get new XN
        int256 idx = -1;
        for (int256 i = 0; i < 36; i++) {
            if (keccak256(abi.encodePacked(XN_VERSIONS[uint256(i)])) == keccak256(abi.encodePacked(originTokenObj.xnVersion))) {
                idx = i;
                break;
            }
        }

        uint256 xn = originTokenObj.xn; // keep origin token XN
        uint256 newIdx = uint256(idx + 1);

        string memory xnVersion;  // change XN version
        if (newIdx == 0) { // 'a'
            xnVersion = '';
        } else {
            xnVersion = XN_VERSIONS[newIdx];
        }
        string memory fullXn = generateFullXn(xn, xnVersion);
        tokensCount++;
        tokens[tokenId] = TokenInfo(description, msg.sender, creatorName, xn, xnVersion, originTokenId, false);
        _xnToTokenId[fullXn] = tokenId;
        _shareIncome(msg.value);
        _safeMint(msg.sender, tokenId);
        burn(originTokenId);
        tokens[originTokenId].burnStatus = true;
        emit TokenUpgraded(msg.sender, tokenId, fullXn, originTokenId);
        lock = false;
    }

    // Allows minting of a new NFT
    function mintToken(
        uint256 rawTokenId,
        string memory description,
        string memory creatorName
    ) public payable {
        require(!lock);
        lock = true;

        uint256 descLen = bytes(description).length;
        require(
            descLen < 36 && descLen > 0,
            "Description must be between 1 and 36 characters"
        );

        uint256 nameLen = bytes(creatorName).length;
        require(
            nameLen < 36 && nameLen > 0,
            "Creator name must be between 1 and 36 characters"
        );

        (uint256 tokenId, uint8 tokenLen) = _checkTokenId(rawTokenId);

        require(
            msg.value >= _tokenIdLenToMintPrice[tokenLen],
            "eth paid is less than the mint price"
        );

        //mint
        uint256 xn = _xn.current();
        string memory fullXn = xn.toString();
        tokensCount++;
        tokens[tokenId] = TokenInfo(description, msg.sender, creatorName, xn, "a", 0, false);
        _xnToTokenId[fullXn] = tokenId;
        _xn.increment();
        _shareIncome(msg.value);
        _safeMint(msg.sender, tokenId);
        emit TokenMinted(msg.sender, tokenId, fullXn);
        lock = false;
    }

    // for Opensea - it doesn't return the token URI of burned token.
    // TODO - review this behavior if we just keep all tokens 
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return generateTokenURI(tokenId, tokens[tokenId]);
    }

    // Returns the token URI even if it was burned.
    function tokenURIByTokenId(uint256 tokenId) public view returns (string memory) {
        require(
            tokens[tokenId].creator != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return generateTokenURI(tokenId, tokens[tokenId]);
    }

    function tokenURIByXN(string memory xn) public view returns (string memory) {
        require(
            _xnToTokenId[xn] != 0,
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256 tokenId = _xnToTokenId[xn];
        return generateTokenURI(tokenId, tokens[tokenId]);
    }

    function creatorOf(uint256 tokenId) public view returns (address) {
        require(
            _exists(tokenId),
            "ERC721Metadata: creator query for nonexistent token"
        );
        return tokens[tokenId].creator;
    }

    function isAvailable(uint256 tokenId) public view returns (bool) {
        return tokens[tokenId].creator == address(0);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "amount exceeds balance");
        payable(msg.sender).transfer(amount);
    }
}
