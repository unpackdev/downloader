pragma solidity ^0.5.16;

interface Ixinv {
    function _acceptAdmin() external returns (uint);
    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    function _setComptroller(address newComptroller) external returns (uint);
    function _setRewardTreasury(address newRewardTreasury) external returns (uint);
    function _setRewardPerBlock(uint newRewardPerBlock) external returns (uint);
}

contract XinvManager {
    
    Ixinv public xinv;
    address public governance;
    address public policyCommittee;
    uint public maxRewardPerBlock = uint(-1);

    constructor(Ixinv _xinv, address _governance, address _policyCommittee) public {
        xinv = _xinv;
        governance = _governance;
        policyCommittee = _policyCommittee;
    }

    modifier onlyGov {
        require(msg.sender == governance, "ONLY GOVERNANCE");
        _;
    }

    function changeGovernance(address _governance) external onlyGov {
        require(_governance != address(0), "GOVERNANCE CANNOT BE ADDRESS 0");
        governance = _governance;
    }

    function changePolicyCommittee(address _policyCommittee) external onlyGov {
        require(_policyCommittee != address(0), "POLICY COMMITTEE CANNOT BE ADDRESS 0");
        policyCommittee = _policyCommittee;
    }

    function _acceptAdmin() external onlyGov {
        xinv._acceptAdmin();
    }

    function _setPendingAdmin(address payable newPendingAdmin) external onlyGov {
        xinv._setPendingAdmin(newPendingAdmin);
    }

    function _setComptroller(address newComptroller) external onlyGov {
        xinv._setComptroller(newComptroller);
    }

    function _setRewardTreasury(address newRewardTreasury) external onlyGov {
        xinv._setRewardTreasury(newRewardTreasury);
    }

    function _setRewardPerBlock(uint newRewardPerBlock) external {
        require(msg.sender == policyCommittee || msg.sender == governance, "ONLY POLICY COMMITTEE OR GOVERNANCE");
        require(newRewardPerBlock <= maxRewardPerBlock, "NEW REWARD RATE EXCEEDS MAX");
        xinv._setRewardPerBlock(newRewardPerBlock);
    }

    function setMaxRewardPerBlock(uint _maxRewardPerBlock) external onlyGov {
        maxRewardPerBlock = _maxRewardPerBlock;
    }
}