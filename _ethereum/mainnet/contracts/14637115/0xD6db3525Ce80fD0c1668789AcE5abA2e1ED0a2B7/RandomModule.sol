pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: GPL-3.0-or-later

import "./Ownable.sol";
import "./IRNG.sol";

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

interface Itoken {
    function setStart1(
        uint256 __start1,
        bool _status,
        string memory _stingSome
    ) external;
}

contract RandomModule is Ownable {
    IRNG public _iRnd;
    bytes32 _reqID;
    uint256 public _randomCL;
    uint256 public _start1;
    uint256 public localModulo;

    constructor(IRNG _rng,uint256 _localModulo) {
        _iRnd = _rng;
        localModulo=_localModulo;
    }

    function setNewRND(IRNG _rng) external onlyOwner {
        _iRnd = _rng;
    }

    function setlocalModulo(uint256 _localModulo) external onlyOwner {
            localModulo=_localModulo;
    }

    // 1
    function getRandom() external onlyOwner {
        _reqID = _iRnd.requestRandomNumberWithCallback();
    }

    function process(uint256 random, bytes32 reqID) external {
        require(msg.sender == address(_iRnd), "Unauthorised RNG");
        if (_reqID == reqID) {
            _randomCL = random / 2; // set msb to zero
            _start1 = _randomCL % (localModulo);
        } else revert("Incorrect request ID sent");
    }

    function reveal(
        address _tokenContract,
        bool _status,
        string memory _metaDataString
    ) external onlyOwner {
        Itoken(_tokenContract).setStart1(_start1, _status, _metaDataString);
    }

    function transferTokenOwnership(address _target, address _newOwner)
        external
        onlyOwner
    {
        IOwnable(_target).transferOwnership(_newOwner);
    }

    function nTimesCalls(
        uint64 _times,
        address target,
        bytes[] calldata data
    ) public onlyOwner {
        for (uint64 j = 0; j < (_times); j++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = target.call(data[j]);
            require(success, "excution failed.");
        }
    }
}
