// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * #######################################   ######################################
 * #####################################       ####################################
 * ###################################           ##################################
 * #################################               ################################
 * ################################################################################
 * ################################################################################
 * ################       ####                           ###        ###############
 * ################      ####        #############        ####      ###############
 * ################     ####          ###########          ####     ###############
 * ################    ###     ##       #######       ##    ####    ###############
 * ################  ####    ######      #####      ######    ####  ###############
 * ################ ####                                       #### ###############
 * ####################                #########                ###################
 * ################                     #######                     ###############
 * ################   ###############             ##############   ################
 * #################   #############               ############   #################
 * ###################   ##########                 ##########   ##################
 * ####################    #######                   #######    ###################
 * ######################     ###                     ###    ######################
 * ##########################                             #########################
 * #############################                       ############################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 *
 * The Mutytes have invaded Ethernia! We hereby extend access to the lab and
 * its facilities to any individual or party that may locate and retrieve a
 * Mutyte sample. We believe their mutated Bit Signatures hold the key to
 * unraveling many great mysteries.
 * Join our efforts in understanding these creatures and witness Ethernia's
 * future unfold.
 *
 * Founders: @nftyte & @tuyumoo
 */

import "./IMutationInterpreter.sol";
import "./Base64.sol";
import "./Ownable.sol";
import "./Buffers.sol";
import "./Labels.sol";
import "./Colors.sol";
import "./Materials.sol";
import "./Models.sol";
import "./Traits.sol";
import "./Renderable.sol";

