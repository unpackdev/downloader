//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./SVG.sol";
import "./Utils.sol";

contract Renderer {
    string[] private wordsList = [
        "you are the light",
        "love yourself",
        "you've got this",
        "nothing will stop you",
        "you're the best",
        "believe",
        "you are worthy",
        "trust the process",
        "remember why you're here",
        "thank you for being you",
        "you're beautiful",
        "beloved",
        "you're amazing",
        "keep going",
        "it'll all be ok",
        "endure",
        "dream big",
        "believe in yourself",
        "yes, you can",
        "love your friends",
        "live laugh love",
        "prove them wrong",
        "you excite me",
        "just keep swimming",
        "hold on to hope",
        "seize the day",
        "win the day",
        "yolo",
        "keep going",
        "set yourself free",
        "make it happen",
        "breathe",
        "be kind",
        "kindness kills",
        "all you need is love",
        "don't give up",
        "conquer your dreams",
        "wish others well",
        "empower your thinking",
        "remember to laugh",
        "have fun",
        "you're the greatest",
        "you are brave",
        "you are appreciated",
        "enjoy",
        "believe and achieve",
        "don't worry, be happy",
        "do you",
        "choose love",
        "be you",
        "never lose hope",
        "you are successful",
        "you are the one",
        "be the change",
        "conquer",
        "build",
        "crush today",
        "you're a beast",
        "you're the goat",
        "you're a legend"
    ];

    function gradientColor1(uint256 _tokenId) public pure returns (string memory) {
        return string.concat("hsla(", utils.uint2str((_tokenId ** 3) % 1000), ", 70%, 80%, 0.8)");
    }

    function gradientColor2(address _address) public pure returns (string memory) {
        return string.concat("hsla(", utils.uint2str(uint160(_address) % 1000), ", 70%, 80%, 0.6)");
    }

    function wordText(uint256 _tokenId) public view returns (string memory) {
        return wordsList[_tokenId % wordsList.length];
    }

    function render(uint256 _tokenId, address _address) public view returns (string memory) {
        return string.concat(
            '<svg viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" style="background-color:white;">',
            svg.el(
                'defs',
                utils.NULL,
                svg.linearGradient(
                    string.concat(
                        svg.prop('id', 'linearGradient'),
                        svg.prop('gradientTransform', 'rotate(90)')
                    ),
                    string.concat(
                        svg.gradientStop(
                            20,
                            gradientColor1(_tokenId),
                            utils.NULL
                        ),
                        svg.gradientStop(
                            50,
                            gradientColor2(_address),
                            utils.NULL
                        )
                    ) 
                )
            ),
            svg.rect(
                string.concat(
                    svg.prop('width', '350'),
                    svg.prop('height', '350'),
                    svg.prop('fill', utils.getDefURL('linearGradient'))
                ),
                utils.NULL
            ),
            svg.path(
                svg.prop('id', 'textPath'),
                svg.el(
                    'animate',
                    string.concat(
                        svg.prop('attributeName', 'd'),
                        svg.prop('from', 'm0,110 h0'),
                        svg.prop('to', 'm0,110 h1100'),
                        svg.prop('dur', '4s'),
                        svg.prop('begin', '0s'),
                        svg.prop('repeatCount', 'indefinite')
                    )
                )
            ),
            svg.text(
                string.concat(
                    svg.prop('fill', 'black'),
                    svg.prop('font-family', 'monospace'),
                    svg.prop('font-size', '18px'),
                    svg.prop('x', '50%'),
                    svg.prop('dy', '15%'),
                    svg.prop('dominant-baseline', 'middle'),
                    svg.prop('text-anchor', 'middle')
                ),
                svg.el(
                    'textPath',
                    svg.prop('href', '#textPath'),
                    wordText(_tokenId)
                )
            ),
            '</svg>'
        );
    }
}