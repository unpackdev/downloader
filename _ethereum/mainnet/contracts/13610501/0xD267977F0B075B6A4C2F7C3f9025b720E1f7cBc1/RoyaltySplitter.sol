// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ERC165.sol";
import "./ERC165Checker.sol";

interface IRoyaltySplitter {
    function initiate(address[] memory participants, uint256[] memory cuts, string[] memory participantsNames, string memory _name) external;
    function distributeFunds(address token) external;
}

contract RoyaltySplitter is IRoyaltySplitter, IERC165, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct ParticipantCut {
        address participant;
        uint256 cut;
        string name;
        bool isRoyaltySplitter;
    }

    bool private _initialized;
    string public name;
    ParticipantCut[] public participantsCut;

    event ParticipantAdded(address indexed participant);

    function initiate(address[] memory participants, uint256[] memory cuts, string[] memory participantsNames, string memory _name) override external {
        name = _name;
        require(!_initialized, "Come on");
        _initialized = true;
        require(participants.length == cuts.length, "Mismatch lengths");
        require(participants.length > 0, "No participants");
        uint256 sum;
        for (uint256 i; i < participants.length; i++) {
            participantsCut.push(
                ParticipantCut(
                    participants[i],
                    cuts[i],
                    participantsNames[i],
                    ERC165Checker.supportsInterface(participants[i], type(IRoyaltySplitter).interfaceId)
                )
            );
            sum += cuts[i];
            emit ParticipantAdded(participants[i]);
        }
        require(sum == 100, "Wrong percentage");
    }

    function distributeFunds(address token) override external nonReentrant {
        uint256 balance;
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
        require(balance > 0, "No money");
        for (uint256 i; i < participantsCut.length; i++) {
            ParticipantCut memory participantCut = participantsCut[i];
            uint256 cut = (balance * participantCut.cut) / 100;
            if (token == address(0)) {
                Address.sendValue(payable(participantCut.participant), cut);
            } else {
                IERC20(token).safeTransfer(participantCut.participant, cut);
            }
            if (participantCut.isRoyaltySplitter) {
                IRoyaltySplitter(participantCut.participant).distributeFunds(token);
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IRoyaltySplitter).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function getParticipantsCut() external view virtual returns (ParticipantCut[] memory) {
        return participantsCut;
    }

    receive() external payable {}
}
