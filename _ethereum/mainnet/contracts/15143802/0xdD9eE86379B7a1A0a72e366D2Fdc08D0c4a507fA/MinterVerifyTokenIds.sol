// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./draft-EIP712.sol";
import "./SafeERC20.sol";

abstract contract IERC721 {
    function mint(address to, uint quantity) external virtual;

    function ownerOf(uint tokenId) external view virtual returns (address);
}

contract MinterVerifyTokenIds is Ownable, EIP712 {
    using SafeERC20 for IERC20;
    IERC721 public erc721;
    bytes32 public constant MINTER_TYPEHASH = keccak256("Mint(address to,uint256[] tokenIds,uint256 nonce)");

    address public signerAddress;
    bool public publicMint;
    mapping(bytes32 => bool) public signatureUsed;
    mapping(uint => bool) public claimed;
    modifier requiresSignature(
        bytes calldata signature,
        uint[] memory tokenIds,
        uint nonce
    ) {
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.

        bytes32 structHash = keccak256(abi.encode(MINTER_TYPEHASH, msg.sender, keccak256(abi.encodePacked(tokenIds)), nonce));
        bytes32 digest = _hashTypedDataV4(structHash); /*Calculate EIP712 digest*/
        require(!signatureUsed[digest], "signature used");
        signatureUsed[digest] = true;
        for (uint i = 0; i < tokenIds.length; i++) {
            require(claimed[tokenIds[i]] == false, "tokenId already claimed");
            claimed[tokenIds[i]] = true;
        }
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = ECDSA.recover(digest, signature);
        require(signerAddress == recoveredAddress, "Invalid Signature");
        _;
    }

    constructor(IERC721 _erc721, address _signer) EIP712("PandamoniumMinter", "1") {
        erc721 = _erc721;
        signerAddress = _signer;
    }

    function setNFT(IERC721 erc721_) public onlyOwner {
        erc721 = erc721_;
    }

    function setPublicMint(bool onOrOff) public onlyOwner {
        publicMint = onOrOff;
    }

    function setSignerAddress(address _newSigner) public onlyOwner {
        signerAddress = _newSigner;
    }

    function mintPublic(uint _quantity) public {
        require(publicMint, "Public mint is not active");
        erc721.mint(msg.sender, _quantity);
    }

    function mint(uint[] memory _tokenIds, uint _nonce, bytes calldata _signature) public requiresSignature(_signature, _tokenIds, _nonce) {
        erc721.mint(msg.sender, _tokenIds.length);
    }
}
