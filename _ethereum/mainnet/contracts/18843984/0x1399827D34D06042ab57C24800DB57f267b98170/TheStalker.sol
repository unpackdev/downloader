// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// the stalker by int.art
// a permissionless collaboration program running on EVM.

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

import "./TheStalkerCommon.sol";

contract TheStalker is Ownable, ERC721A, ERC721AQueryable {
    struct Timestamps {
        uint128 mintStartTimestamp;
        uint128 mintEndTimestamp;
    }

    struct Token {
        bytes32 seed;
        ITheStalkerRenderer renderer;
        uint256 targetTokenId;
    }

    bool public isMintFinalised;
    ITheStalkerRenderer public defaultRenderer;
    ITheStalkerRenderer public launchRenderer;

    Timestamps public timestamps;

    mapping(uint256 => Token) public tokens;
    mapping(ITheStalkerRenderer => bool) public renderers;

    error MintIsNotOpen();
    error MintIsFinalised();
    error InvalidMintAmount();
    error InvalidAuthorisation();
    error InvalidRendererAuthorisation();
    error InvalidTokenRenderer();

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event TokenUpdate(
        uint256 _tokenId,
        ITheStalkerRenderer _renderer,
        uint256 _targetTokenId
    );
    event RendererAllowlistStatusUpdate(
        ITheStalkerRenderer _renderer,
        bool _isValid
    );
    event DefaultRendererUpdate(ITheStalkerRenderer _address);
    event LaunchRendererUpdate(ITheStalkerRenderer _address);
    event MintPeriodUpdate(uint256 _startTimesstamp, uint256 _endTimeStamp);

    constructor(
        ITheStalkerRenderer _defaultRenderer,
        ITheStalkerRenderer _launchRenderer
    ) Ownable(msg.sender) ERC721A("the stalker", "STAL") {
        defaultRenderer = _defaultRenderer;
        launchRenderer = _launchRenderer;
        renderers[_defaultRenderer] = true;
        renderers[_launchRenderer] = true;
        _mintStalker(10);
    }

    // CONTRACT OWNER

    function finaliseMint() public onlyOwner {
        isMintFinalised = true;
    }

    function updateMintStartAndEndTimestamps(
        uint128 _mintStartTimestamp,
        uint128 _mintEndTimestamp
    ) public onlyOwner {
        if (isMintFinalised) {
            revert MintIsFinalised();
        }
        timestamps.mintStartTimestamp = _mintStartTimestamp;
        timestamps.mintEndTimestamp = _mintEndTimestamp;
        emit MintPeriodUpdate(_mintStartTimestamp, _mintEndTimestamp);
    }

    function updateRendererAllowlistStatus(
        ITheStalkerRenderer rendererAddress,
        bool isValid
    ) public onlyOwner {
        renderers[rendererAddress] = isValid;
        emit RendererAllowlistStatusUpdate(rendererAddress, isValid);
        emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
    }

    function updateDefaultRenderer(
        ITheStalkerRenderer _defaultRenderer
    ) public onlyOwner {
        defaultRenderer = _defaultRenderer;
        emit DefaultRendererUpdate(_defaultRenderer);
        emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
    }

    function updateLaunchRenderer(
        ITheStalkerRenderer _launchRenderer
    ) public onlyOwner {
        launchRenderer = _launchRenderer;
        emit LaunchRendererUpdate(_launchRenderer);
        emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
    }

    function triggerBatchMetadataUpdate() public onlyOwner {
        emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
    }

    // PUBLIC MINT

    function isMintOpen() public view returns (bool) {
        Timestamps memory _timestamps = timestamps;
        return
            block.timestamp >= _timestamps.mintStartTimestamp &&
            block.timestamp <= _timestamps.mintEndTimestamp &&
            !isMintFinalised;
    }

    function mint(uint256 count) public {
        if (!isMintOpen()) {
            revert MintIsNotOpen();
        }
        uint256 mintedAmount = _numberMinted(msg.sender);
        unchecked {
            if (count == 0 || mintedAmount + count > 3) {
                revert InvalidMintAmount();
            }
        }
        _mintStalker(count);
    }

    function numberMinted(address _address) public view returns (uint256) {
        return _numberMinted(_address);
    }

    function currentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    // TOKEN OWNER

    function updateTokenRenderer(
        uint256 tokenId,
        ITheStalkerRenderer tokenRenderer
    ) public {
        if (msg.sender != ownerOf(tokenId)) {
            revert InvalidAuthorisation();
        }
        if (!renderers[tokenRenderer]) {
            revert InvalidTokenRenderer();
        }

        Token memory token = tokens[tokenId];
        bool canUpdateToken = tokenRenderer.canUpdateToken(
            msg.sender,
            tokenId,
            token.targetTokenId
        );

        if (!canUpdateToken) {
            revert InvalidRendererAuthorisation();
        }

        tokens[tokenId].renderer = tokenRenderer;
        _notifyTokenUpdate(tokenId, token);
    }

    function updateTokenTargetTokenId(
        uint256 tokenId,
        uint256 targetTokenId
    ) public {
        if (msg.sender != ownerOf(tokenId)) {
            revert InvalidAuthorisation();
        }

        Token memory token = tokens[tokenId];
        ITheStalkerRenderer tokenRenderer = _launchOrTokenRenderer(
            token.renderer
        );
        bool canUpdateToken = tokenRenderer.canUpdateToken(
            msg.sender,
            tokenId,
            targetTokenId
        );

        if (!canUpdateToken) {
            revert InvalidRendererAuthorisation();
        }

        tokens[tokenId].targetTokenId = targetTokenId;
        _notifyTokenUpdate(tokenId, token);
    }

    function updateToken(
        uint256 tokenId,
        ITheStalkerRenderer tokenRenderer,
        uint256 targetTokenId
    ) public {
        if (msg.sender != ownerOf(tokenId)) {
            revert InvalidAuthorisation();
        }
        if (!renderers[tokenRenderer]) {
            revert InvalidTokenRenderer();
        }

        bool canUpdateToken = tokenRenderer.canUpdateToken(
            msg.sender,
            tokenId,
            targetTokenId
        );

        if (!canUpdateToken) {
            revert InvalidRendererAuthorisation();
        }

        Token memory token = tokens[tokenId];
        tokens[tokenId].renderer = tokenRenderer;
        tokens[tokenId].targetTokenId = targetTokenId;
        _notifyTokenUpdate(tokenId, token);
    }

    // PUBLIC TOKEN

    function tokenHTML(uint256 tokenId) public view returns (string memory) {
        Token memory token = tokens[tokenId];
        ITheStalkerRenderer renderer = _targetTokenRenderer(tokenId, token);
        return renderer.tokenHTML(tokenId, token.targetTokenId);
    }

    function tokenImage(uint256 tokenId) public view returns (string memory) {
        Token memory token = tokens[tokenId];
        ITheStalkerRenderer renderer = _targetTokenRenderer(tokenId, token);
        return renderer.tokenImage(tokenId, token.targetTokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        Token memory token = tokens[tokenId];
        ITheStalkerRenderer renderer = _targetTokenRenderer(tokenId, token);
        return renderer.tokenURI(tokenId, token.targetTokenId);
    }

    // INTERNAL

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // PRIVATE

    function _mintStalker(uint256 count) private {
        unchecked {
            uint256 nextTokenId = _nextTokenId();
            uint256 length = nextTokenId + count;

            do {
                (
                    bytes32 seed,
                    uint256 freshHellTokenId
                ) = _getRandomFreshHellSeedAndTokenId(nextTokenId);
                tokens[nextTokenId].seed = seed;
                tokens[nextTokenId].targetTokenId = freshHellTokenId;
                ++nextTokenId;
            } while (nextTokenId < length);

            _mint(msg.sender, count);
        }
    }

    // If token becomes unrenderable after user sets
    // let's fallback to default renderer.
    function _targetTokenRenderer(
        uint256 tokenId,
        Token memory token
    ) private view returns (ITheStalkerRenderer) {
        ITheStalkerRenderer renderer = token.renderer;
        renderer = _launchOrTokenRenderer(renderer);
        if (
            renderers[renderer] &&
            renderer.isTokenRenderable(tokenId, token.targetTokenId)
        ) {
            return renderer;
        } else {
            return defaultRenderer;
        }
    }

    // Fallback to launch renderer. Instead of writing at mint,
    // we correct the renderer address on read to save gas.
    function _launchOrTokenRenderer(
        ITheStalkerRenderer tokenRenderer
    ) private view returns (ITheStalkerRenderer) {
        if (address(tokenRenderer) == address(0)) {
            return launchRenderer;
        }
        return tokenRenderer;
    }

    function _getRandomFreshHellSeedAndTokenId(
        uint256 nextTokenId
    ) private view returns (bytes32, uint256) {
        unchecked {
            bytes32 seed = keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp,
                    nextTokenId
                )
            );
            return (seed, (uint256(seed) % 2) + 1);
        }
    }

    function _notifyTokenUpdate(uint256 tokenId, Token memory token) private {
        emit MetadataUpdate(tokenId);
        emit TokenUpdate(tokenId, token.renderer, token.targetTokenId);
    }
}
