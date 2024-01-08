// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Math.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";

contract LoFiStargazer is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    IERC721Enumerable skylines;

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    string public animationURI;
    address payable admin;

    ProxyRegistry private _proxyRegistry;
    Counters.Counter private _tokenIds;

    mapping(uint256 => bytes32) bHash;
    mapping(uint256 => bool) claimedToken;

    constructor(
        string memory _name,
        string memory _symbol,
        address payable _admin,
        string memory _animationURI,
        address _skylines,
        address openseaProxyRegistry_
    ) ERC721(_name, _symbol) {
        admin = _admin;
        animationURI = _animationURI;
        skylines = IERC721Enumerable(_skylines);
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }
    }

    function freeClaim() public {
        uint256 bal = skylines.balanceOf(msg.sender);
        for (uint8 i = 0; i < bal; i++) {
            uint256 tokenId = skylines.tokenOfOwnerByIndex(msg.sender, i);
            if (claimedToken[tokenId]) {
                continue;
            }
            _mint(msg.sender, tokenId);
            bHash[tokenId] = bytes32(
                keccak256(abi.encodePacked(address(msg.sender), tokenId))
            );
            claimedToken[tokenId] = true;
        }
    }

    function canTokenClaim(uint256 _token) public view returns (bool) {
        return claimedToken[_token];
    }

    function purchased() public view returns(uint256) {
        return _tokenIds.current();
    }
    
    function mint(uint256 _amount) public payable {
        require(
            uint256(200000000000000000).mul(_amount) == msg.value,
            "Invalid value"
        );
        require(_amount <= 20, "Cannot mint more than 20 at a time");
        require(
            _tokenIds.current().add(_amount) <= 1111,
            "Mint exceeds max supply"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 newNftTokenId = _tokenIds.current().add(3333);
            _mint(msg.sender, newNftTokenId);
            bHash[newNftTokenId] = bytes32(
                keccak256(abi.encodePacked(address(msg.sender), newNftTokenId))
            );
        }
    }

    function setAnimationURI(string memory newAnimationURI) public onlyOwner {
        animationURI = newAnimationURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        string memory seed = bytes32ToString(bHash[_tokenId]);
        string memory baseColor = strSlice(59, 64, seed);
        string memory fg = baseColor;
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"',
                    uint2str(_tokenId),
                    '","animation_url":"',
                    string(abi.encodePacked(animationURI, seed)),
                    '","image_data":"',
                    baseImg(fg, getBG(baseColor)),
                    '"}'
                )
            );
    }

    function baseImg(string memory fg, string memory bg)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' width='512px' height='512px'>",
                    "<rect width='100%' height='100%' fill='",
                    bg,
                    "'/><text x='194' y='224' font-size='64' fill='#",
                    fg,
                    "'>LoFi</text>",
                    "<text x='134' y='288' font-size='64' fill='#",
                    fg,
                    "'>Stargazer</text><circle cx='20' cy='26' r='50' fill='#",
                    fg,
                    "'/><circle cx='100' cy='200' r='20' fill='#",
                    fg,
                    "'/><circle cx='88' cy='440' r='70' fill='#",
                    fg,
                    "'/><circle cx='277' cy='360' r='43' fill='#",
                    fg,
                    "'/><circle cx='433' cy='444' r='12' fill='#",
                    fg,
                    "'/><circle cx='376' cy='75' r='65' fill='#",
                    fg,
                    "'/><circle cx='475' cy='230' r='32' fill='#",
                    fg,
                    "'/></svg>"
                )
            );
    }

    function getBG(string memory _seedColor)
        internal
        pure
        returns (string memory)
    {
        string memory s1 = strSlice(1, 2, _seedColor);
        string memory s2 = strSlice(3, 4, _seedColor);
        string memory s3 = strSlice(5, 6, _seedColor);
        uint256 ss1 = fromHex(s1);
        uint256 ss2 = fromHex(s2);
        uint256 ss3 = fromHex(s3);

        uint256 i1 = ss1 ^ uint256(255);
        uint256 i2 = ss2 ^ uint256(255);
        uint256 i3 = ss3 ^ uint256(255);
        return
            string(
                abi.encodePacked(
                    "#",
                    toHexString(i1),
                    toHexString(i2),
                    toHexString(i3)
                )
            );
    }

    function withdraw(uint256 amount) external payable onlyOwner {
        require(amount <= address(this).balance);
        admin.transfer(amount);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);
        for (i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes32[i / 2] & 0x0f);
            uint8 _l = uint8(_bytes32[i / 2] >> 4);

            bytesArray[i] = toByte(_f);
            i = i + 1;
            bytesArray[i] = toByte(_l);
        }
        return string(bytesArray);
    }

    function toByte(uint8 _uint8) public pure returns (bytes1) {
        if (_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }

    function strSlice(
        uint256 begin,
        uint256 end,
        string memory text
    ) public pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint256 i = 0; i <= end - begin; i++) {
            a[i] = bytes(text)[i + begin - 1];
        }
        return string(a);
    }

    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
    }

    function fromHex(string memory s) public pure returns (uint256) {
        bytes memory ss = bytes(s);
        require(ss.length % 2 == 0);
        bytes memory r = new bytes(ss.length / 2);
        uint256 total;
        for (uint256 i = 0; i < ss.length / 2; ++i) {
            total += (fromHexChar(uint8(ss[2 * i])) *
                16 +
                fromHexChar(uint8(ss[2 * i + 1])));
        }
        return total;
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);

        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return

            address(proxyRegistry) != address(0) &&

            address(proxyRegistry.proxies(owner)) == operator;
    }

    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {

        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setOpenSeaRegistry(address proxyRegistryAddress)
        external
        onlyOwner
    {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
