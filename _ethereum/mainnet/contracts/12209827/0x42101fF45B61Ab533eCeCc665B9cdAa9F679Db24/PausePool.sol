// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


contract PausePool{
    
    mapping(uint256 => bool) private pausedPool;

    event PoolPaused(uint256 indexed _pid, bool _paused);

    modifier whenNotPaused(uint256 _pid) {
        require(!pausedPool[_pid], "Pausable: paused");
        _;
    }

    function pausePoolViaPid(uint256 _pid, bool _paused) internal {
        pausedPool[_pid] = _paused;
        emit PoolPaused(_pid, _paused);
    }
}
