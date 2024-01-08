// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Context.sol";
import "./Ownable.sol";
import "./IDAOFactoryStore.sol";

contract DAOFactoryStore is IDAOFactoryStore, Context, Ownable {
    mapping(string => address) private _tokens;
    mapping(address => uint256) private _tokenVersion;
    mapping(address => bool) public override isFactory;

    address public override staking;

    modifier onlyFactory() {
        require(isFactory[_msgSender()], 'onlyFactory');
        _;
    }

    constructor(address _owner) Ownable() {
        transferOwnership(_owner);
    }

    function tokens(string memory _daoID) external view override returns (address token, uint256 version) {
        token = _tokens[_daoID];
        version = _tokenVersion[token];
    }

    function addToken(
        string memory _daoId,
        address token,
        uint256 version
    ) external override onlyFactory {
        _tokens[_daoId] = token;
        _tokenVersion[token] = version;
        emit AddToken(_msgSender(), _daoId, token, version);
    }

    function setStaking(address _staking) external override onlyOwner {
        require(_staking != address(0), 'ICPDAO: _staking INVALID');
        staking = _staking;
    }

    function addFactory(address _factory) external override onlyOwner {
        isFactory[_factory] = true;
        emit AddFactory(_factory);
    }

    function removeFactory(address _factory) external override onlyOwner {
        isFactory[_factory] = false;
        emit RemoveFactory(_factory);
    }
}
