//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./Strings.sol";
import "./IPartCollection.sol";
import "./URICompiler.sol";
import "./IHost.sol";
import "./IFrameCollection.sol";
import "./AvatarBase.sol";
import "./IAvatar.sol";
import "./IDava.sol";
import "./OnchainMetadata.sol";
import "./QuickSort.sol";

contract AvatarV1 is AvatarBase {
    using Strings for uint256;

    function version() public pure override returns (string memory) {
        return "V1";
    }

    function getPFP() external view override returns (string memory) {
        return OnchainMetadata.compileImages(_imgURIs());
    }

    function getMetadata() external view override returns (string memory) {
        IDava _dava = IDava(dava());

        Part[] memory parts = allParts();

        IPartCollection.Attribute[]
            memory attributes = new IPartCollection.Attribute[](parts.length);

        uint256 wearingPartAmount = 0;
        for (uint256 i = 0; i < parts.length; i += 1) {
            if (parts[i].collection != address(0x0)) {
                attributes[wearingPartAmount] = IPartCollection.Attribute(
                    IPartCollection(parts[i].collection).categoryTitle(
                        parts[i].id
                    ),
                    IPartCollection(parts[i].collection).partTitle(parts[i].id)
                );
                wearingPartAmount += 1;
            }
        }

        IPartCollection.Attribute[]
            memory wearingAttributes = new IPartCollection.Attribute[](
                wearingPartAmount + 1
            );
        for (uint256 i = 0; i < wearingPartAmount; i += 1) {
            wearingAttributes[i] = attributes[i];
        }
        wearingAttributes[wearingPartAmount] = IPartCollection.Attribute(
            "ADDRESS",
            uint256(uint160(address(this))).toHexString(20)
        );

        string memory baseURI = IHost(dava()).baseURI();
        string[] memory infoParams = new string[](3);
        infoParams[0] = "info";
        infoParams[1] = uint256(uint160(address(_dava))).toHexString(20);
        infoParams[2] = uint256(_props().davaId).toString();

        return
            OnchainMetadata.toMetadata(
                string(
                    abi.encodePacked(
                        "DAVA #",
                        uint256(_props().davaId).toString()
                    )
                ),
                string(
                    abi.encodePacked(
                        "Genesis Avatar (",
                        uint256(uint160(address(this))).toHexString(20),
                        ")"
                    )
                ),
                _imgURIs(),
                externalImgUri(),
                URICompiler.getFullUri(
                    baseURI,
                    infoParams,
                    new URICompiler.Query[](0)
                ),
                wearingAttributes
            );
    }

    function externalImgUri() public view override returns (string memory) {
        IDava _dava = IDava(dava());

        Part[] memory parts = allParts();
        address frameCollection = _dava.frameCollection();
        IFrameCollection.FrameWithUri[] memory frames = IFrameCollection(
            frameCollection
        ).getAllFrames();

        QuickSort.Layer[] memory layers = new QuickSort.Layer[](
            parts.length + frames.length
        );

        URICompiler.Query[] memory queries = new URICompiler.Query[](
            parts.length + frames.length
        );

        for (uint256 i = 0; i < frames.length; i += 1) {
            queries[i] = URICompiler.Query(
                uint256(uint160(frameCollection)).toHexString(20),
                frames[i].id.toString()
            );
            layers[i] = QuickSort.Layer(i, frames[i].zIndex);
        }

        uint256 layerAmount = frames.length;
        for (uint256 i = 0; i < parts.length; i += 1) {
            if (parts[i].collection != address(0x0)) {
                queries[layerAmount] = URICompiler.Query(
                    uint256(uint160(parts[i].collection)).toHexString(20),
                    uint256(parts[i].id).toString()
                );
                layers[layerAmount] = QuickSort.Layer(
                    layerAmount,
                    IPartCollection(parts[i].collection).zIndex(parts[i].id)
                );
                layerAmount += 1;
            }
        }

        if (layerAmount > 1) {
            QuickSort.sort(layers, int256(0), int256(layerAmount - 1));
        }
        URICompiler.Query[] memory sortedQueries = new URICompiler.Query[](
            layerAmount
        );
        for (uint256 i = 0; i < layerAmount; i += 1) {
            sortedQueries[i] = queries[layers[i].value];
        }

        string memory baseURI = IHost(dava()).baseURI();
        string[] memory imgParams = new string[](1);
        imgParams[0] = "images";

        return URICompiler.getFullUri(baseURI, imgParams, sortedQueries);
    }

    function _imgURIs() private view returns (string[] memory) {
        IDava _dava = IDava(dava());

        Part[] memory parts = allParts();
        address frameCollection = _dava.frameCollection();
        IFrameCollection.FrameWithUri[] memory frames = IFrameCollection(
            frameCollection
        ).getAllFrames();

        uint256 totalLayers = frames.length + parts.length;
        uint256 validLayers = frames.length;

        QuickSort.Layer[] memory layers = new QuickSort.Layer[](totalLayers);
        string[] memory imgURIs = new string[](totalLayers);
        for (uint256 i = 0; i < frames.length; i += 1) {
            imgURIs[i] = frames[i].imgUri;
            layers[i] = QuickSort.Layer(i, frames[i].zIndex);
        }

        for (uint256 i = 0; i < parts.length; i += 1) {
            if (parts[i].collection != address(0x0)) {
                imgURIs[validLayers] = IPartCollection(parts[i].collection)
                    .imageUri(parts[i].id);
                layers[validLayers] = QuickSort.Layer(
                    validLayers,
                    IPartCollection(parts[i].collection).zIndex(parts[i].id)
                );
                validLayers += 1;
            }
        }

        if (validLayers > 1) {
            QuickSort.sort(layers, int256(0), int256(validLayers - 1));
        }

        string[] memory sortedImgURIs = new string[](validLayers);
        for (uint256 i = 0; i < validLayers; i += 1) {
            sortedImgURIs[i] = imgURIs[layers[i].value];
        }

        return sortedImgURIs;
    }
}
