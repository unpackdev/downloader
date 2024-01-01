// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import "./IOptions.sol";
import "./OptionsRepo.sol";
import "./SwapsRepo.sol";

pragma solidity ^0.8.8;

interface IRegisterOfOptions {

    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(uint256 indexed seqOfOpt, bytes32 indexed codeOfOpt);

    event IssueOpt(uint256 indexed seqOfOpt, uint indexed issueDate);

    event AddObligorIntoOpt(uint256 indexed seqOfOpt, uint256 indexed obligor);

    event RemoveObligorFromOpt(uint256 indexed seqOfOpt, uint256 indexed obligor);

    event UpdateOracle(uint256 indexed seqOfOpt, uint indexed data1, uint indexed data2, uint data3);

    event ExecOpt(uint256 indexed seqOfOpt);

    event RegSwap(uint256 indexed seqOfOpt, bytes32 indexed snOfSwap);

    event PayOffSwap(uint256 indexed seqOfOpt, bytes32 indexed snOfSwap);

    event TerminateSwap(uint256 indexed seqOfOpt, uint indexed seqOfSwap);

    // ################
    // ##   Write    ##
    // ################

    function createOption(
        bytes32 sn,
        bytes32 snOfCond,
        uint rightholder,
        uint paid,
        uint par
    ) external returns(OptionsRepo.Head memory head);

    function issueOption(OptionsRepo.Option memory opt) external;

    function regOptionTerms(address opts) external;

    function addObligorIntoOption(uint256 seqOfOpt, uint256 obligor) external;

    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor) external;

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external;

    function execOption(uint256 seqOfOpt, uint caller) external;

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller
    ) external returns (SwapsRepo.Swap memory swap);

    function payOffSwap(
        uint seqOfOpt,
        uint seqOfSwap,
        uint msgValue,
        uint centPrice
    ) external returns (SwapsRepo.Swap memory swap);

    function terminateSwap(
        uint seqOfOpt,
        uint seqOfSwap
    ) external returns (SwapsRepo.Swap memory swap);
    
    // ################
    // ##  查询接口   ##
    // ################

    function counterOfOptions() external view returns (uint32);

    function qtyOfOptions() external view returns (uint);

    function isOption(uint256 seqOfOpt) external view returns (bool);

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory opt);

    function getAllOptions() external view returns (OptionsRepo.Option[] memory);

    function isRightholder(uint256 seqOfOpt, uint256 acct) external view returns (bool);

    function isObligor(uint256 seqOfOpt, uint256 acct) external view returns (bool);

    function getObligorsOfOption(uint256 seqOfOpt)
        external view returns (uint256[] memory);

    function getSeqListOfOptions() external view returns(uint[] memory);

    // ==== Swap ====
    function counterOfSwaps(uint256 seqOfOpt)
        external view returns (uint16);

    function sumPaidOfTarget(uint256 seqOfOpt)
        external view returns (uint64);

    function isSwap(uint256 seqOfOpt, uint256 seqOfSwap)
        external view returns (bool); 

    function getSwap(uint256 seqOfOpt, uint256 seqOfSwap)
        external view returns (SwapsRepo.Swap memory swap);

    function getAllSwapsOfOption(uint256 seqOfOpt)
        external view returns (SwapsRepo.Swap[] memory);

    function allSwapsClosed(uint256 seqOfOpt)
        external view returns (bool);

    // ==== oracles ====

    function getOracleAtDate(uint256 seqOfOpt, uint date)
        external view returns (Checkpoints.Checkpoint memory);

    function getLatestOracle(uint256 seqOfOpt) external 
        view returns(Checkpoints.Checkpoint memory);

    function getAllOraclesOfOption(uint256 seqOfOpt)
        external view returns (Checkpoints.Checkpoint[] memory);

    // ==== Value ====

    function checkValueOfSwap(uint seqOfOpt, uint seqOfSwap)
        external view returns (uint);
    
}
