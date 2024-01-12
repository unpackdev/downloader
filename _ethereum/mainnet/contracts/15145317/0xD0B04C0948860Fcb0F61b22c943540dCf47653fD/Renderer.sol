//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

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

    address internal constant EPOCH_ADDRESS =
        0xde9f0c369Ef3692B4bF9D40803A9029a3722B9c4; // mainnet

    // address internal constant EPOCH_ADDRESS =
    //     0x6710B4419eb05a8CDB7940268bf7AE40D0bF7773; // rinkeby

    function getEpochLabels() public view returns (string[12] memory) {
        return IEpochs(EPOCH_ADDRESS).getEpochLabels();
    }

    function getEpochs(uint256 blockNumber)
        public
        pure
        returns (uint256[12] memory)
    {
        return IEpochs(EPOCH_ADDRESS).getEpochs(blockNumber);
    }

    string[12] public epochLabels = getEpochLabels();

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

    /// ============ build NFT ============

    function render(uint256 _tokenId, string memory _address)
        public
        view
        returns (string memory)
    {
        uint256[12] memory epochs = getEpochs(block.number);
        return
            string.concat(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            '{',
                            getName(_tokenId, epochs),
                            getImage(_address, epochs),
                            getDescription(_address, epochs),
                            '}'
                        )
                    )
                )
            );
    }

    function getName(uint256 tokenId, uint256[12] memory _epochs)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                '"name":',
                '"NEBULAETH',
                ' ',
                string.concat(
                    utils.uint2str(tokenId + 1),
                    '-',
                    utils.uint2str(_epochs[3]),
                    utils.uint2str(_epochs[2]),
                    utils.uint2str(_epochs[1])
                ),
                '",'
            );
    }

    function getImage(string memory _add, uint256[12] memory _epochs)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                '"image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(getSVG(_add, _epochs))),
                '",'
            );
    }

    function getSVG(string memory _add, uint256[12] memory _epochs)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600" style="height: 100vh; width: 100vw; min-height: 600px; min-width: 600px;">',
                radialGradient(_add, _epochs),
                filter(_epochs),
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

    function radialGradient(string memory _add, uint256[12] memory _epochs)
        internal
        view
        returns (string memory)
    {
        string memory _color1 = string.concat(
            '#',
            getColor(_add, block.number * _epochs[0])
        );
        string memory _color2 = string.concat(
            '#',
            getColor(_add, block.number / _epochs[0])
        );
        string memory _color3 = string.concat(
            '#',
            getColor(_add, block.number)
        );
        return
            svg.el(
                'radialGradient',
                string.concat(svg.prop('id', 'a')),
                string.concat(
                    svg.el('stop', svg.prop('stop-color', _color1)),
                    svg.el(
                        'stop',
                        string.concat(
                            svg.prop('offset', '0.125'),
                            svg.prop('stop-color', _color2)
                        )
                    ),
                    svg.el(
                        'stop',
                        string.concat(
                            svg.prop('offset', '.25'),
                            svg.prop('stop-color', _color3)
                        )
                    ),
                    svg.el('stop', string.concat(svg.prop('offset', '.5')))
                )
            );
    }

    function seed(uint256[12] memory _epochs)
        internal
        pure
        returns (string memory)
    {
        string memory _seed1 = string.concat(
            utils.uint2str(_epochs[0]),
            utils.uint2str(_epochs[1]),
            utils.uint2str(_epochs[2]),
            utils.uint2str(_epochs[3])
        );
        string memory _seed2 = string.concat(
            utils.uint2str(_epochs[4]),
            utils.uint2str(_epochs[5]),
            utils.uint2str(_epochs[6]),
            utils.uint2str(_epochs[7])
        );
        string memory _seed3 = string.concat(
            utils.uint2str(_epochs[8]),
            utils.uint2str(_epochs[9]),
            utils.uint2str(_epochs[10]),
            utils.uint2str(_epochs[11])
        );
        return string.concat(_seed1, _seed2, _seed3);
    }

    function filter(uint256[12] memory _epochs)
        internal
        view
        returns (string memory)
    {
        return
            svg.el(
                'filter',
                string.concat(svg.prop('id', 'b')),
                string.concat(
                    svg.el(
                        'feTurbulence',
                        string.concat(
                            svg.prop(
                                'baseFrequency',
                                string.concat('0.', utils.uint2str(_epochs[0]))
                            ),
                            svg.prop('seed', utils.uint2str(block.number))
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
                            svg.prop(
                                'baseFrequency',
                                string.concat(
                                    '0.0',
                                    utils.uint2str(_epochs[7]),
                                    utils.uint2str(_epochs[0])
                                )
                            ),
                            svg.prop('numOctaves', utils.uint2str(_epochs[1])),
                            svg.prop('seed', seed(_epochs))
                        )
                    ),
                    svg.el(
                        'feDisplacementMap',
                        string.concat(
                            svg.prop('in', 'SourceGraphic'),
                            svg.prop(
                                'scale',
                                string.concat(
                                    utils.uint2str(_epochs[0]),
                                    utils.uint2str(_epochs[2])
                                )
                            )
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

    function getDescription(string memory _add, uint256[12] memory _epochs)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                '"description": "A nebulaeth discovered  in ',
                epochLabels[6],
                ' ',
                utils.uint2str(_epochs[6]),
                ' ',
                epochLabels[5],
                ' ',
                utils.uint2str(_epochs[5]),
                ' ',
                epochLabels[4],
                ' ',
                utils.uint2str(_epochs[4]),
                ' by ',
                _add,
                '.\\n\\n##[nebulaeth.space](https://nebulaeth.space)\\n\\n[epochs.cosmiccomputation.org](https://epochs.cosmiccomputation.org)"'
            );
    }
}
