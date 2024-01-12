//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SVG.sol";
import "./Utils.sol";
import "./Strings.sol";
import "./Base64.sol";

/// ============ epochs interface ============
interface IEpochs {
    function getEpochLabels() external view returns (string[12] memory);

    function getEpochs(uint256 blockNumber)
        external
        pure
        returns (uint256[12] memory);
}

// Core Renderer called from the main contract.
contract Renderer {
    /// ============ get epochs ============

    address epochsAddr = 0xde9f0c369Ef3692B4bF9D40803A9029a3722B9c4;

    function getEpochLabels() public view returns (string[12] memory) {
        return IEpochs(epochsAddr).getEpochLabels();
    }

    function getEpochs() public view returns (uint256[12] memory) {
        return IEpochs(epochsAddr).getEpochs(block.number);
    }

    string[12] public epochLabels = getEpochLabels();

    function _block() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[0]);
    }

    function _form() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[1]);
    }

    function _structure() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[2]);
    }

    function _bloom() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[3]);
    }

    function _episode() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[4]);
    }

    function _phase() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[5]);
    }

    function _season() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[6]);
    }

    function _revolution() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[7]);
    }

    function _aepoch() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[8]);
    }

    function _aera() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[9]);
    }

    function _arche() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[10]);
    }

    function _aeon() internal view returns (string memory) {
        return utils.uint2str(getEpochs()[11]);
    }

    // Built seed(s)
    function _seed1() internal view returns (string memory) {
        return string.concat(_block(), _form(), _structure(), _bloom());
    }

    function _seed2() internal view returns (string memory) {
        return string.concat(_episode(), _phase(), _season(), _revolution());
    }

    function _seed3() internal view returns (string memory) {
        return string.concat(_aepoch(), _aera(), _arche(), _aeon());
    }

    function _seed() internal view returns (string memory) {
        return string.concat(_seed1(), _seed2(), _seed3());
    }

    function _seedBlock() internal view returns (string memory) {
        return utils.uint2str(block.number);
    }

    // Build additional SVG values
    function _scale() internal view returns (string memory) {
        return string.concat(_block(), _structure());
    }

    function _baseFrequency1() internal view returns (string memory) {
        return string.concat('0.', _block());
    }

    function _baseFrequency2() internal view returns (string memory) {
        return string.concat('0.0', _revolution(), _block());
    }

    /// ============ get colors ============    
    function getColor(string memory _add, uint256 multiplier)
        internal
        pure
        returns (string memory)
    {
        string[7] memory colors = [
            string.concat('00', utils.getSlice(3, 6, _add)),
            utils.getSlice(7, 12, _add),
            utils.getSlice(13, 18, _add),
            utils.getSlice(19, 24, _add),
            utils.getSlice(25, 30, _add),
            utils.getSlice(31, 36, _add),
            utils.getSlice(37, 42, _add)
        ];
        return utils.pluck(multiplier, 'COLORS', colors);
    }

    // Select colors
    function _color1(string memory _add) internal view returns (string memory) {
        return string.concat('#', getColor(_add, block.number * getEpochs()[0]));
    }

    function _color2(string memory _add) internal view returns (string memory) {
        return string.concat('#', getColor(_add, block.number / getEpochs()[0]));
    }

    function _color3(string memory _add) internal view returns (string memory) {
        return string.concat('#', getColor(_add, block.number));
    }

    /// ============ build NFT ============

    function render(uint256 _tokenId, string memory _address) public view returns (string memory) {
        return
            string.concat(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        getNebulaeth(
                            getName(_tokenId),
                            getImage(_address),
                            getDescription(_address)
                        )
                    )
                )
            );
    }

    function getNebulaeth(
        string memory _getName,
        string memory _getImage,
        string memory _getDescription
    ) public pure returns (string memory) {
        return string.concat('{', _getName, _getImage, _getDescription, '}');
    }

    function getName(uint256 tokenId) internal view returns (string memory) {
        return
            string.concat(
                '"name":',
                '"NEBULAETH',
                ' ',
                string.concat(utils.uint2str(tokenId + 1), '-', _bloom(), _structure(), _form()),
                '",'
            );
    }

    function getImage(string memory _add) internal view returns (string memory) {
        return
            string.concat(
                '"image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(getSVG(_add))),
                '",'
            );
    }

    function getSVG(string memory _add) internal view returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600" style="height: 100vh; width: 100vw; min-height: 600px; min-width: 600px;">',
                radialGradient(_add),
                filter(),
                svg.el(
                    'circle',
                    string.concat(
                        svg.prop('cx', '50%'),
                        svg.prop('cy', '50%'),
                        svg.prop('r', '55%'),
                        svg.prop('fill', 'url(#a)'),
                        svg.prop('filter', 'url(#b)')
                    )
                ),
                '</svg>'
            );
    }

    function radialGradient(string memory _add) internal view returns (string memory) {
        return
            svg.el(
                'radialGradient',
                string.concat(svg.prop('id', 'a')),
                string.concat(
                    svg.el(
                        'stop',
                        string.concat(svg.prop('stop-color', _color1(_add)))
                    ),
                    svg.el(
                        'stop',
                        string.concat(
                            svg.prop('offset', '0.125'),
                            svg.prop('stop-color', _color2(_add))
                        )
                    ),
                    svg.el(
                        'stop',
                        string.concat(
                            svg.prop('offset', '.25'),
                            svg.prop('stop-color', _color3(_add))
                        )
                    ),
                    svg.el('stop', string.concat(svg.prop('offset', '.5')))
                )
            );
    }

    function filter() internal view returns (string memory) {
        return
            svg.el(
                'filter',
                string.concat(svg.prop('id', 'b')),
                string.concat(
                    svg.el(
                        'feTurbulence',
                        string.concat(
                            svg.prop('baseFrequency', _baseFrequency1()),
                            svg.prop('seed', _seedBlock())
                        )
                    ),
                    svg.el(
                        'feColorMatrix',
                        string.concat(
                            svg.prop(
                                'values',
                                '0 0 0 9 -5 0 0 0 9 -5 0 0 0 9 -5 0 0 0 0 1'
                            ),
                            svg.prop('result', 's')
                        )
                    ),
                    svg.el(
                        'feTurbulence',
                        string.concat(
                            svg.prop('type', 'fractalNoise'),
                            svg.prop('baseFrequency', _baseFrequency2()),
                            svg.prop('numOctaves', _form()),
                            svg.prop('seed', _seed())
                        )
                    ),
                    svg.el(
                        'feDisplacementMap',
                        string.concat(
                            svg.prop('in', 'SourceGraphic'),
                            svg.prop('scale', _scale())
                        )
                    ),
                    svg.el(
                        'feBlend',
                        string.concat(
                            svg.prop('in', 's'),
                            svg.prop('mode', 'screen')
                        )
                    )
                )
            );
    }

    function getDescription(string memory _add) internal view returns (string memory) {
        return
            string.concat(
                '"description": "A nebulaeth discovered  in ',
                epochLabels[6],
                ' ',
                utils.uint2str(getEpochs()[6]),
                ' ',
                epochLabels[5],
                ' ',
                utils.uint2str(getEpochs()[5]),
                ' ',
                epochLabels[4],
                ' ',
                utils.uint2str(getEpochs()[4]),
                ' by ',
                _add,
                '.\\n\\n##[nebulaeth.space](https://nebulaeth.space)\\n\\n[epochs.cosmiccomputation.org](https://epochs.cosmiccomputation.org)"'
            );
    }
}
