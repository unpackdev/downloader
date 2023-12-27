// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./ERC1155.sol";

import "./IERC165.sol";
import "./IERC1155.sol";
import "./IMetadataRenderer.sol";
import "./IERC4906.sol";

contract Stickers is ERC1155, Ownable {
    address public signer;
    address public metadataRenderer;
    uint256 public mintEnd;
    mapping(bytes32 => bool) _hasMinted;

    error InvalidSignature();
    error MintClosed();
    error MintedAlready();

    constructor() {
        _initializeOwner(tx.origin);
    }

    function name() public view virtual returns (string memory) {
        return "!fundrop Stickers";
    }

    function _packRecipientAndRound(address _address, uint16 _round) internal pure returns (bytes32) {
        return (bytes32(uint256(uint160(_address))) << 96) | bytes32(uint256(_round));
    }

    function mint(uint256[] calldata tokens, uint256[] calldata amounts, uint16 round, bytes calldata signature)
        public
        payable
    {
        bytes32 packedRecipientAndRound = _packRecipientAndRound(msg.sender, round);
        if (block.timestamp > mintEnd) revert MintClosed();
        if (_hasMinted[packedRecipientAndRound]) revert MintedAlready();
        address recovered =
            ECDSA.tryRecoverCalldata(keccak256(abi.encodePacked(msg.sender, round, tokens, amounts)), signature);
        if (recovered != signer) revert InvalidSignature();
        _hasMinted[packedRecipientAndRound] = true;
        _batchMint(msg.sender, tokens, amounts, "");
    }

    function adminMint(address to, uint256[] calldata tokens, uint256[] calldata amounts) public onlyOwner {
        _batchMint(to, tokens, amounts, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return IMetadataRenderer(metadataRenderer).tokenURI(id);
    }

    // Admin functions

    function setMetadataRenderer(address _metadataRenderer) public onlyOwner {
        metadataRenderer = _metadataRenderer;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setMintEnd(uint256 _mintEnd) public onlyOwner {
        mintEnd = _mintEnd;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC4906).interfaceId;
    }
}
