pragma solidity ^0.8.7;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./Ownable.sol";
import "./IRNG.sol";
import "./console.sol";

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

interface Itoken {
    function setStart1( uint256 __start1, bool _status, string memory _stingSome) external;
    function totalSupply() external view returns (uint256);
    function uri(uint256) external view returns (uint256);
    function owner() external view returns (address);
}

contract RevealOne is Ownable {
    IRNG public _iRnd;
    bytes32 public _reqID;

    uint256 public _randomCL;
    uint256 public _start1;
    uint256 public _stop1;
    uint256 public _ts1; // total supply when baseURI set
    bool    public _randomReceived;

    Itoken  public tokenContract;
    string  public metaDataString;
    uint256 public tokenSupply;

    event RandomProcessed(
        uint256 randUsed_,
        uint256 _start,
        uint256 _stop,
        uint256 _supply
    );

    constructor(IRNG _rng) {
        _iRnd = _rng;
    }

    function requestReveal(
        address _tokenContract,
        string calldata revealedBaseURI,
        uint256 _maxSupply
    ) external onlyOwner {

        tokenContract = Itoken(_tokenContract);

        require(address(this) == tokenContract.owner(), "RM: Contract not owner of token contract");

        metaDataString = revealedBaseURI;
        tokenSupply = _maxSupply;
        _ts1 = tokenContract.totalSupply();
        _stop1 = tokenContract.uri(_ts1);
        _reqID = _iRnd.requestRandomNumberWithCallback();
    }

    function process(uint256 random, bytes32 reqID) external {
        require(msg.sender == address(_iRnd), "RM: Unauthorised RNG");
        if (_reqID == reqID) {
            _randomCL = random / 2; // set msb to zero
            _start1 = _randomCL % tokenSupply;
            _randomReceived = true;
        } else revert("RM: Incorrect request ID received");
    }

    function reveal() external onlyOwner {
        require(_randomReceived, "RM: RNG not received");
        Itoken(tokenContract).setStart1(_start1, _randomReceived, metaDataString);
        emit RandomProcessed(_randomCL, _start1, _stop1, _ts1);
    }

    function transferTokenOwnership(address _target, address _newOwner) external onlyOwner {
        IOwnable(_target).transferOwnership(_newOwner);
    }

}
