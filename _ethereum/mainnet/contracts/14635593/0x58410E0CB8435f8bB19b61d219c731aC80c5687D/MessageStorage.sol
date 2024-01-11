// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Secret message
 */
contract MessageStorage {
    
    // "Konfirmation am 24.04.2022"
     
    // secret message, hint: The Gold-Bug
    string constant messageData = "bji16l95n6ji59stzwtzswss"
        "1zzlg4n8h6g4i6g4nzmkl6g4ng4l6mnomz6g426ih8l8lmn8oihh8l08nfn8oihh8l0828ih638z"
        "6g4d5lnjnzoihm6848z6g426i0828ih63pji8d83b86nfo8d63b86nz"
        "j118i25loi3rzruxrv"
        "06828lajm4o5z5008m3on8foh86i8lbji16l95n6jiz";
		
    function getSecretMessage() public pure returns (string memory) {
        return messageData;
    }

}