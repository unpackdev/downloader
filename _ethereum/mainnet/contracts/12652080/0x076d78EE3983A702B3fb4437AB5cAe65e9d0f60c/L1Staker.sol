// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./FxBaseRootTunnel.sol";

interface IRootChainManager{
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;
}

contract L1Staker is FxBaseRootTunnel, Ownable, Pausable {
    
    IRootChainManager public rootChainManager;
    address public erc20Predicate;
    address public cntToken;
    
    event InitiatedCrossChainStaking(address indexed user, uint256 indexed stakedAmount);

    constructor (IRootChainManager _rootChainManager,
        address _erc20Predicate,
        address _cntToken,
        address _checkpointManager,
        address _fxRoot
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot)
    {
        rootChainManager = IRootChainManager(_rootChainManager);
        erc20Predicate = _erc20Predicate;
        cntToken = _cntToken;
    }
    
    function stakeCrossChain (uint256 amount) public whenNotPaused{
        require(
            fxChildTunnel != address(0x0),
            "CHILD_TUNNEL_NOT_SET"
        );
        IERC20(cntToken).transferFrom(msg.sender, address(this), amount);
        IERC20(cntToken).approve(erc20Predicate, amount);
        
        bytes memory depositData = abi.encode(amount);
        rootChainManager.depositFor(fxChildTunnel,cntToken,depositData);
        
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                amount
            )
        );
        
        emit InitiatedCrossChainStaking(msg.sender, amount);
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function _processMessageFromChild(bytes memory message) internal override {}
}