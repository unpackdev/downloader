// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./BBOTSRenderer.events.sol";
import "./MetadataRenderer.interface.sol";

interface IBBOTSRenderer is BBOTSRendererEvents, IMetadataRenderer {
    error TooMuchEntropy();

    /*///////////////////////////////////////////////////////////////
                        	   RANDOMNESS
    //////////////////////////////////////////////////////////////*/

    function requestEntropy(bytes32 _keyHash, uint32 _callbackGasLimit)
        external;
}
