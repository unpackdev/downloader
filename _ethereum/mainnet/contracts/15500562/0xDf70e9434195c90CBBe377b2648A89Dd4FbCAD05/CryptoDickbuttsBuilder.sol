// SPDX-License-Identifier: CC0-1.0

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G?77777J#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJP&&&&&&&JYB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@J75@@@@@@@@@@#57B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@B..7G&@@&G:^775P Y@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@G  ~&::5@5  7@@J  Y@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@B..! :P@@B^^775G Y@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:~&J7J&@@@@@@@& Y@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:.7777????B@@@& Y@@@@@@@@@#?~J@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:~&&&&&&&P#@B&& !GGG#@@@BYY&^^@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:!@@@@@@@.J&.Y&.!5YYJ7?JP##7YB@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:!@@@@@@B~P@~J#&@@?7!:?G@P~ G@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@5JY@@@@5.7B@Y^:@@@@@@@BYJJJJ&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G:B@@@&G:^!.?#@@@@@@@@# J&@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&^?@@@@@&&&@@@@@@@@@#5!#@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BY!77!7???G@@@&J???5B@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5 B? B&&&J^@Y^#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5~.&Y &@&Y^.@?.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#7Y55#Y^&B7Y5P#?~@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5JJJB@@@&YJJJ#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity ^0.8.13;

import "./Ownable.sol";

import "./SSTORE2.sol";
import "./Animation.sol";
import "./IPixelRenderer.sol";
import "./IAnimationEncoder.sol";
import "./ISVGWrapper.sol";

import "./IBuilder.sol";

contract CryptoDickbuttsBuilder is Ownable, IBuilder {
    error UnexpectedTraitCount(uint256 traitCount);

    uint8 public constant canonicalSize = 54;

    mapping(uint256 => address) data;
    mapping(uint256 => address) deltas;

    function getCanonicalSize()
        external
        pure
        override
        returns (uint256, uint256)
    {
        return (canonicalSize, canonicalSize);
    }

    function setData(uint256 key, bytes memory imageData) external onlyOwner {
        data[key] = SSTORE2.write(imageData);
    }

    function setDelta(uint256 key, bytes memory imageData) external onlyOwner {
        deltas[key] = SSTORE2.write(imageData);
    }

    /**
    @notice Returns the canonical image for the given metadata buffer, in an encoded data URI format.
     */
    function getImage(
        IPixelRenderer renderer,
        IAnimationEncoder encoder,
        uint8[] memory metadata,
        uint tokenId
    ) external view override returns (string memory) {
        return encoder.getDataUri(_getAnimation(renderer, metadata, tokenId));
    }

    function _getAnimation(IPixelRenderer renderer, uint8[] memory metadata, uint tokenId)
        private
        view
        returns (Animation memory animation)
    {
        animation.width = canonicalSize;
        animation.height = canonicalSize;
        animation.frames = new AnimationFrame[](1);

        AnimationFrame memory frame;
        frame.width = animation.width;
        frame.height = animation.height;
        frame.buffer = new uint32[](frame.width * frame.height);

        DrawFrame memory drawFrame;
        drawFrame.blend = AlphaBlend.Type.Pillow;

        if (metadata.length == 12) {
            _renderAttribute(renderer, frame, drawFrame, metadata[0]);  // background
            _renderAttribute(renderer, frame, drawFrame, metadata[1]);  // skin
            _renderAttribute(renderer, frame, drawFrame, metadata[9]);  // butt
            _renderAttribute(renderer, frame, drawFrame, metadata[3]);  // hat
            _renderAttribute(renderer, frame, drawFrame, metadata[5]);  // mouth
            _renderAttribute(renderer, frame, drawFrame, metadata[2]);  // body
            _renderAttribute(renderer, frame, drawFrame, metadata[10]); // dick
            _renderAttribute(renderer, frame, drawFrame, metadata[8]);  // shoes
            _renderAttribute(renderer, frame, drawFrame, metadata[6]);  // nose
            _renderAttribute(renderer, frame, drawFrame, metadata[4]);  // eyes
            _renderAttribute(renderer, frame, drawFrame, metadata[7]);  // hand
            _renderAttribute(renderer, frame, drawFrame, metadata[11]); // special
        } else if (metadata.length == 1) {
            _renderAttribute(renderer, frame, drawFrame, metadata[0]);  // legendary
        } else {
            revert UnexpectedTraitCount(metadata.length);
        }

        address delta = deltas[tokenId];
        if(delta != address(0)) {
            drawFrame.blend = AlphaBlend.Type.None;
            drawFrame.buffer = SSTORE2.read(delta);
            drawFrame.frame = frame;
            drawFrame.position = 0;
            drawFrame.ox = 0;
            drawFrame.oy = 0;
            _renderFrame(renderer, frame, drawFrame);
        }

        animation.frames[animation.frameCount++] = frame;
    }

    function _renderAttribute(
        IPixelRenderer renderer,
        AnimationFrame memory frame,
        DrawFrame memory drawFrame,
        uint8 attribute
    ) private view {
        uint256 position;
        uint8 offsetX;
        uint8 offsetY;

        address feature = data[attribute];
        if (feature == address(0)) return;

        bytes memory buffer = SSTORE2.read(feature);
        (offsetX, position) = _readByte(position, buffer);
        (offsetY, position) = _readByte(position, buffer);

        drawFrame.buffer = buffer;
        drawFrame.position = position;
        drawFrame.frame = frame;
        drawFrame.ox = offsetX;
        drawFrame.oy = offsetY;

        _renderFrame(renderer, frame, drawFrame);
    }

    function _readByte(uint256 position, bytes memory buffer)
        private
        pure
        returns (uint8, uint256)
    {
        uint8 value = uint8(buffer[position++]);
        return (value, position);
    }

    function _renderFrame(
        IPixelRenderer renderer,
        AnimationFrame memory frame,
        DrawFrame memory drawFrame        
    ) private pure returns (uint256) {
        
        (uint32[] memory colors, uint256 positionAfterColor) = renderer.getColorTable(drawFrame.buffer, drawFrame.position);
        drawFrame.colors = colors;
        drawFrame.position = positionAfterColor;

        (uint32[] memory newBuffer, uint256 positionAfterDraw) = renderer.drawFrameWithOffsets(drawFrame);
        frame.buffer = newBuffer;

        return positionAfterDraw;
    }
}
