// SPDX-License-Identifier: MIT

/**
 ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─██████████████─██████████████─██████──────────██████─██████████████─██████████████─██████──████████─██████████████─██████████████────
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██████████──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██────
─██░░██████░░██─██░░██████░░██─██░░░░░░░░░░██──██░░██─██░░██████████─██░░██████░░██─██░░██──██░░████─██░░██████████─██░░██████████────
─██░░██──██░░██─██░░██──██░░██─██░░██████░░██──██░░██─██░░██─────────██░░██──██░░██─██░░██──██░░██───██░░██─────────██░░██────────────
─██░░██████░░██─██░░██████░░██─██░░██──██░░██──██░░██─██░░██─────────██░░██████░░██─██░░██████░░██───██░░██████████─██░░██████████────
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░██──██░░██─██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░░░░░██────
─██░░██████████─██░░██████░░██─██░░██──██░░██──██░░██─██░░██─────────██░░██████░░██─██░░██████░░██───██░░██████████─██████████░░██────
─██░░██─────────██░░██──██░░██─██░░██──██░░██████░░██─██░░██─────────██░░██──██░░██─██░░██──██░░██───██░░██─────────────────██░░██────
─██░░██─────────██░░██──██░░██─██░░██──██░░░░░░░░░░██─██░░██████████─██░░██──██░░██─██░░██──██░░████─██░░██████████─██████████░░██────
─██░░██─────────██░░██──██░░██─██░░██──██████████░░██─██░░░░░░░░░░██─██░░██──██░░██─██░░██──██░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░██────
─██████─────────██████──██████─██████──────────██████─██████████████─██████──██████─██████──████████─██████████████─██████████████────
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 * @dev @henry
 * happy holidays 2023!
 */
pragma solidity 0.8.23;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./base64.sol";
import "./ERC721A.sol";

