// SPDX-License-Identifier: MIT

/*

  by             .__________                 ___ ___
  __  _  __ ____ |__\_____  \  ___________  /   |   \_____    ______ ____
  \ \/ \/ // __ \|  | _(__  <_/ __ \_  __ \/    ~    \__  \  /  ___// __ \
   \     /\  ___/|  |/       \  ___/|  | \/\    Y    // __ \_\___ \\  ___/
    \/\_/  \___  >__/______  /\___  >__|    \___|_  /(____  /____  >\___  >
               \/          \/     \/              \/      \/     \/     \/

*/

pragma solidity >=0.8.4 <0.9.0;

import "./Governable.sol";
import "./Keep3rJob.sol";

import "./IERC721Receiver.sol";

interface IChess {
  function board() external returns (uint256 _board);

  function mintMove(uint256 _move, uint256 _depth) external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external;
}

contract Kasparov is Governable, Keep3rJob, IERC721Receiver {
  address constant internal fiveOutOfNine = 0xB543F9043b387cE5B3d1F0d916E42D8eA2eBA2E0;
  
  uint256 internal board;
  uint256[] internal moves;
  uint256 internal nextMove;
  uint256 internal depth = 3;

  error UnknownBoard();
  error NoMoves();
  error UnknownNFT();

  constructor() Governable(msg.sender) {}

  function work() external upkeep {
    if (nextMove == moves.length) revert NoMoves();
    _checkBoard();
    _playNextMove();
  }

  function workMany(uint256 j) external upkeep {
    _checkBoard();
    if (j == 0) revert NoMoves();
    for (uint256 i = 0; i < j; i++) {
      _playNextMove();
    }
  }

  // Governable

  function addMoves(uint256[] memory _moves, bool _append) external onlyGovernor {
    if (!_append) {
      delete moves;
      delete nextMove;
    }
    for (uint256 i = 0; i < _moves.length; i++) {
      moves.push(_moves[i]);
    }
    board = IChess(fiveOutOfNine).board();
  }

  function setDepth(uint256 _depth) external onlyGovernor {
    depth = _depth;
  }

  // Internal

  function _playNextMove() internal {
    IChess(fiveOutOfNine).mintMove(moves[nextMove++], depth);
    board = IChess(fiveOutOfNine).board();
  }

  function _checkBoard() internal {
    uint256 _actualBoard = IChess(fiveOutOfNine).board();
    if (board != _actualBoard) revert UnknownBoard();
  }

  // @dev Transfers ERC721 to owner on reception
  function onERC721Received(
    address,
    address,
    uint256 _tokenId,
    bytes memory
  ) external override returns (bytes4) {
    if (msg.sender != fiveOutOfNine) revert UnknownNFT();
    IChess(fiveOutOfNine).transferFrom(address(this), governor, _tokenId);
    return 0x150b7a02;
  }
}
