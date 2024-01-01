// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IROOKeeper.sol";

import "./AccessControl.sol";

contract ROOKeeper is IROOKeeper, AccessControl {

    // ##################
    // ##    Option    ##
    // ##################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external onlyDK {
        _gk.getROO().updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt, uint256 caller)
        external onlyDK
    {
        _gk.getROO().execOption(seqOfOpt, caller);
    }

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge,
        uint256 caller
    ) external onlyDK {
        
        IRegisterOfOptions _roo = _gk.getROO(); 
        IRegisterOfShares _ros = _gk.getROS();
        
        SwapsRepo.Swap memory swap = 
            _roo.createSwap(seqOfOpt, seqOfTarget, paidOfTarget, seqOfPledge, caller);

        _ros.decreaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        if (swap.isPutOpt)
            _ros.decreaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);        
    }

    function payOffSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap,
        uint msgValue,
        uint caller
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();

        SwapsRepo.Swap memory swap =
            _gk.getROO().payOffSwap(seqOfOpt, seqOfSwap, msgValue, _gk.getCentPrice());

        uint buyer = _ros.getShare(swap.seqOfPledge).head.shareholder;
        
        require (caller == buyer, "ROOK.payOffSwap: wrong payer");

        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        _ros.transferShare(swap.seqOfTarget, swap.paidOfTarget, swap.paidOfTarget, buyer, swap.priceOfDeal, swap.priceOfDeal);

        if (swap.isPutOpt)
            _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);

        _gk.saveToCoffer(
            _ros.getShare(swap.seqOfTarget).head.shareholder, 
            msgValue
        );
    }

    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap,
        uint caller
    ) external onlyDK {
        
    
        SwapsRepo.Swap memory swap = 
            _gk.getROO().terminateSwap(seqOfOpt, seqOfSwap);

        IRegisterOfShares _ros = _gk.getROS();
        uint seller = _ros.getShare(swap.seqOfTarget).head.shareholder;

        require (caller == seller, "ROOK.terminateSwap: wrong ");

        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        
        if(swap.isPutOpt) {
            _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);
            _ros.transferShare(swap.seqOfPledge, swap.paidOfPledge, swap.paidOfPledge, 
                seller, swap.priceOfDeal, swap.priceOfDeal);
        }
    }

    // ==== AgainstToBuy ====

    function requestToBuy(
        address ia,
        uint seqOfDeal,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller
    ) external onlyDK {

        // 
        IRegisterOfShares _ros = _gk.getROS();

        SwapsRepo.Swap memory swap =
            IInvestmentAgreement(ia).createSwap(_gk.getROA().getFile(ia).head.seqOfMotion, 
                seqOfDeal, paidOfTarget, seqOfPledge, caller);
        
        _ros.decreaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        _ros.decreaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);
    }

    function payOffRejectedDeal(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap,
        uint msgValue,
        uint caller
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();

        SwapsRepo.Swap memory swap = 
            IInvestmentAgreement(ia).payOffSwap(_gk.getROA().getFile(ia).head.seqOfMotion, 
                seqOfDeal, seqOfSwap, msgValue, _gk.getCentPrice());
        
        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);

        uint40 buyer = _ros.getShare(swap.seqOfPledge).head.shareholder;

        require(caller == buyer, "ROAK.payOffRD: not buyer");

        _ros.transferShare(swap.seqOfTarget, swap.paidOfTarget, swap.paidOfTarget, 
            buyer, swap.priceOfDeal, swap.priceOfDeal);

        _gk.saveToCoffer(
            _ros.getShare(swap.seqOfTarget).head.shareholder, 
            msgValue
        );
    }

    function pickupPledgedShare(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap,
        uint caller
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();

        SwapsRepo.Swap memory swap = 
            IInvestmentAgreement(ia).terminateSwap(_gk.getROA().getFile(ia).head.seqOfMotion, 
                seqOfDeal, seqOfSwap);

        uint40 seller = _ros.getShare(swap.seqOfTarget).head.shareholder;

        require(caller == seller, "ROAK.pickupPledgedShare: not seller");

        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);

        _ros.transferShare(swap.seqOfPledge, swap.paidOfPledge, swap.paidOfPledge, seller, swap.priceOfDeal, swap.priceOfDeal);

    }

}
