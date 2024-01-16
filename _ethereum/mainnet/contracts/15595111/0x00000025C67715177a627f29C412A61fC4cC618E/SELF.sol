// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract SELF is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) public minterAddresses;
    address public signerAddress;
    string private baseUri;
    uint256 public maxSupply;
    uint256 public mintFee;

    constructor(
        string memory _baseUri,
        address _signerAddress,
        address _owner,
        uint256 _maxSupply,
        uint256 _mintFee
    ) ERC721("SELF", "SELF") {
        baseUri = _baseUri;
        signerAddress = _signerAddress;
        maxSupply = _maxSupply;
        mintFee = _mintFee;
        _transferOwnership(_owner);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function safeMint(bytes memory signature) public payable {
        uint256 tokenId = _tokenIdCounter.current();

        require(msg.value == mintFee, "Check the fee");
        require(!minterAddresses[msg.sender], "Only once");
        require(tokenId + 1 <= maxSupply, "Maximum nfts minted");
        require(source(signature) == signerAddress, "Signature incorrect");
        _tokenIdCounter.increment();
        minterAddresses[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
    }

    function mintQuantity() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    function changeSignerAddress(address _address) public onlyOwner {
        signerAddress = _address;
    }

    function setMintFee(uint256 _mintFee) public onlyOwner {
        mintFee = _mintFee;
    }

    function source(bytes memory signature) private view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked("PRB", toString(abi.encodePacked(msg.sender)))
        );
        return recoverAddress(hash, signature);
    }

    function isMintable(address[] memory addresses) public view returns (bool) {
        uint256 tokenId = _tokenIdCounter.current();

        for (uint256 i = 0; i < addresses.length; i++) {
            if (minterAddresses[addresses[i]] == true) {
                return false;
            }
        }
        if (tokenId + 1 > maxSupply) {
            return false;
        }
        return true;
    }

    function toString(bytes memory data) private pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function recoverAddress(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        if (signature.length != 65) {
            return (address(0));
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        return ecrecover(hash, v, r, s);
    }
}
