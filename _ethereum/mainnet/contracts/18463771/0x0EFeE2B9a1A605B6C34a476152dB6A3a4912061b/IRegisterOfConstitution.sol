// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IFilesFolder.sol";

interface IRegisterOfConstitution is IFilesFolder{

    //##############
    //##  Event   ##
    //##############

    event ChangePointer(address indexed pointer);

    //##################
    //##  Write I/O  ##
    //##################

    function changePointer(address body) external;

    //##################
    //##    读接口    ##
    //##################

    function pointer() external view returns (address);
}
