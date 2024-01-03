// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IArtData.sol";
import "./Structs.sol";

interface IArtCode {

    function getCode(BaseAttributes calldata atts, bool isSample, IArtData.ArtProps calldata artProps) external view returns(bytes memory);

}
