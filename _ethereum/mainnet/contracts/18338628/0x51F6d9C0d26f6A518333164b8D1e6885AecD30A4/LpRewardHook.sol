// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IVoterProxy.sol";
import "./IBooster.sol";


//hook that claims fees
contract LpRewardHook{

    address public constant voteproxy = address(0xd11a4Ee017cA0BECA8FA45fF2abFe9C6267b7881);
    address public constant hookManager = address(0x723f9Aa67FDD9B0e375eF8553eB2AFC28eCD4a96);

    constructor() {}

    function getReward(address) external{
        require(msg.sender == hookManager,"!auth");

        //ask the current operator to claim fees
        IBooster(IVoterProxy(voteproxy).operator()).claimFees();
    }

}