contract MutyteInterpreter is IMutationInterpreter, Ownable {
    using Strings for uint256;
    using Buffers for Buffers.Writer;
    using Paths for Paths.Path;

    function tokenURI(
        TokenData calldata token,
        MutationData calldata mutation,
        string calldata externalURL
    ) external pure override returns (string memory) {
        Renderable.Mutyte memory mutyte = Renderable.fromDNA(
            token.dna.length > 0 ? token.dna[0] : 0
        );
        (string memory image, string memory attrs) = _render(mutyte, mutation);
        (
            string memory name,
            string memory description,
            string memory url
        ) = _getInfo(token, mutation, externalURL);

        return _encodeMetaData(name, description, url, image, attrs);
    }

    function _getInfo(
        TokenData memory token,
        MutationData memory mutation,
        string memory externalURL
    )
        private
        pure
        returns (
            string memory name,
            string memory description,
            string memory url
        )
    {
        string memory tokenIdStr = token.id.toString();
        string memory mutyteName = bytes(token.name).length > 0
            ? token.name
            : string.concat("Mutyte #", tokenIdStr);

        return (
            mutyteName,
            string.concat(
                bytes(token.info).length == 0
                    ? "The Mutytes are a collection of 10,101 severely mutated creatures that invaded Ethernia. Completely decentralized, every Mutyte is generated, stored and rendered 100% on-chain. Once acquired, a Mutyte grants its owner access to the lab and its facilities."
                    : token.info,
                "\\n\\n",
                mutyteName,
                " is exhibiting signs of mutation ",
                bytes(mutation.name).length > 0
                    ? mutation.name
                    : string.concat("#", (mutation.id + 1).toString3()),
                ".",
                bytes(mutation.info).length == 0
                    ? ""
                    : string.concat("\\n", mutation.info)
            ),
            string.concat(externalURL, tokenIdStr)
        );
    }

    function _encodeMetaData(
        string memory name,
        string memory description,
        string memory url,
        string memory image,
        string memory attributes
    ) private pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        name,
                        '","description":"',
                        description,
                        '","external_url":"',
                        url,
                        '","image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(image)),
                        '","attributes":[',
                        attributes,
                        "]}"
                    )
                )
            );
    }

    function _render(
        Renderable.Mutyte memory mutyte,
        MutationData memory mutation
    ) private pure returns (string memory, string memory) {
        Buffers.Writer memory attrs = Buffers.getWriter(3200);
        Buffers.Writer memory image = Buffers.getWriter(24000);

        _addMutationAttribute(attrs, mutation.id + 1);
        _addAttribute(attrs, "Mutation Level", mutyte.mutationLevel + 1);
        _addAttribute(attrs, "Unlocked Mutations", mutation.count);

        image.write(
            '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><style>rect:not([fill]){transition:opacity .25s .25s}rect:not([fill]):hover{transition-delay:0s;opacity:.3}</style>'
        );
        _renderBackground(mutyte, image);
        image.write(
            '<g stroke-linecap="round" stroke-linejoin="round" stroke="#000" stroke-width="2">'
        );
        if (!mutyte.legs[0] || mutyte.legs[1]) {
            _renderLegs(0, mutyte, image, attrs);
        }
        _renderEars(mutyte, image, attrs);
        _renderBody(mutyte, image, attrs);
        _renderCheeks(mutyte, image, attrs);
        _renderMouth(mutyte, image, attrs);
        _renderTeeth(mutyte, image, attrs);
        _renderNose(mutyte, image, attrs);
        _renderEyes(mutyte, image, attrs);
        if (mutyte.legs[0] || mutyte.legs[1]) {
            _renderLegs(1, mutyte, image, attrs);
        }
        _renderArms(mutyte, image, attrs);
        image.writeWord("</g></svg>");

        return (image.toString(), attrs.toString());
    }

    function _renderBackground(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image
    ) private pure {
        Materials.Variant memory variant = Materials.get(0).variants[
            mutyte.mutationLevel
        ];
        string memory color1 = Colors.get(variant.colorIds[0]);
        string memory color2 = Colors.get(variant.colorIds[1]);
        image.write('<rect width="256" height="256" fill="', color1, '"/>');

        uint256 shapes = mutyte.bgShapes;
        _renderBackgroundShape((shapes >> 4) & 0xF, color2, image);
        _renderBackgroundShape(shapes & 0xF, color1, image);
        _renderBackgroundPattern(mutyte, image);
    }

    function _renderBackgroundShape(
        uint256 shape,
        string memory color,
        Buffers.Writer memory image
    ) private pure {
        image.writeWords('<path opacity=".5" fill="', color, '" d="M0 128');

        if (shape >> 3 == 1) {
            image.writeWord("V0H128");
        } else {
            image.writeWord("L128 0");
        }

        if ((shape >> 2) & 1 == 1) {
            image.writeWord("H256V128");
        } else {
            image.writeWord("L256 128");
        }

        if ((shape >> 1) & 1 == 1) {
            image.writeWord("V256H128");
        } else {
            image.writeWord("L128 256");
        }

        if (shape & 1 == 1) {
            image.writeWord("H0");
        }

        image.writeWord('Z"/>');
    }

    function _renderBackgroundPattern(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image
    ) private pure {
        image.writeWord('<g fill="#000" opacity=".2">');
        uint256 pid = 64;
        uint256 dna = mutyte.dna;
        uint256 pattern = ((dna << 10) & 0xFFFFE00000000000) |
            ((dna << 8) & 0x7E000000000) |
            ((dna << 6) & 0x7C0000000) |
            ((dna << 2) & 0x3E00000) |
            (dna & 0x7FFFF);

        for (uint256 i; i < 8; i++) {
            string memory y = ((i << 5) + 1).toString3();

            for (uint256 j; j < 8; j++) {
                if ((pattern >> --pid) & 1 == 1) {
                    image.writeWords(
                        '<rect width="30" height="30" x="',
                        ((j << 5) + 1).toString3(),
                        '" y="',
                        y,
                        (pattern >> (63 - pid)) & 1 == 1
                            ? '" opacity=".5"/>'
                            : '"/>'
                    );
                }
            }
        }

        image.writeWord("</g>");
    }

    function _renderBody(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory body = Traits.getBody(mutyte.bodyId);
        Traits.Model[] memory tModels = body.parts[0].models;

        for (uint256 i; i < tModels.length; i++) {
            Traits.Model memory tModel = tModels[i];
            _renderModel(
                image,
                Models.getBody(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(attrs, body, "Body", mutyte.colorId);
    }

    function _renderCheeks(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory cheeks = Traits.getCheeks(mutyte.cheeksId);
        Traits.Model[] memory tModels = cheeks.parts[0].models;

        for (uint256 i; i < tModels.length; i++) {
            Traits.Model memory tModel = tModels[i];
            _renderModel(
                image,
                Models.getCheeks(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(attrs, "Cheeks", Labels.get(cheeks.nameId));
    }

    function _renderLegs(
        uint256 pid,
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory legs = Traits.getLegs(mutyte.legsId);
        Traits.Model[] memory tModels = legs.parts[pid].models;

        for (uint256 j; j < tModels.length; j++) {
            Traits.Model memory tModel = tModels[j];
            _renderModel(
                image,
                Models.getLegs(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(
            attrs,
            legs,
            pid == 0 ? "Back Legs" : "Front Legs",
            mutyte.colorId
        );
    }

    function _renderArms(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory arms = Traits.getArms(mutyte.armsId);

        for (uint256 i; i < ARMS_PART_COUNT; i++) {
            if (mutyte.arms[i]) {
                Traits.Model[] memory tModels = arms.parts[i].models;

                for (uint256 j; j < tModels.length; j++) {
                    Traits.Model memory tModel = tModels[j];
                    _renderModel(
                        image,
                        Models.getArms(tModel.id),
                        tModel,
                        mutyte.colorId
                    );
                }

                _addAttribute(
                    attrs,
                    arms,
                    i == 0 ? "Bottom Arms" : "Top Arms",
                    mutyte.colorId
                );
            }
        }
    }

    function _renderEars(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory ears = Traits.getEars(mutyte.earsId);
        string[EARS_PART_COUNT] memory tTypes = [
            "Bottom Left Ear",
            "Bottom Right Ear",
            "Left Ear",
            "Right Ear",
            "Middle Ear"
        ];

        for (uint256 i; i < EARS_PART_COUNT; i++) {
            if (mutyte.ears[i]) {
                Traits.Model[] memory tModels = ears.parts[i].models;

                for (uint256 j; j < tModels.length; j++) {
                    Traits.Model memory tModel = tModels[j];
                    _renderModel(
                        image,
                        Models.getEars(tModel.id),
                        tModel,
                        mutyte.colorId
                    );
                }

                _addAttribute(attrs, ears, tTypes[i], mutyte.colorId);
            }
        }
    }

    function _renderEyes(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory eyes = Traits.getEyes(mutyte.eyesId);
        string[EYES_PART_COUNT] memory tTypes = [
            "Bottom Left Eye",
            "Bottom Right Eye",
            "Left Eye",
            "Right Eye",
            "Middle Eye",
            "Top Left Eye",
            "Top Right Eye",
            "Top Middle Eye"
        ];

        for (uint256 i; i < EYES_PART_COUNT; i++) {
            if (mutyte.eyes[i]) {
                Traits.Model[] memory tModels = eyes.parts[i].models;

                for (uint256 j; j < tModels.length; j++) {
                    Traits.Model memory tModel = tModels[j];
                    _renderModel(
                        image,
                        Models.getEyes(tModel.id),
                        tModel,
                        mutyte.colorId
                    );
                }

                _addAttribute(attrs, eyes, tTypes[i], mutyte.colorId);
            }
        }
    }

    function _renderNose(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory nose = Traits.getNose(mutyte.noseId);
        Traits.Model[] memory tModels = nose.parts[0].models;

        for (uint256 i; i < tModels.length; i++) {
            Traits.Model memory tModel = tModels[i];
            _renderModel(
                image,
                Models.getNose(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(attrs, "Nose", Labels.get(nose.nameId));
    }

    function _renderMouth(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory mouth = Traits.getMouth(mutyte.mouthId);
        Traits.Model[] memory tModels = mouth.parts[0].models;

        for (uint256 i; i < tModels.length; i++) {
            Traits.Model memory tModel = tModels[i];
            _renderModel(
                image,
                Models.getMouth(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(attrs, "Mouth", Labels.get(mouth.nameId));
    }

    function _renderTeeth(
        Renderable.Mutyte memory mutyte,
        Buffers.Writer memory image,
        Buffers.Writer memory attrs
    ) private pure {
        Traits.Trait memory teeth = Traits.getTeeth(mutyte.teethId);
        Traits.Model[] memory tModels = teeth.parts[0].models;

        for (uint256 i; i < tModels.length; i++) {
            Traits.Model memory tModel = tModels[i];
            _renderModel(
                image,
                Models.getTeeth(tModel.id),
                tModel,
                mutyte.colorId
            );
        }

        _addAttribute(attrs, "Teeth", Labels.get(teeth.nameId));
    }

    function _renderModel(
        Buffers.Writer memory image,
        Models.Model memory model,
        Traits.Model memory tModel,
        uint256 variantId
    ) private pure {
        Materials.Variant[] memory variants = Materials
            .get(model.materialId)
            .variants;
        Materials.Variant memory variant = variants[
            variantId % variants.length
        ];
        image.writeWords(
            '<g transform="translate(',
            tModel.x.toString3(),
            ",",
            tModel.y.toString3(),
            tModel.flip ? ') scale(-1,1)">' : ')">'
        );

        for (uint256 i; i < model.paths.length; i++) {
            Paths.Path memory path = model.paths[i];
            image.writeWord('<path d="');
            image.write(path.d);
            image.writeWords(
                path.stroke ? "" : '" stroke="none',
                '" fill="',
                path.fill ? Colors.get(variant.colorIds[path.fillId]) : "none",
                '"/>'
            );
        }

        image.writeWord("</g>");
    }

    function _addAttribute(
        Buffers.Writer memory attrs,
        Traits.Trait memory trait,
        string memory tType,
        uint256 colorId
    ) private pure {
        string memory label = Labels.get(trait.nameId);
        Materials.Variant[] memory variants = Materials
            .get(trait.materialId)
            .variants;

        label = string.concat(
            Labels.get(variants[colorId % variants.length].nameId),
            " ",
            label
        );

        _addAttribute(attrs, tType, label);
    }

    function _addAttribute(
        Buffers.Writer memory attrs,
        string memory tType,
        string memory value
    ) private pure {
        attrs.writeWords(',{"trait_type":"', tType, '","value":"');
        attrs.write(value);
        attrs.writeWord('"}');
    }

    function _addAttribute(
        Buffers.Writer memory attrs,
        string memory tType,
        uint256 value
    ) private pure {
        attrs.writeWords(',{"trait_type":"', tType, '","value":');
        attrs.write(value.toString());
        attrs.writeWord("}");
    }

    function _addMutationAttribute(
        Buffers.Writer memory attrs,
        uint256 mutation
    ) private pure {
        attrs.write(
            '{"display_type":"number","trait_type":"Mutation Type","value":'
        );
        attrs.writeWord(mutation.toString3());
        attrs.writeChar("}");
    }
}
