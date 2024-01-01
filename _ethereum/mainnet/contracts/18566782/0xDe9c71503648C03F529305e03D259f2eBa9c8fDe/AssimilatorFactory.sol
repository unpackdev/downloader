// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Address.sol";

import "./AssimilatorV3.sol";
import "./IAssimilatorFactory.sol";
import "./IOracle.sol";
import "./ICurveFactory.sol";
import "./IConfig.sol";

contract AssimilatorFactory is IAssimilatorFactory {
    using Address for address;

    event NewAssimilator(
        address indexed caller,
        bytes32 indexed id,
        address indexed assimilator,
        address oracle,
        address token,
        address quote
    );
    event AssimilatorRevoked(address indexed caller, bytes32 indexed id, address indexed assimilator);
    event CurveFactoryUpdated(address indexed caller, address indexed curveFactory);

    mapping(bytes32 => AssimilatorV3) public assimilators;

    address public curveFactory;
    address public config;

    modifier onlyCurveFactoryOrOwner() {
        require(msg.sender == curveFactory || msg.sender == owner(), "unauthorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == IConfig(config).getProtocolTreasury(), "unauthorized");
        _;
    }

    constructor(address _config) {
        require(_config.isContract(), "config-invalid!");
        config = _config;
    }

    function owner() public view returns (address) {
        return IConfig(config).getProtocolTreasury();
    }

    function setCurveFactory(address _curveFactory) external onlyOwner {
        require(_curveFactory != address(0), "curve-factory-invalid!");
        curveFactory = _curveFactory;
        emit CurveFactoryUpdated(msg.sender, curveFactory);
    }

    function getAssimilator(address _token, address _quote) external view override returns (AssimilatorV3) {
        bytes32 assimilatorID = keccak256(abi.encode(_token, _quote));
        return assimilators[assimilatorID];
    }

    function newAssimilator(address _quote, IOracle _oracle, address _token, uint256 _tokenDecimals)
        external
        override
        onlyCurveFactoryOrOwner
        returns (AssimilatorV3)
    {
        require(curveFactory != address(0), "curve-factory-not-set");
        bytes32 assimilatorID = keccak256(abi.encode(_token, _quote));
        if (address(assimilators[assimilatorID]) != address(0)) {
            revert("assimilator-already-exists");
        }
        AssimilatorV3 assimilator = new AssimilatorV3(
            ICurveFactory(curveFactory).wETH(),
            _quote,
            _oracle,
            _token,
            _tokenDecimals,
            IOracle(_oracle).decimals()
        );
        assimilators[assimilatorID] = assimilator;
        emit NewAssimilator(msg.sender, assimilatorID, address(assimilator), address(_oracle), _token, _quote);
        return assimilator;
    }

    function revokeAssimilator(address _token, address _quote) external onlyOwner {
        bytes32 assimilatorID = keccak256(abi.encode(_token, _quote));
        address _assimAddress = address(assimilators[assimilatorID]);
        assimilators[assimilatorID] = AssimilatorV3(address(0));
        emit AssimilatorRevoked(msg.sender, assimilatorID, address(_assimAddress));
    }
}
