// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfOptions.sol";

import "./AccessControl.sol";

contract RegisterOfOptions is IRegisterOfOptions, AccessControl {
    using OptionsRepo for OptionsRepo.Repo;

    OptionsRepo.Repo private _repo;

    // ################
    // ## Write I/O ##
    // ################

    function createOption(
        bytes32 sn,
        bytes32 snOfCond,
        uint rightholder,
        uint paid,
        uint par
    ) external onlyKeeper returns(OptionsRepo.Head memory head) {
        head = _repo.createOption(sn, snOfCond, rightholder, paid, par);
        emit CreateOpt(head.seqOfOpt, OptionsRepo.codifyHead(head));
    }

    function issueOption(OptionsRepo.Option memory opt) external onlyKeeper 
    {
        uint issueDate = _repo.issueOption(opt);
        emit IssueOpt(opt.head.seqOfOpt, issueDate);
    }

    function regOptionTerms(address opts) external onlyKeeper {

        OptionsRepo.Option[] memory optsList = IOptions(opts).getAllOptions();

        uint len = optsList.length;

        while (len > 0) {
            OptionsRepo.Option memory opt = optsList[len - 1]; 

            opt.head.issueDate = uint48(block.timestamp);
            opt.body.state = uint8(OptionsRepo.StateOfOpt.Issued);

            uint256[] memory obligors = 
                IOptions(opts).getObligorsOfOption(opt.head.seqOfOpt);

            opt.head = _repo.regOption(opt);

            _repo.addObligorsIntoOption(opt.head.seqOfOpt, obligors);

            emit CreateOpt(opt.head.seqOfOpt, OptionsRepo.codifyHead(opt.head));

            len--;
        }
    }

    function addObligorIntoOption(uint256 seqOfOpt, uint256 obligor) external onlyDK {
        if (_repo.addObligorIntoOption(seqOfOpt, obligor))
            emit AddObligorIntoOpt(seqOfOpt, obligor);
    }

    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor) external onlyDK {
        if (_repo.removeObligorFromOption(seqOfOpt, obligor))
            emit RemoveObligorFromOpt(seqOfOpt, obligor);
    }

    // ==== Exec Option ====

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external onlyDK {
        _repo.updateOracle(seqOfOpt, d1, d2, d3);
        emit UpdateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt, uint caller) external onlyKeeper {
        _repo.execOption(seqOfOpt, caller);
        emit ExecOpt(seqOfOpt);
    }

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller
    ) external onlyKeeper returns (SwapsRepo.Swap memory swap) {
        swap = _repo.createSwap(seqOfOpt, seqOfTarget, paidOfTarget, seqOfPledge, caller, _gk.getROS());
        emit RegSwap(seqOfOpt, SwapsRepo.codifySwap(swap));
    }

    function payOffSwap(
        uint seqOfOpt,
        uint seqOfSwap,
        uint msgValue,
        uint centPrice
    ) external returns (SwapsRepo.Swap memory swap) {
        swap = _repo.payOffSwap(seqOfOpt, seqOfSwap, msgValue, centPrice);
        emit PayOffSwap(seqOfOpt, SwapsRepo.codifySwap(swap));
    }

    function terminateSwap(
        uint seqOfOpt,
        uint seqOfSwap
    ) external returns (SwapsRepo.Swap memory swap){
        swap = _repo.terminateSwap(seqOfOpt, seqOfSwap);
        emit TerminateSwap(seqOfOpt, seqOfSwap);
    }

    // ################
    // ##  查询接口   ##
    // ################

    // ==== Option ====

    function counterOfOptions() external view returns (uint32) {
        return _repo.counterOfOptions();
    }

    function qtyOfOptions() external view returns (uint) {
        return _repo.qtyOfOptions();
    }

    function isOption(uint256 seqOfOpt) public view returns (bool) {
        return _repo.isOption(seqOfOpt);
    }

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory opt)
    {
        opt = _repo.getOption(seqOfOpt);
    }

    function getAllOptions() external view 
        returns (OptionsRepo.Option[] memory) 
    {
        return _repo.getAllOptions();
    }

    function isRightholder(uint256 seqOfOpt, uint256 acct) 
        external view returns (bool)
    {
        return _repo.isRightholder(seqOfOpt, acct);
    }

    function isObligor(uint256 seqOfOpt, uint256 acct) external view
        returns (bool) 
    { 
        return _repo.isObligor(seqOfOpt, acct);
    }

    function getObligorsOfOption(uint256 seqOfOpt)
        external view returns (uint256[] memory)
    {
        return _repo.getObligorsOfOption(seqOfOpt);
    }

    function getSeqListOfOptions() external view returns(uint[] memory) {
        return _repo.getSeqList();
    }

    // ==== Swap ====
    function counterOfSwaps(uint256 seqOfOpt)
        external view returns (uint16) 
    {
        return _repo.counterOfSwaps(seqOfOpt);
    }

    function sumPaidOfTarget(uint256 seqOfOpt)
        external view returns (uint64) 
    {
        return _repo.sumPaidOfTarget(seqOfOpt);
    }

    function isSwap(uint256 seqOfOpt, uint256 seqOfSwap)
        public view returns (bool) 
    {
        return _repo.isSwap(seqOfOpt, seqOfSwap);
    }

    function getSwap(uint256 seqOfOpt, uint256 seqOfSwap)
        external view returns (SwapsRepo.Swap memory)
    {
        return _repo.getSwap(seqOfOpt, seqOfSwap);
    }

    function getAllSwapsOfOption(uint256 seqOfOpt)
        external view returns (SwapsRepo.Swap[] memory)
    {
        return _repo.getAllSwapsOfOption(seqOfOpt);
    }

    function allSwapsClosed(uint256 seqOfOpt)
        external view returns (bool)
    {
        return _repo.allSwapsClosed(seqOfOpt);
    }

    // ==== Oracles ====

    function getOracleAtDate(uint256 seqOfOpt, uint date)
        external
        view
        returns (Checkpoints.Checkpoint memory)
    {
        return _repo.getOracleAtDate(seqOfOpt, date);
    }

    function getLatestOracle(uint256 seqOfOpt) external 
        view returns(Checkpoints.Checkpoint memory)
    {
        return _repo.getLatestOracle(seqOfOpt);
    }

    function getAllOraclesOfOption(uint256 seqOfOpt)
        external
        view
        returns (Checkpoints.Checkpoint[] memory) 
    {
        return _repo.getAllOraclesOfOption(seqOfOpt);
    }

    // ==== Value ====

    function checkValueOfSwap(uint seqOfOpt, uint seqOfSwap)
        external view returns (uint)
    {
        return _repo.checkValueOfSwap(seqOfOpt, seqOfSwap, _gk.getCentPrice());
    }

}
