// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC165.sol";
import "./Ownable.sol";

import "./Errors.sol";
import "./IRelayerManager.sol";

contract RelayerManager is ERC165, Ownable, IRelayerManager {
    mapping(address => Pool) private _rpoolsAddrs;
    address[] private _rpools;

    bytes32 public immutable override appId; // app id for fee processing
    uint256 public immutable blockDelta; // blocks delta

    constructor(bytes32 _appId, uint256 _blockDelta) {
        appId = _appId;
        blockDelta = _blockDelta;
    }

    function addRelayer(address relAddr) public override onlyOwner {
        require(relAddr != address(0), Errors.B_ZERO_ADDRESS);
        require(
            _rpoolsAddrs[relAddr].addr == address(0),
            Errors.B_ENTITY_EXIST
        );

        _rpools.push(relAddr);
        _rpoolsAddrs[relAddr] = Pool(
            relAddr,
            _rpools.length - 1,
            block.timestamp,
            0
        );
        emit RelayerAdded(relAddr);
    }

    function addRelayerBatch(
        address[] calldata relAddrs
    ) public override onlyOwner {
        for (uint256 i = 0; i < relAddrs.length; i++) {
            addRelayer(relAddrs[i]);
        }
    }

    function removeRelayer(address relAddr) public override onlyOwner {
        require(relAddr != address(0), Errors.B_ZERO_ADDRESS);
        Pool memory pool = _rpoolsAddrs[relAddr];
        require(pool.addr != address(0), Errors.B_ENTITY_NOT_EXIST);

        if (_rpools.length > 1) {
            // move last to rm slot
            _rpools[pool.index] = _rpools[_rpools.length - 1];
            _rpools.pop();

            // change indexing
            address poolAddrLast = _rpools[pool.index];
            _rpoolsAddrs[poolAddrLast].index = pool.index;
        } else {
            // just remove it as 1 left
            _rpools.pop();
        }

        delete _rpoolsAddrs[pool.addr];

        emit RelayerRemoved(relAddr);
    }

    function removeRelayerBatch(
        address[] calldata relAddrs
    ) public override onlyOwner {
        for (uint256 i = 0; i < relAddrs.length; i++) {
            removeRelayer(relAddrs[i]);
        }
    }

    function getRelayer(uint256 index) public view override returns (address) {
        return _rpools[index];
    }

    function getRelayers() public view override returns (address[] memory) {
        return _rpools;
    }

    function pickRelayer(bytes32 seed) public view override returns (address) {
        uint256 index = _getRandomIndex(
            uint256(seed),
            block.number,
            blockDelta,
            _rpools.length
        );
        return _rpools[index];
    }

    function getRandomIndex(
        uint256 rk,
        uint256 height,
        uint256 delta,
        uint256 length
    ) public pure returns (uint256) {
        return _getRandomIndex(rk, height, delta, length);
    }

    function _getRandomIndex(
        uint256 rk,
        uint256 height,
        uint256 delta,
        uint256 length
    ) private pure returns (uint256) {
        rk = _deltaRoundDown(rk, delta);
        uint256 pseudoHeight;
        unchecked {
            pseudoHeight = rk - height - 1;
        }
        pseudoHeight = _deltaRoundDown(pseudoHeight, delta);

        uint256 random = uint256(keccak256(abi.encodePacked(pseudoHeight)));
        return random % length;
    }

    function _deltaRoundDown(
        uint256 n,
        uint256 delta
    ) private pure returns (uint256) {
        if (n < delta) {
            return 0;
        }
        uint256 dev = n % delta;
        if (dev != 0) {
            n = n - dev;
        }
        return n;
    }
}