contract HappyHolidays is ERC721A, Ownable {
    using Strings for uint256;

    struct ArtPieceSVG {
        string[8] ornamentColors;
        string svgContent;
    }

    string private description = "This is an on-chain holiday collection. Each mint generates a piece with a randomised colour set. Happy Holidays 2023, from henry.";
    string private token_name = "Happy Holidays";
    string private external_url = "https://henrypye.xyz";

    constructor() ERC721A("Happy Holidays", "HAPHOL") {}

    function giftTo(address recipient) external onlyOwner {
        _mint(recipient, 1);
    }

    function mint() external onlyOwner {
        _mint(msg.sender, 1);
    }

    function giftToMultiple(address[] calldata recipients) external onlyOwner {
        for (uint256 i; i < recipients.length; i++) {
            _mint(recipients[i], 1);
        }
    }

    function updateDescription(string calldata _description) external onlyOwner {
        description = _description;
    }

    function updateName(string calldata _new_name) external onlyOwner {
        token_name = _new_name;
    }

    function updateExternalURL(string calldata _new_url) external onlyOwner {
        external_url = _new_url;
    }

    function getRandomColor(uint256 tokenId, uint256 maxColors) internal view returns (string memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, block.prevrandao, msg.sender)));
        uint256 colorIndex = rand % maxColors;
        return getColorByIndex(colorIndex);
    }

    function getColorByIndex(uint256 index) internal pure returns (string memory) {
        string[8] memory colors = ["#ffffff", "#00aaff", "#cb4ff1", "#db100f", "#ff7e19", "#6bff0e", "#ff5722", "#0c730c"];
        
        return colors[index % colors.length];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        return string(abi.encodePacked("data:application/json;base64,", 
                Base64.encode(
                    bytes(
                        string(abi.encodePacked('{"name": "',token_name,' #', tokenId.toString(), '", "description": "',description,'", "external_url": "',external_url,'", "image": "data:image/svg+xml;base64,', 
                        Base64.encode(bytes(generateArtPieceSVG(tokenId))), '"}'))
                    )
                )
            ));
    }

    function generateArtPieceSVG(uint256 tokenId) internal view returns (string memory) {
        ArtPieceSVG memory artPieceSVG;

        for (uint256 i = 0; i < 8; i++) {
            artPieceSVG.ornamentColors[i] = getRandomColor(tokenId + i, 8);
        }
        
        artPieceSVG.svgContent = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="1.7379 7.937 767.442 767.442" width="767.442" height="767.442">',
                    '<g transform="matrix(0.8289389610290527, 0, 0, 1, -1.9890949726104736, 1.4210854715202004e-14)">',
                        '<path fill="#010101" d="M 4.703 11.894 C -12.159 13.102 1007.305 7.937 1007.305 7.937 L 1007.305 775.379 L 7.305 775.379 L 4.703 11.894 Z"/>',
                    '</g>',
                    '<g transform="matrix(1, 0, 0, 1, 13.553369522094727, 9.437137603759766)">',
                        '<path fill="',artPieceSVG.ornamentColors[0],'" d="M240.791 0.628h186.047c14.884 22.837 30.395 46.093 46.512 69.767 -19.209 22.116 -23.07 45.372 -11.628 69.767a462.651 462.651 0 0 1 81.395 93.023c-63.023 34.628 -109.535 19.116 -139.535 -46.512v-93.023a244.698 244.698 0 0 0 -58.14 -69.767c-42.698 56.093 -77.581 48.326 -104.651 -23.256Z"/>',
                    '</g>',
                    '<g transform="matrix(1, 0, 0, 1, 8.081493377685547, -45.8916664123535)">',
                        '<path fill="',artPieceSVG.ornamentColors[1],'" d="M825.581 81.395v93.023c-58.651 -34.93 -58.651 -65.93 0 -93.023Z"/>',
                    '</g>',
                    '<g transform="matrix(1, 0, 0, 1, 14.2127103805542, 26.97425651550293)">',
                        '<path fill="',artPieceSVG.ornamentColors[2],'" d="M 174.419 267.442 C 223.808 217.433 362.028 344.506 362.028 344.506 C 370.214 428.227 256.645 519.544 278.738 536.242 C 180.831 511.591 185.047 374.559 174.419 267.443 L 174.419 267.442 Z"/>',
                    '</g>',
                    '<g transform="matrix(0.9929119944572449, 0, 0, 1, -338.0770568847656, -94.87667083740234)">',
                        '<path fill="',artPieceSVG.ornamentColors[3],'" d="M 988.372 406.977 C 1071.202 475.01 990.329 501.607 988.372 500 C 932.691 496.914 894.257 474.285 895.349 406.977 C 925.768 380.791 956.791 380.791 988.372 406.977 Z"/>',
                    '</g>',
                    '<g transform="matrix(1.0110349655151367, 0, 0, 1.427367925643921, 126.60209655761719, -253.3085479736328)">',
                        '<path fill="',artPieceSVG.ornamentColors[4],'" d="M 475.02 562.839 C 524.043 546.979 564.274 666.248 545.633 663.803 C 526.029 679.625 441.142 660.468 452.798 651.06 C 452.798 651.06 408.229 603.235 475.02 562.839 Z"/>',
                    '</g>',
                    '<g transform="matrix(1.0110349655151367, 0, 0, 1.427367925643921, -378.05810546875, -710.0194702148438)">',
                        '<path fill="',artPieceSVG.ornamentColors[5],'" d="M 475.02 562.839 C 524.043 546.979 638.048 631.284 619.407 628.839 C 599.803 644.661 454.386 638.343 466.042 628.935 C 466.042 628.935 408.229 603.235 475.02 562.839 Z"/>',
                    '</g>',
                    '<g transform="matrix(0.9929119944572449, 0, 0, 1, -291.1453857421875, -306.11138916015625)">',
                        '<path fill="',artPieceSVG.ornamentColors[6],'" d="M 988.372 406.977 C 1161.35 387.381 990.329 501.607 988.372 500 C 909.451 600.617 876.866 551.89 895.349 406.977 C 925.768 380.791 947.608 411.595 988.372 406.977 Z"/>',
                    '</g>',
                    '<g transform="matrix(1.0110349655151367, 0, 0, 1.427367925643921, -374.6351318359375, -293.4820861816406)">'
                        '<path fill="',artPieceSVG.ornamentColors[7],'" d="M 475.02 562.839 C 524.043 546.979 728.903 706.207 710.262 703.762 C 690.658 719.584 441.142 660.468 452.798 651.06 C 452.798 651.06 408.229 603.235 475.02 562.839 Z"/>',
                    '</g>',
                '</svg>'
            )
        );

        return artPieceSVG.svgContent;
    }
}
