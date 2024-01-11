pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./FxBaseRootTunnel.sol";
import "./OwnablePausable.sol";

interface MPL {
	function ownerOf(uint256 tokenId) external view returns(address);
    function getShuffledId(uint256 tokenId) external view returns(uint256);
}

contract BootcampBridge is FxBaseRootTunnel, OwnablePausable {

    address public mpl;

    event Bridged(uint256[] tokenIds, address recipient);

    constructor(address _checkpointManager, address _fxRoot, address _mpl, address _bootCampPlayer)
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
    {
        mpl = _mpl;
        setFxChildTunnel(_bootCampPlayer);
    }

    function safeClaimPlayers(uint256[] memory tokenIds) public {
        require(msg.sender.code.length == 0, "Safe: contract may not exist on child chain");
        require(tokenIds.length <= 120, "Safe: too many tokens");
        claimPlayers(tokenIds, msg.sender);
    }

    function claimPlayers(uint256[] memory tokenIds) public {
        claimPlayers(tokenIds, msg.sender);
    }

    function claimPlayers(uint256[] memory tokenIds, address recipient) public whenNotPaused {
        uint256[] memory characterIds = new uint256[](tokenIds.length);
        for(uint i; i < tokenIds.length; i++){
            require(MPL(mpl).ownerOf(tokenIds[i]) == msg.sender, "ERC721: Not token owner");
            characterIds[i] = MPL(mpl).getShuffledId(tokenIds[i]);
        }
        _sendMessageToChild(abi.encode(characterIds, recipient));
        emit Bridged(tokenIds, recipient);
    }

	function _processMessageFromChild(bytes memory message) virtual internal override{}
}
