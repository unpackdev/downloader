// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./DeepSkyNetwork.sol";
import "./TheLostGlitches.sol";
import "./IGatekeeper.sol";

contract Syndicates is Ownable {
    string constant name = "The Lost Glitches Syndicates";
    string constant symbol = "SYN";

    TheLostGlitches public tlg;
    DeepSkyNetwork public dsn;
    IGatekeeper public gatekeeper;

    mapping(uint256 => uint256) public syndicate;
    mapping(uint256 => mapping(uint256 => uint256)) private members;
    mapping(uint256 => uint256) public memberCount;
    event joinedSyndicate(address _from, uint256 _syndicate, uint256 _glitch);

    constructor(address _tlg, address _dsn) {
        tlg = TheLostGlitches(_tlg);
        dsn = DeepSkyNetwork(_dsn);
    }

    function setGatekeeper(address _gatekeeper) public onlyOwner {
        gatekeeper = IGatekeeper(_gatekeeper);
    }

    function syndicates(uint256 id) public pure returns (string memory description) {
        if (id == 1) {
            return "Song of the Chain";
        } else if (id == 2) {
            return "Curators Maxima";
        } else if (id == 3) {
            return "Adamant Hands";
        } else if (id == 4) {
            return "Sentinels of Eternity";
        } else if (id == 5) {
            return "Guardians of the Source";
        }
    }

    function join(uint256 _syndicate, uint256 _glitch) public {
        require(1 <= _syndicate && _syndicate <= 5, "SYNDICATE: INVALID_SYNDICATE");
        require(_isApprovedOrOwner(msg.sender, _glitch), "THE_LOST_GLITCHES: NOT_APPROVED");
        require(syndicate[_glitch] == 0, "SYNDICATE: ALREADY_JOINED");

        if (_syndicate == 5) {
            require(address(gatekeeper) != address(0), "SYNDICATE: GATEKEEPER_NOT_PRESENT");
            require(gatekeeper.allowed(msg.sender, _glitch), "GATEKEEPER: NOT_QUALIFIED");
        }

        _join(_syndicate, _glitch);
    }

    function memberOfSyndicateByIndex(uint256 _syndicate, uint256 index) public view virtual returns (uint256) {
        require(index <= memberCount[_syndicate], "SYNDICATE: INDEX OUT OF BOUNDS");
        return members[_syndicate][index];
    }

    function _join(uint256 _syndicate, uint256 _glitch) internal {
        syndicate[_glitch] = _syndicate;
        memberCount[_syndicate] += 1;
        uint256 length = memberCount[_syndicate];
        members[_syndicate][length] = _glitch;
        emit joinedSyndicate(msg.sender, _syndicate, _glitch); // TODO Naming Convention
    }

    function _isApprovedOrOwner(address operator, uint256 glitch) internal view virtual returns (bool) {
        require(tlg.exists(glitch), "ERC721: operator query for nonexistent token");
        address owner = tlg.ownerOf(glitch);
        return (operator == owner || tlg.getApproved(glitch) == operator || tlg.isApprovedForAll(owner, operator));
    }
}
