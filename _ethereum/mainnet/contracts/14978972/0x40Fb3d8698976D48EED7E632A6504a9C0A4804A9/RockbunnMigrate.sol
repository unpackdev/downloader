// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Rbn.sol";
import "./Rbm.sol";
import "./ERC721A.sol";
import "./console.sol";

contract RockbunnMigrate is Ownable, ReentrancyGuard {

    Rbn private immutable rbn;
    Rbm private immutable rbm;
    bool public _paused = true;
    address t1 = 0x5b137804dfa92CEd576595b73C3cB1F4258747d3; // Community Manager

    constructor(address rbnAddress, address rbmAddress) {
        rbn = Rbn(rbnAddress);
        rbm = Rbm(rbmAddress);
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function MigrateAllMusic() public nonReentrant {
        require( !_paused, "Migrate paused" );
        uint256[] memory tokensId = rbn.walletOfOwner(msg.sender);
        for(uint256 i; i < tokensId.length; i++){
            rbn.transferFrom(msg.sender, t1, tokensId[i]);
            rbm.transferFrom(t1, msg.sender, tokensId[i]);
        }
    }

    function MigrateMusicTokens(uint256[] memory _tokenIds) public nonReentrant {
        require( !_paused, "Migrate paused" );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(rbn.ownerOf(_tokenId) == msg.sender,"You are not owner of this token");
            rbn.transferFrom(msg.sender, t1, _tokenId);
            rbm.transferFrom(t1, msg.sender, _tokenId);
        }
    }
}