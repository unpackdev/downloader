// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./BytesLib.sol";

import "./IBlitoadzRenderer.sol";

/*  @title Blitoadz Renderer V2
    @author Clement Walter
    @dev This V2 fixes the use of image_data instead of image in the token metadata
*/
contract BlitoadzRendererV2 is Ownable, IBlitoadzRenderer {
    IBlitoadzRenderer blitoadzRendererV1;

    constructor(address _blitoadzRendererV1) {
        blitoadzRendererV1 = IBlitoadzRenderer(_blitoadzRendererV1);
    }

    function tokenURI(
        uint256 toadzId,
        uint256 blitmapId,
        uint8 paletteOrder
    ) public view returns (string memory) {
        string memory baseMetadata = blitoadzRendererV1.tokenURI(
            toadzId,
            blitmapId,
            paletteOrder
        );
        return
            string.concat(
                string(BytesLib.slice(bytes(baseMetadata), 0, 24)),
                "image",
                string(
                    BytesLib.slice(
                        bytes(baseMetadata),
                        34,
                        bytes(baseMetadata).length - 34
                    )
                )
            );
    }
}
