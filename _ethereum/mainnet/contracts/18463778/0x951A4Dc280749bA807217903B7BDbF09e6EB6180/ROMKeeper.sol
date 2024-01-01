// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./AccessControl.sol";

// import "./BOSSetting.sol";

import "./IROMKeeper.sol";

contract ROMKeeper is IROMKeeper, AccessControl {

    // ###################
    // ##   ROMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external onlyDK {
        _gk.getROM().setMaxQtyOfMembers(max);
    }

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) 
    external onlyDK {
        _gk.getROS().setPayInAmt(seqOfShare, amt, expireDate, hashLock);
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey)
    external onlyDK {
        _gk.getROS().requestPaidInCapital(hashLock, hashKey);
    }

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external onlyDK {
        _gk.getROS().withdrawPayInAmt(hashLock, seqOfShare);
    }

    function payInCapital(
        uint seqOfShare, 
        uint amt,
        uint msgValue,
        uint caller
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();

        SharesRepo.Share memory share =
            _ros.getShare(seqOfShare);
        
        require(share.head.shareholder == caller,
            "ROMK.payInCap: not shareholder");
        require(amt * _gk.getCentPrice() / 100 <= msgValue,
            "ROMK.payInCap: insufficient amt");
        
        _ros.payInCapital(seqOfShare, amt);
    }

    function decreaseCapital(
        uint256 seqOfShare, 
        uint paid, 
        uint par
    ) external onlyDK {
        _gk.getROS().decreaseCapital(seqOfShare, paid, par);
    }

    function updatePaidInDeadline(
        uint256 seqOfShare, 
        uint line
    ) external onlyDK {
        _gk.getROS().updatePaidInDeadline(seqOfShare, line);
    }

}
