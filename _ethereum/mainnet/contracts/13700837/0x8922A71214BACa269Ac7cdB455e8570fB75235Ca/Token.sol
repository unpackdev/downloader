//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Namespace to encapsulate a "Metadata" struct for a drawing
 */
library Token {
    struct Metadata { 
       string name;
       string description;
       string externalUrl;
       string drawingAddress;
    }
}
