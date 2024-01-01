// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfConstitution.sol";

import "./FilesFolder.sol";

contract RegisterOfConstitution is IRegisterOfConstitution, FilesFolder {

    address private _pointer;

    //##################
    //##  Write I/O  ##
    //##################

    function changePointer(address body) external onlyDK {
        if (_pointer != address(0)) setStateOfFile(_pointer, uint8(FilesRepo.StateOfFile.Revoked));
        // setStateOfFile(body, uint8(StateOfFile.Closed));
        _pointer = body;
        emit ChangePointer(body);
    }

    //##################
    //##    读接口    ##
    //##################

    function pointer() external view returns (address) {
        return _pointer;
    }
}
