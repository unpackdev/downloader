pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./FxBaseRootTunnel.sol";
import "./OwnablePausable.sol";

interface MPL {
	function ownerOf(uint256 tokenId) external view returns(address);
}

contract MarsUBIBridge is FxBaseRootTunnel, OwnablePausable {

    address public mpl;
    uint256 public limit = 120;
    uint256 public claimId = 1;

    event Bridged(uint256[] tokenIds, address recipient, uint256 claimId);

    constructor(address _checkpointManager, address _fxRoot, address _mpl, address _marsUBI)
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
    {
        mpl = _mpl;
        setFxChildTunnel(_marsUBI);
    }

    function safeClaimUBI(uint256[] calldata tokenIds) public {
        require(msg.sender.code.length == 0, "Safe: contract may not exist on child chain");
        claimUBI(tokenIds, msg.sender);
    }

    function setLimit(uint256 _limit) public onlyOwner {
        limit = _limit;
    }
    
    // @notice helper min function
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function claimUBI(uint256[] calldata tokenIds, address recipient) public whenNotPaused {
        
        for(uint i; i < tokenIds.length; i++){
            require(MPL(mpl).ownerOf(tokenIds[i]) == msg.sender, "ERC721: Not token owner");
        }

        uint start;
        while (start < tokenIds.length) {
            uint end = min(start + limit, tokenIds.length);
            _sendMessageToChild(abi.encode(tokenIds[start:end], recipient, claimId));
            start += limit;
        }

        emit Bridged(tokenIds, recipient, claimId);
        claimId = claimId + 1;
    }

	  function _processMessageFromChild(bytes memory message) virtual internal override{}
}
