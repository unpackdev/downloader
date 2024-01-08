// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library ColourWork {

    function safeTint(uint colourComponent, uint tintComponent, uint alpha) internal pure returns (uint) {        
        unchecked {
            if (alpha == 0) {
                return uint8(colourComponent);
            }
            uint safelyTinted;

            if (colourComponent <= tintComponent) {
                uint offset = ((tintComponent - colourComponent) * alpha) / 255; 
                safelyTinted = colourComponent + offset;            
            } else {
                uint offset = ((colourComponent - tintComponent) * alpha) / 255; 
                safelyTinted = colourComponent - offset;
            }

            return uint8(safelyTinted);            
        }
    }
}