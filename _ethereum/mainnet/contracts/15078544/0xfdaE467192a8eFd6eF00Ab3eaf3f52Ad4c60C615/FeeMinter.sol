// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";

import "./Percent.sol";
import "./OwnableTimelock.sol";

contract FeeMinter is Ownable, OwnableTimelock {
    /// Overall rate at which to mint new tokens
    uint256 public totalToMintPerBlock;

    /// Owner approved minters with assigned toMintPercents
    address[] public minters;

    /// Decimal points of precision to use with percents
    uint256 public decimals;

    // Version of the toMintPercent mapping
    uint32 private _version;
    
    // Map approved minter address to a percent of totalToMintPerBlock rate
    mapping(bytes32 => uint256) private _toMintPercent;

    // Emitted when a new totalToMintPerBlock is set
    event SetTotalToMintPerBlock(address indexed setter, uint256 indexed totalToMintPerBlock);

    // Emitted whan decimals is set
    event SetDecimals(address indexed sender, uint256 indexed decimals);

    // Emitted when new minters are assigned toMintPercents
    event SetToMintPercents(
        address indexed setter,
        address[] indexed minters,
        uint256[] indexed toMintPercents,
        uint32 version
    );

    constructor(uint256 _totalToMintPerBlock) {
        totalToMintPerBlock = _totalToMintPerBlock;
        decimals = 2;   // default to 2 decimals of precision, i.e. 100.00%
    }

    /// Set the _totalToMintPerBlock rate
    function setTotalToMintPerBlock(uint256 _totalToMintPerBlock) external onlyTimelock {
        totalToMintPerBlock = _totalToMintPerBlock;
        emit SetTotalToMintPerBlock(msg.sender, _totalToMintPerBlock);
    }

    /// Set the toMintPercent for each minter in _minters
    function setToMintPercents(address[] calldata _minters, uint256[] calldata _toMintPercents) 
        external 
        onlyTimelock 
    { 
        require(_minters.length == _toMintPercents.length, "FeeMinter: array length mismatch");

        // Increment the version and delete the previous mapping
        _version++;

        // Maintain a running tally of percents to enforce that they sum to 100
        uint256 percentSum;

        uint256 length = _minters.length;
        for (uint256 i = 0; i < length; i++) {
            address minter = _minters[i];
            require(minter != address(0), "FeeMinter: zero address");

            uint256 toMintPercent = _toMintPercents[i];
            percentSum += toMintPercent;
            require(percentSum <= _percent(), "FeeMinter: percent sum exceeds 100");

            _toMintPercent[_key(minter)] = toMintPercent;
        }
        require(percentSum == _percent(), "FeeMinter: percents do not total 100");

        minters = _minters;

        emit SetToMintPercents(
            msg.sender,
            _minters,
            _toMintPercents,
            _version
        );
    }

    // Set the number of _decimal points of precision used by percents
    function setDecimals(uint256 _decimals) external onlyOwner {
        decimals = _decimals;
        emit SetDecimals(msg.sender, _decimals);
    }
    
    /// Return the toMintBlock rate for _minter
    function getToMintPerBlock(address _minter) external view returns (uint256) {
        uint256 toMintPercent = getToMintPercent(_minter);
        return Percent.getPercentage(totalToMintPerBlock, toMintPercent, decimals);
    }

    /// Return the array of approved minter addresses
    function getMinters() external view returns (address[] memory) {
        return minters;
    }

    /// Return the toMintPercent for _minter
    function getToMintPercent(address _minter) public view returns (uint256) {
        return _toMintPercent[_key(_minter)];
    }

    // Return a key to the toMintPercent mapping based on _version and _minter
    function _key(address _minter) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_version, _minter));
    }

    // Return the expected percent based on decimals being used
    function _percent() private view returns (uint256) {
        return 100 * (10 ** decimals);
    }
}
