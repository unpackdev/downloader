// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";
import "./Checkpoints.sol";
import "./CondsRepo.sol";
import "./SharesRepo.sol";
import "./SwapsRepo.sol";

import "./IRegisterOfShares.sol";

library OptionsRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using Checkpoints for Checkpoints.History;
    using CondsRepo for CondsRepo.Cond;
    using CondsRepo for bytes32;
    using SwapsRepo for SwapsRepo.Repo;

    enum TypeOfOpt {
        CallPrice,          
        PutPrice,           
        CallRoe,            
        PutRoe,             
        CallPriceWithCnds,  
        PutPriceWithCnds,   
        CallRoeWithCnds,    
        PutRoeWithCnds     
    }

    enum StateOfOpt {
        Pending,    
        Issued,         
        Executed,
        Closed
    }

    struct Head {
        uint32 seqOfOpt;
        uint8 typeOfOpt;
        uint16 classOfShare;
        uint32 rate;            
        uint48 issueDate;
        uint48 triggerDate;     
        uint16 execDays;         
        uint16 closingDays;
        uint40 obligor;      
    }

    struct Body {
        uint48 closingDeadline;
        uint40 rightholder;
        uint64 paid;
        uint64 par;
        uint8 state;
        uint16 para;
        uint16 argu;
    }

    struct Option {
        Head head;
        CondsRepo.Cond cond;
        Body body;
    }

    struct Record {
        EnumerableSet.UintSet obligors;
        SwapsRepo.Repo swaps;
        Checkpoints.History oracles;
    }

    struct Repo {
        mapping(uint256 => Option) options;
        mapping(uint256 => Record) records;
        EnumerableSet.UintSet seqList;
    }

    // ###############
    // ##  Modifier ##
    // ###############


    modifier optExist(Repo storage repo, uint seqOfOpt) {
        require (isOption(repo, seqOfOpt), "OR.optExist: not");
        _;
    }

    modifier onlyRightholder(Repo storage repo, uint seqOfOpt, uint caller) {
        require (isRightholder(repo, seqOfOpt, caller),
            "OR.mf.onlyRightholder: not");
        _;
    }

    // ###############
    // ## Write I/O ##
    // ###############

    // ==== cofify / parser ====

    function snParser(bytes32 sn) public pure returns (Head memory head) {
        uint _sn = uint(sn);

        head = Head({
            seqOfOpt: uint32(_sn >> 224),
            typeOfOpt: uint8(_sn >> 216),
            classOfShare: uint16(_sn >> 200),
            rate: uint32(_sn >> 168),
            issueDate: uint48(_sn >> 120),
            triggerDate: uint48(_sn >> 72),
            execDays: uint16(_sn >> 56),
            closingDays: uint16(_sn >> 40),
            obligor: uint40(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.seqOfOpt,
                            head.typeOfOpt,
                            head.classOfShare,
                            head.rate,
                            head.issueDate,
                            head.triggerDate,
                            head.execDays,
                            head.closingDays,
                            head.obligor);
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    // ==== Option ====

    function createOption(
        Repo storage repo,
        bytes32 snOfOpt,
        bytes32 snOfCond,
        uint rightholder,
        uint paid,
        uint par
    ) public returns (Head memory head) 
    {
        Option memory opt;

        opt.head = snParser(snOfOpt);
        opt.cond = snOfCond.snParser();

        opt.body.closingDeadline = opt.head.triggerDate + (uint48(opt.head.execDays) + uint48(opt.head.closingDays)) * 86400;
        opt.body.rightholder = uint40(rightholder);
        opt.body.paid = uint64(paid);
        opt.body.par = uint64(par);

        // head = issueOption(repo, opt);
        head = regOption(repo, opt);
    }

    function issueOption(
        Repo storage repo,
        Option memory opt
    ) public returns(uint) {
        Option storage o = repo.options[opt.head.seqOfOpt];

        o.head.issueDate = uint48(block.timestamp);
        o.body.state = uint8(StateOfOpt.Issued);

        return o.head.issueDate;
    }

    function regOption(
        Repo storage repo,
        Option memory opt
    ) public returns(Head memory) {

        require(opt.head.rate > 0, "OR.IO: ZERO rate");

        require(opt.head.triggerDate > block.timestamp, "OR.IO: triggerDate not future");
        require(opt.head.execDays > 0, "OR.IO: ZERO execDays");
        require(opt.head.closingDays > 0, "OR.IO: ZERO closingDays");
        require(opt.head.obligor > 0, "OR.IO: ZERO obligor");

        require(opt.body.rightholder > 0, "OR.IO: ZERO rightholder");
        require(opt.body.paid > 0, "OR.IO: ZERO paid");
        require(opt.body.par >= opt.body.paid, "OR.IO: INSUFFICIENT par");

        opt.head.seqOfOpt = _increaseCounter(repo);

        repo.seqList.add(opt.head.seqOfOpt);

        repo.options[opt.head.seqOfOpt] = opt;
        repo.records[opt.head.seqOfOpt].obligors.add(opt.head.obligor);

        return opt.head;        
    }

    function removeOption(
        Repo storage repo,
        uint seqOfOpt
    ) public returns (bool flag) {

        require (
            repo.options[seqOfOpt].body.state == uint8(StateOfOpt.Pending),
            "OR.removeOption: wrong state" 
        );

        if (repo.seqList.remove(seqOfOpt)) {
            delete repo.options[seqOfOpt];
            flag = true;
        }
    }

    // ==== Record ====

    function addObligorIntoOption(Repo storage repo, uint seqOfOpt, uint256 obligor)
        public returns(bool)
    {
        require (obligor > 0, "OR.AOIO: zero obligor");        
        return repo.records[seqOfOpt].obligors.add(uint40(obligor));
    }

    function removeObligorFromOption(Repo storage repo, uint seqOfOpt, uint256 obligor)
        public returns(bool)
    {
        require (obligor > 0, "OR.ROFO: zero obligor");        
        return repo.records[seqOfOpt].obligors.remove(obligor);
    }

    function addObligorsIntoOption(Repo storage repo, uint seqOfOpt, uint256[] memory obligors)
        public
    {
        Record storage rcd = repo.records[seqOfOpt];
        uint256 len = obligors.length;

        while (len > 0) {
            rcd.obligors.add(uint40(obligors[len-1]));
            len--;
        }
    }

    // ==== ExecOption ====

    function updateOracle(
        Repo storage repo,
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) public optExist(repo, seqOfOpt) {
        repo.records[seqOfOpt].oracles.push(100, d1, d2, d3);
    }

    function execOption(
        Repo storage repo,
        uint256 seqOfOpt,
        uint caller
    ) public onlyRightholder(repo, seqOfOpt, caller) {
        Option storage opt = repo.options[seqOfOpt]; 
        Record storage rcd = repo.records[seqOfOpt];

        require(
            opt.body.state == uint8(StateOfOpt.Issued),
            "OR.EO: wrong state of Opt"
        );
        require(
            block.timestamp >= opt.head.triggerDate,
            "OR.EO: NOT reached TriggerDate"
        );

        require(
            block.timestamp < opt.head.triggerDate + uint48(opt.head.execDays) * 86400,
            "OR.EO: NOT in exercise period"
        );

        if (opt.head.typeOfOpt > uint8(TypeOfOpt.PutRoe)) {
            Checkpoints.Checkpoint memory cp = rcd.oracles.latest();

            if (opt.cond.logicOpr == uint8(CondsRepo.LogOps.ZeroPoint)) { 
                require(opt.cond.checkSoleCond(cp.paid), 
                    "OR.EO: conds not satisfied");
            } else if (opt.cond.logicOpr <= uint8(CondsRepo.LogOps.NotEqual)) {
                require(opt.cond.checkCondsOfTwo(cp.paid, cp.par), 
                    "OR.EO: conds not satisfied");                
            } else if (opt.cond.logicOpr <= uint8(CondsRepo.LogOps.NeOr)) {
                require(opt.cond.checkCondsOfThree(cp.paid, cp.par, cp.cleanPaid), 
                    "OR.EO: conds not satisfied");   
            } else revert("OR.EO: logical operator overflow");
        }

        opt.body.closingDeadline = uint48(block.timestamp) + uint48(opt.head.closingDays) * 86400;
        opt.body.state = uint8(StateOfOpt.Executed);
    }

    // ==== Brief ====

    function createSwap(
        Repo storage repo,
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller,
        IRegisterOfShares _ros
    ) public onlyRightholder(repo, seqOfOpt, caller) returns(SwapsRepo.Swap memory swap) {

        Option storage opt = repo.options[seqOfOpt];

        require(opt.body.state == uint8(StateOfOpt.Executed), "OR.createSwap: wrong state");
        require(block.timestamp < opt.body.closingDeadline, "OR.createSwap: option expired");

        swap.seqOfTarget = uint32(seqOfTarget);
        swap.paidOfTarget = uint64(paidOfTarget);
        swap.seqOfPledge = uint32(seqOfPledge);
        swap.state = uint8(SwapsRepo.StateOfSwap.Issued);

        Record storage rcd = repo.records[opt.head.seqOfOpt];

        SharesRepo.Head memory headOfTarget = _ros.getShare(swap.seqOfTarget).head;
        SharesRepo.Head memory headOfPledge = _ros.getShare(swap.seqOfPledge).head;

        require(opt.head.classOfShare == headOfTarget.class, 
            "OR.createSwap: wrong target class");

        require (opt.body.paid >= rcd.swaps.sumPaidOfTarget() + swap.paidOfTarget, 
            "OR.PS: paidOfTarget overflow");

        if (opt.head.typeOfOpt % 2 == 1) { // Put Option

            require(opt.body.rightholder == headOfTarget.shareholder, 
                "OR.createSwap: rightholder not targetholder");
            require(rcd.obligors.contains(headOfPledge.shareholder), 
                "OR.createSwap: pledge shareholder not obligor");

            swap.isPutOpt = true;

        } else { // Call Opt
            require(opt.body.rightholder == headOfPledge.shareholder, 
                "OR.createSwap: pledge shareholder not rightholder");

            require(rcd.obligors.contains(headOfTarget.shareholder), 
                "OR.createSwap: target shareholder not obligor");
        }

        if (opt.head.typeOfOpt % 4 < 2) 
            swap.priceOfDeal = opt.head.rate;
        else {
            uint32 ds = uint32(((block.timestamp - headOfTarget.issueDate) + 43200) / 86400);
            swap.priceOfDeal = headOfTarget.priceOfPaid * (opt.head.rate * ds + 3650000) / 3650000;  
        }

        if (opt.head.typeOfOpt % 2 == 1) {            
            swap.paidOfPledge = (swap.priceOfDeal - headOfTarget.priceOfPaid) * 
                swap.paidOfTarget / headOfPledge.priceOfPaid;
        }

        return rcd.swaps.regSwap(swap);

    }

    function payOffSwap(
        Repo storage repo,
        uint seqOfOpt,
        uint seqOfSwap,
        uint msgValue,
        uint centPrice
    ) public returns (SwapsRepo.Swap memory ) {

        Option storage opt = repo.options[seqOfOpt];

        require(opt.body.state == uint8(StateOfOpt.Executed), 
            "OR.payOffSwap: wrong state of Opt");
        require(block.timestamp < opt.body.closingDeadline, 
            "OR.payOffSwap: option expired");

        return repo.records[seqOfOpt].swaps.payOffSwap(seqOfSwap, msgValue, centPrice);
    }

    function terminateSwap(
        Repo storage repo,
        uint seqOfOpt,
        uint seqOfSwap
    ) public returns (SwapsRepo.Swap memory){

        Option storage opt = repo.options[seqOfOpt];

        require(opt.body.state == uint8(StateOfOpt.Executed), 
            "OR.terminateSwap: wrong state of Opt");
        require(block.timestamp >= opt.body.closingDeadline, 
            "OR.terminateSwap: still in closing period");

        return repo.records[seqOfOpt].swaps.terminateSwap(seqOfSwap);
    }

    // ==== Counter ====

    function _increaseCounter(Repo storage repo) private returns(uint32 seqOfOpt) {
        repo.options[0].head.seqOfOpt++;
        seqOfOpt = repo.options[0].head.seqOfOpt;
    } 

    // ################
    // ##  查询接口   ##
    // ################

    // ==== Repo ====

    function counterOfOptions(Repo storage repo)
        public view returns (uint32)
    {
        return repo.options[0].head.seqOfOpt;
    }

    function qtyOfOptions(Repo storage repo)
        public view returns (uint)
    {
        return repo.seqList.length();
    }

    function isOption(Repo storage repo, uint256 seqOfOpt) 
        public view returns (bool) 
    {
        return repo.seqList.contains(seqOfOpt);
    }

    function getOption(Repo storage repo, uint256 seqOfOpt) public view 
        optExist(repo, seqOfOpt) returns (OptionsRepo.Option memory option)   
    {
        option = repo.options[seqOfOpt];
    }

    function getAllOptions(Repo storage repo) 
        public view returns (Option[] memory) 
    {
        uint[] memory ls = repo.seqList.values();
        uint256 len = ls.length;
        Option[] memory output = new Option[](len);
        
        while (len > 0) {
            output[len-1] = repo.options[ls[len-1]];
            len--;
        }
        return output;
    }

    function isRightholder(Repo storage repo, uint256 seqOfOpt, uint256 acct) 
        public view optExist(repo, seqOfOpt) returns (bool)
    {
        return repo.options[seqOfOpt].body.rightholder == acct;
    }

    function isObligor(Repo storage repo, uint256 seqOfOpt, uint256 acct) public 
        view optExist(repo, seqOfOpt) returns (bool) 
    {
        return repo.records[seqOfOpt].obligors.contains(acct);
    }

    function getObligorsOfOption(Repo storage repo, uint256 seqOfOpt) public 
        view optExist(repo, seqOfOpt) returns (uint256[] memory)
    {
        return repo.records[seqOfOpt].obligors.values();
    }

    function getSeqList(Repo storage repo) public view returns(uint[] memory) {
        return repo.seqList.values();
    }

    // ==== Order ====

    function counterOfSwaps(Repo storage repo, uint256 seqOfOpt)
        public view returns (uint16)
    {
        return repo.records[seqOfOpt].swaps.counterOfSwaps();
    }

    function sumPaidOfTarget(Repo storage repo, uint256 seqOfOpt)
        public view returns (uint64)
    {
        return repo.records[seqOfOpt].swaps.sumPaidOfTarget();
    }

    function isSwap(Repo storage repo, uint256 seqOfOpt, uint256 seqOfOrder)
        public view returns (bool)
    {
        return repo.records[seqOfOpt].swaps.isSwap(seqOfOrder);
    }

    function getSwap(Repo storage repo, uint256 seqOfOpt, uint256 seqOfSwap)
        public view returns (SwapsRepo.Swap memory)
    {
        return repo.records[seqOfOpt].swaps.getSwap(seqOfSwap);
    }

    function getAllSwapsOfOption(Repo storage repo, uint256 seqOfOpt)
        public view returns (SwapsRepo.Swap[] memory )
    {
        return repo.records[seqOfOpt].swaps.getAllSwaps();
    }

    function allSwapsClosed(Repo storage repo, uint256 seqOfOpt)
        public view returns (bool)
    {
        return repo.records[seqOfOpt].swaps.allSwapsClosed();
    }

    // ==== Oracles ====

    function getOracleAtDate(
        Repo storage repo, 
        uint256 seqOfOpt, 
        uint date
    ) public view optExist(repo, seqOfOpt) 
        returns (Checkpoints.Checkpoint memory)
    {
        return repo.records[seqOfOpt].oracles.getAtDate(date);
    }

    function getLatestOracle(Repo storage repo, uint256 seqOfOpt) 
        public view optExist(repo, seqOfOpt) 
        returns(Checkpoints.Checkpoint memory)
    {
        return repo.records[seqOfOpt].oracles.latest();
    }

    function getAllOraclesOfOption(Repo storage repo, uint256 seqOfOpt)
        public view optExist(repo, seqOfOpt)
        returns (Checkpoints.Checkpoint[] memory) 
    {
        return repo.records[seqOfOpt].oracles.pointsOfHistory();
    }

    function checkValueOfSwap(
        Repo storage repo, 
        uint seqOfOpt, 
        uint seqOfSwap, 
        uint centPrice
    ) public view optExist(repo, seqOfOpt) returns (uint) {
        return repo.records[seqOfOpt].swaps.checkValueOfSwap(seqOfSwap, centPrice);
    }

}
