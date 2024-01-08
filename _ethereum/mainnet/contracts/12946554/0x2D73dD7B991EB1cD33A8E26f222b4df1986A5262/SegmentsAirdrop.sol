//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IPiece.sol";
import "./IMillionPieces.sol";


/// @title Smart contract which will distribute segments to provided users
/// @author Ararat Tonoyan
contract SegmentsAirdrop is Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    address public millionPiecesSigner;

    IPiece public pieceToken;
    IMillionPieces public pieceNft;

    mapping(address => mapping(uint256 => bool)) public nonces;

    event NewMint(address receiver, uint256 tokenId);
    event PieceMinted(address receiver, uint256 tokenId);
    event NonceUsed(address receiver, uint256 nonce);

    //  ----------------------------
    //  CONSTRUCTOR
    //  ----------------------------

    constructor (address _millionPiecesSigner, IPiece _pieceToken, IMillionPieces _pieceNft) public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        pieceNft = _pieceNft;
        pieceToken = _pieceToken;
        millionPiecesSigner = _millionPiecesSigner;
    }

    //  ----------------------------
    //  SETTERS
    //  ----------------------------

    function claim(
        uint256 nonce,
        address owner,
        uint256[] calldata tokens,
        uint256 pieceAmount,
        bytes calldata signature
    ) external {
        require(owner != address(0) && owner == msg.sender, 'claim: Not authorized!');
        require(nonces[msg.sender][nonce] == false, 'claim: Already claimed this segments!');

        address signer = getSignerAddress(nonce, owner, tokens, pieceAmount, signature);
        require(signer != address(0) && signer == millionPiecesSigner, 'claim: Invalid signature!');

        nonces[msg.sender][nonce] = true;

        _mintSegments(msg.sender, tokens);
        _mintPieces(msg.sender, pieceAmount);

        emit NonceUsed(msg.sender, nonce);
    }

    function getSignerAddress(
        uint256 nonce,
        address owner,
        uint256[] calldata tokens,
        uint256 pieceAmount,
        bytes calldata signature
    ) public pure returns (address) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(
                nonce,
                owner,
                tokens,
                pieceAmount
            )
        );

        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        return ECDSA.recover(message, signature);
    }

    //  ----------------------------
    //  PRIVATE
    //  ----------------------------

    function _mintSegments(address receiver, uint256[] memory tokens) private {
        uint256 tokensLength = tokens.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            uint256 tokenId = tokens[i];

            // Mint if token not exist
            if (!pieceNft.exists(tokenId)) {
                pieceNft.mintTo(receiver, tokenId);
                emit NewMint(msg.sender, tokenId);
            }
        }
    }

    function _mintPieces(address receiver, uint256 amount) private {
        pieceToken.mint(receiver, amount);

        emit PieceMinted(receiver, amount);
    }
}