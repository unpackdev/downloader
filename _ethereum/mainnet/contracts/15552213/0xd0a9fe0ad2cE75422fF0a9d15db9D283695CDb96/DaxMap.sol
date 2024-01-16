// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./DaxToken.sol";

contract DaxMap is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 public constant MAP_ADMIN_ROLE = keccak256("MAP_ADMIN_ROLE");
    bytes32 public constant WORMHOLE_ADMIN_ROLE = keccak256("WORMHOLE_ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    event Arrive(uint256 indexed token, uint256 x, uint256 y, uint256 z);
    event Lock(uint256 indexed token, uint256 time);
    event Move(uint256 indexed token, uint256 x, uint256 y, uint256 z);
    event Wormhole(uint256 indexed x, uint256 indexed y, uint256 indexed z, uint256 start, uint256 age, uint256 toX, uint256 toY, uint256 toZ);

    mapping(uint256 => uint256) private _destinationXPositions;
    mapping(uint256 => uint256) private _destinationYPositions;
    mapping(uint256 => uint256) private _destinationZPositions;
    mapping(uint256 => uint256) private _lastXPositions;
    mapping(uint256 => uint256) private _lastYPositions;
    mapping(uint256 => uint256) private _lastZPositions;
    mapping(uint256 => uint256) private _tokenLockTimes;
    mapping(uint256 => uint256) private _tokenMoveTimes;

    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _wormholeAgeLimits;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _wormholeStartTimes;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _wormholeXPositions;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _wormholeYPositions;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _wormholeZPositions;

    DaxToken private _tokenContract;
    uint256 private _mintPositionX;
    uint256 private _mintPositionY;
    uint256 private _mintPositionZ;
    uint256 private _mintPositionFactorX;
    uint256 private _mintPositionFactorY;
    uint256 private _mintPositionFactorZ;
    uint256 private _speedLimit;

    constructor() {
        _disableInitializers();
    }

    function initialize(DaxToken tokenContract)
    public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        address sender = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(CONTRACT_ADMIN_ROLE, sender);
        _grantRole(MAP_ADMIN_ROLE, sender);
        _grantRole(WORMHOLE_ADMIN_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);

        _tokenContract = tokenContract;
        _mintPositionX = 100000000000;
        _mintPositionY = 100000000000;
        _mintPositionZ = 100000000000;
        _mintPositionFactorX = 27;
        _mintPositionFactorY = 42;
        _mintPositionFactorZ = 69;
        _speedLimit = 1;
    }

    function current(uint256 token)
    public view
    returns (uint256 x, uint256 y, uint256 z) {
        _requireMinted(token);

        uint256 distance;
        uint256 time = _tokenMoveTimes[token];
        unchecked {
            distance = (block.number - time) * _speedLimit;
        }
        (uint256 lx, uint256 ly, uint256 lz) = last(token);
        (uint256 dx, uint256 dy, uint256 dz) = destination(token);
        x = _position(lx, dx, distance, time);
        y = _position(ly, dy, distance, time);
        z = _position(lz, dz, distance, time);
    }

    function destination(uint256 token)
    public view
    returns (uint256 x, uint256 y, uint256 z) {
        _requireMinted(token);

        if (_tokenMoveTimes[token] == 0) {
            x = _mintPosition(_mintPositionX, token, _mintPositionFactorX);
            y = _mintPosition(_mintPositionY, token, _mintPositionFactorY);
            z = _mintPosition(_mintPositionZ, token, _mintPositionFactorZ);
        } else {
            x = _destinationXPositions[token];
            y = _destinationYPositions[token];
            z = _destinationZPositions[token];
        }
    }

    function exists(uint256 token)
    public view
    returns (bool) {
        return _tokenContract.exists(token);
    }

    function inMotion(uint256 token)
    public view
    returns (bool) {
        _requireMinted(token);

        (uint256 cx, uint256 cy, uint256 cz) = current(token);
        (uint256 dx, uint256 dy, uint256 dz) = destination(token);

        return cx != dx || cy != dy || cz != dz;
    }

    function isApprovedOrOwner(address sender, uint256 token)
    public view
    returns (bool) {
        return _tokenContract.exists(token) && _tokenContract.isApprovedOrOwner(sender, token);
    }

    function last(uint256 token)
    public view
    returns (uint256 x, uint256 y, uint256 z) {
        _requireMinted(token);

        if (_tokenMoveTimes[token] == 0) {
            x = _mintPosition(_mintPositionX, token, _mintPositionFactorX);
            y = _mintPosition(_mintPositionY, token, _mintPositionFactorY);
            z = _mintPosition(_mintPositionZ, token, _mintPositionFactorZ);
        } else {
            x = _lastXPositions[token];
            y = _lastYPositions[token];
            z = _lastZPositions[token];
        }
    }

    function locked(uint256 token)
    public view
    returns (bool) {
        _requireMinted(token);

        return _locked(token);
    }

    function lockTime(uint256 token)
    public view
    returns (uint256) {
        _requireMinted(token);

        return _tokenLockTimes[token];
    }

    function moveTime(uint256 token)
    public view
    returns (uint256) {
        _requireMinted(token);

        return _tokenMoveTimes[token];
    }

    function collapseWormhole(
        uint256 x,
        uint256 y,
        uint256 z,
        uint256 start,
        uint256 age)
    public onlyRole(WORMHOLE_ADMIN_ROLE) {
        delete _wormholeXPositions[x][y][z];
        delete _wormholeYPositions[x][y][z];
        delete _wormholeZPositions[x][y][z];
        delete _wormholeStartTimes[x][y][z];
        delete _wormholeAgeLimits[x][y][z];

        emit Wormhole(x, y, z, start, age, 0, 0, 0);
    }
    
    function createWormhole(
        uint256 atX,
        uint256 atY,
        uint256 atZ,
        uint256 toX,
        uint256 toY,
        uint256 toZ,
        uint256 start,
        uint256 age)
    public onlyRole(WORMHOLE_ADMIN_ROLE) {
        _wormholeXPositions[atX][atY][atZ] = toX;
        _wormholeYPositions[atX][atY][atZ] = toY;
        _wormholeZPositions[atX][atY][atZ] = toZ;
        _wormholeStartTimes[atX][atY][atZ] = start;
        _wormholeAgeLimits[atX][atY][atZ] = age;

        emit Wormhole(atX, atY, atZ, start, age, toX, toY, toZ);
    }

    function initialize(uint256 token)
    public {
        _initialize(token);
    }

    function lock(uint256 token)
    public {
        _requireApprovedOrOwner(token);
        _requireUnlocked(token);
        _initialize(token);
    
        uint256 time = block.number;
        _tokenLockTimes[token] = time;

        emit Lock(token, time);
    }

    function move(uint256 token, uint256 x, uint256 y, uint256 z)
    public {
        _requireApprovedOrOwner(token);
        _requireUnlocked(token);
        _initialize(token);

        _move(token, x, y, z);
    }

    function stopMoving(uint256 token)
    public {
        _requireApprovedOrOwner(token);
        _requireUnlocked(token);
        _initialize(token);

        _stopMoving(token);
    }

    function teleport(uint256 from, uint256 to)
    public {
        _requireApprovedOrOwner(from);
        _requireApprovedOrOwner(to);
        _requireUnlocked(from);
        _initialize(from);

        (uint256 x, uint256 y, uint256 z) = current(to);
        _place(from, x, y, z);
        _move(from, x, y, z);
    }

    function unlock(uint256 token)
    public {
        _requireApprovedOrOwner(token);
        _requireLocked(token);
        _initialize(token);

        _tokenLockTimes[token] = 0;

        emit Lock(token, 0);
    }

    function warp(uint256 token)
    public {
        _requireApprovedOrOwner(token);
        _requireUnlocked(token);
        _initialize(token);

        (uint256 x, uint256 y, uint256 z) = current(token);
        require(_wormholeXPositions[x][y][z] != 0 && _wormholeYPositions[x][y][z] != 0 && _wormholeZPositions[x][y][z] != 0 , "DaxMap: wormhole unavailable");
        require(_wormholeStartTimes[x][y][z] <= block.number && _wormholeStartTimes[x][y][z] + _wormholeAgeLimits[x][y][z] >= block.number, "DaxMap: wormhole collapsed");

        _place(token, _wormholeXPositions[x][y][z], _wormholeYPositions[x][y][z], _wormholeZPositions[x][y][z]);
        _move(token, _wormholeXPositions[x][y][z], _wormholeYPositions[x][y][z], _wormholeZPositions[x][y][z]);
    }

    function __config()
    public view
    returns (
        DaxToken tokenContract,
        uint256 speedLimit,
        uint256 mintPositionX,
        uint256 mintPositionY,
        uint256 mintPositionZ,
        uint256 mintPositionFactorX,
        uint256 mintPositionFactorY,
        uint256 mintPositionFactorZ)
    {
        tokenContract = _tokenContract;
        speedLimit = _speedLimit;
        mintPositionX = _mintPositionX;
        mintPositionY = _mintPositionY;
        mintPositionZ = _mintPositionZ;
        mintPositionFactorX = _mintPositionFactorX;
        mintPositionFactorY = _mintPositionFactorY;
        mintPositionFactorZ = _mintPositionFactorZ;
    }

    function __mintPosition()
    public view returns (uint256 x, uint256 y, uint256 z) {
        return (_mintPositionX, _mintPositionY, _mintPositionZ);
    }

    function __mintPositionFactors()
    public view returns (uint256 x, uint256 y, uint256 z) {
        return (_mintPositionFactorX, _mintPositionFactorY, _mintPositionFactorZ);
    }

    function __speedLimit()
    public view returns (uint256) {
        return _speedLimit;
    }

    function __tokenContract()
    public view returns (DaxToken) {
        return _tokenContract;
    }

    function __setSpeedLimit(uint256 speedLimit)
    public onlyRole(MAP_ADMIN_ROLE) {
        _speedLimit = speedLimit;
    }

    function __setMintPositions(uint256 x, uint256 y, uint256 z)
    public onlyRole(MAP_ADMIN_ROLE) {
        _mintPositionX = x;
        _mintPositionY = y;
        _mintPositionZ = z;
    }

    function __setMintPositionFactors(uint256 x, uint256 y, uint256 z)
    public onlyRole(MAP_ADMIN_ROLE) {
        _mintPositionFactorX = x;
        _mintPositionFactorY = y;
        _mintPositionFactorZ = z;
    }

    function __setTokenContract(DaxToken tokenContract)
    public onlyRole(CONTRACT_ADMIN_ROLE) {
        _tokenContract = tokenContract;
    }

    function _authorizeUpgrade(address newImplementation)
    internal override onlyRole(UPGRADER_ROLE) {}

    function _initialize(uint256 token)
    private {
        if (_tokenMoveTimes[token] == 0) {
            (uint256 x, uint256 y, uint256 z) = current(token);
            _lastXPositions[token] = x;
            _lastYPositions[token] = y;
            _lastZPositions[token] = z;
            _destinationXPositions[token] = x;
            _destinationYPositions[token] = y;
            _destinationZPositions[token] = z;
            _tokenLockTimes[token] = block.number;
            _tokenMoveTimes[token] = block.number;
        }
    }

    function _locked(uint256 token)
    private view
    returns (bool) {
        if (_tokenMoveTimes[token] == 0) {
            return true;
        }
        
        return _tokenLockTimes[token] != 0;
    }

    function _mintPosition(uint256 position, uint256 token, uint256 positionFactor)
    private pure
    returns (uint256) {
        return position + (token * positionFactor);
    }

    function _move(uint256 token, uint256 x, uint256 y, uint256 z)
    private {
        _stopMoving(token);
        _destinationXPositions[token] = x;
        _destinationYPositions[token] = y;
        _destinationZPositions[token] = z;

        emit Move(token, x, y, z);
    }

    function _place(uint256 token, uint256 x, uint256 y, uint256 z)
    private {
        _lastXPositions[token] = x;
        _lastYPositions[token] = y;
        _lastZPositions[token] = z;
        _tokenMoveTimes[token] = block.number;

        emit Arrive(token, x, y, z);
    }

    function _position(uint256 position_, uint256 destination_, uint256 travelDistance, uint256 moveTime_)
    private pure
    returns (uint256) {
        uint256 currPosition;
        if (moveTime_ == 0) {
            return position_;
        }
        if (destination_ > position_) {
            unchecked {
                currPosition = position_ + travelDistance;
            }
            if (currPosition > destination_) return destination_;
            return currPosition;
        }
        unchecked {
            currPosition = position_ - travelDistance;
        }
        if (currPosition < destination_) return destination_;
        return currPosition;
    }

    function _requireApprovedOrOwner(uint256 token)
    private view {
        require(isApprovedOrOwner(_msgSender(), token), "DaxMap: not approved or owner");
    }

    function _requireMinted(uint256 token)
    private view {
        require(_tokenContract.exists(token), "DaxMap: invalid token");
    }

    function _requireUnlocked(uint256 token)
    private view {
        require(!_locked(token), "DaxMap: locked");
    }

    function _requireLocked(uint256 token)
    private view {
        require(_locked(token), "DaxMap: unlocked");
    }

    function _stopMoving(uint256 token)
    private {
        (uint256 x, uint256 y, uint256 z) = current(token);
        _lastXPositions[token] = x;
        _lastYPositions[token] = y;
        _lastZPositions[token] = z;
        _tokenMoveTimes[token] = block.number;
        _destinationXPositions[token] = x;
        _destinationYPositions[token] = y;
        _destinationZPositions[token] = z;

        emit Arrive(token, x, y, z);
    }
}