// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";

interface IToken {
    function ownerOf(uint id) external view returns (address);
    function isPirate(uint16 id) external view returns (bool);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) external;
    function isApprovedForAll(address owner, address operator) external returns(bool);
    function setApprovalForAll(address operator, bool approved) external;
}
interface IRum {
    function ownerOf(uint id) external view returns (address);
    function burn(address account, uint amount) external;
    function balanceOf(address account, uint tokenId) external returns (uint);
}
interface INewLand {
    function stakeTokens(address account, uint16[] memory tokenIds) external;
}

contract GHGSail is Ownable, IERC721Receiver, Pausable {
    uint constant public RUM_TICKET_ID = 0;

    // References to other contracts
    IToken public goldHunter;
    IToken public shipToken;
    INewLand public newLand;
    IRum public rum;

    struct OceanStake {
        address owner;
        uint80 startTimestamp;
        uint16[] tokenIds;
        uint16 speed;
    }

    mapping(uint16 => bool) public waterproof;
    mapping(uint256 => uint256) public stakeIndices;
    mapping(address => OceanStake[]) public oceanStake;

    mapping(address => bool) public approvedManagers;

    uint public distance = 424800;

    // Speed mapping
    //      [0] raft         = 30
    //      [1] default ship = 30
    //      [2] pirate ship  = 45
    //      [3] gold miner   = 15
    //      [4] pirate       = 30
    //      [5] fairwind     = 0
    mapping(uint16 => uint16) public speedMapping;

    // Rum speed
    //      [0] = 10
    //      [1] = 8
    //      [2] = 7
    //      [3] = 6
    //      [4] = 4
    //      [5] = 3
    //      [6] = 2
    mapping(uint16 => uint16) public rumSpeedMapping;

    // Counters
    uint16 public shipsInOceanCounter;
    uint16 public raftsInOceanCounter;
    uint16 public shipsArrivedCounter;
    uint16 public raftsArrivedCounter;
    uint16 public tokensArrivedCounter;

    event TokenStaked(address owner, uint16 shipId, uint16[] tokenIds, uint16 rum, uint16 speed, uint timestamp);
    event ShipArrived(address owner, uint16 shipId, uint16[] tokenIds, uint timestamp);

    function addManager(address _address) public onlyOwner {
        approvedManagers[_address] = true;
    }

    function removeManager(address _address) public onlyOwner {
        approvedManagers[_address] = false;
    }

    function getStake(address _address) external view returns(OceanStake[] memory) {
        return oceanStake[_address];
    }

    constructor() {
        _pause();

        rumSpeedMapping[0] = 10;
        rumSpeedMapping[1] = 8;
        rumSpeedMapping[2] = 7;
        rumSpeedMapping[3] = 6;
        rumSpeedMapping[4] = 4;
        rumSpeedMapping[5] = 3;
        rumSpeedMapping[6] = 2;

        speedMapping[0] = 30; // raft
        speedMapping[1] = 30; // default ship
        speedMapping[2] = 45; // pirate ship
        speedMapping[3] = 15; // goldminer
        speedMapping[4] = 30; // pirate
        speedMapping[5] = 0;  // fairwind
    }

    function setGoldHunter(address _address) external onlyOwner {
        addManager(_address);
        goldHunter = IToken(_address);
    }
    function setShips(address _address) external onlyOwner {
        addManager(_address);
        shipToken = IToken(_address);
    }
    function setRum(address _address) external onlyOwner {
        rum = IRum(_address);
    }
    function setNewLand(address _address) external onlyOwner {
        addManager(_address);
        newLand = INewLand(_address);
    }
    function changeRumSpeedMapping(uint16 _key, uint16 _newValue) external onlyOwner {
        rumSpeedMapping[_key] = _newValue;
    }
    function changeSpeedMapping(uint16 _key, uint16 _newValue) external onlyOwner {
        speedMapping[_key] = _newValue;
    }
    function changeDistance(uint16 _distance) external onlyOwner {
        distance = _distance;
    }

    function stakeTokens(address _account, uint16 _shipId, uint16[] calldata _tokenIds, uint16 _rumAmount) public whenNotPaused {
        require(_account == msg.sender, "You do not have a permission to do that");

        if (_shipId != 0) {
            require(shipToken.ownerOf(_shipId) == msg.sender, "This NTF does not belong to address");
        }

        uint16 speed = speedMapping[0]; // raft speed
        if (_shipId != 0) {
            if (shipToken.isPirate(_shipId)) {
                speed = speedMapping[2]; // pirate ship speed
                require(_tokenIds.length <= 7, "Cannot stake more than 7 NFTs");
            } else {
                speed = speedMapping[1]; // default ship speed
                require(_tokenIds.length <= 5, "Cannot stake more than 5 NFTs");
            }

            shipToken.transferFrom(msg.sender, address(this), _shipId);
            waterproof[_shipId] = true;
        }

        // Use rum
        for (uint16 i = 0; i < _rumAmount; i++) {
            require(rum.balanceOf(_account, RUM_TICKET_ID) > 0, "No tokens available to burn");
            rum.burn(_account, 1);
            speed += rumSpeedMapping[i];
        }

        uint16[] memory tokens = new uint16[](_tokenIds.length + 1);
        tokens[0] = _shipId;

        // OceanStake
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(goldHunter.ownerOf(_tokenIds[i]) == msg.sender, "This NTF does not belong to address");
            goldHunter.transferFrom(msg.sender, address(this), _tokenIds[i]);
            waterproof[_tokenIds[i]] = true;
            tokens[i+1] = _tokenIds[i];
            if (_shipId != 0) {
                speed += goldHunter.isPirate(_tokenIds[i]) ? speedMapping[4] : speedMapping[3];
            }
        }

        oceanStake[_account].push(OceanStake({
            owner: _account,
            speed: uint16(speed),
            tokenIds: tokens,
            startTimestamp: uint80(block.timestamp)
            }));

        shipsInOceanCounter += 1;
        if (_shipId == 0) raftsInOceanCounter += 1;
        emit TokenStaked(msg.sender, _shipId, _tokenIds, _rumAmount, uint16(speed), block.timestamp);
    }

    // Unstake from Ocean
    function unstakeTokens(address _owner, uint16 _index) external whenNotPaused {
        OceanStake memory userStake = oceanStake[_owner][_index];
        require(userStake.owner == msg.sender, "This stake does not belong to address");

        uint arrivedTimestamp = userStake.startTimestamp + distance / (userStake.speed + speedMapping[5]) * 1 minutes;
        require(block.timestamp >= arrivedTimestamp, "The bus has not arrived yet");

        oceanStake[_owner][_index] = oceanStake[_owner][oceanStake[_owner].length - 1];
        oceanStake[_owner].pop();

        if (userStake.tokenIds[0] != 0) {
            shipToken.safeTransferFrom(address(this), msg.sender, userStake.tokenIds[0], "");
        }
        for (uint i = 1; i < userStake.tokenIds.length; i++) {
            goldHunter.safeTransferFrom(address(this), msg.sender, userStake.tokenIds[i], "");
        }

        shipsArrivedCounter += 1;
        shipsInOceanCounter -= 1;
        tokensArrivedCounter += uint16(userStake.tokenIds.length - 1);

        if (userStake.tokenIds[0] == 0) {
            raftsInOceanCounter -= 1;
            raftsArrivedCounter += 1;
        }

        emit ShipArrived(userStake.owner, userStake.tokenIds[0], userStake.tokenIds, block.timestamp);
    }

    function unstakeTokensIntoLand(address _owner, uint16 _index) external whenNotPaused {
        OceanStake memory userStake = oceanStake[_owner][_index];
        require(userStake.owner == msg.sender, "This stake does not belong to address");

        if (!shipToken.isApprovedForAll(address(this), address(newLand))) shipToken.setApprovalForAll(address(newLand), true);
        if (!goldHunter.isApprovedForAll(address(this), address(newLand))) goldHunter.setApprovalForAll(address(newLand), true);

        uint arrivedTimestamp = userStake.startTimestamp + distance / (userStake.speed + speedMapping[5]) * 1 minutes;
        require(block.timestamp >= arrivedTimestamp, "The ship has not arrived yet");

        oceanStake[_owner][_index] = oceanStake[_owner][oceanStake[_owner].length - 1];
        oceanStake[_owner].pop();

        // Call method from INewLand
        newLand.stakeTokens(_owner, userStake.tokenIds);

        tokensArrivedCounter += uint16(userStake.tokenIds.length - 1);
        shipsArrivedCounter += 1;
        shipsInOceanCounter -= 1;

        if (userStake.tokenIds[0] == 0) {
            raftsInOceanCounter -= 1;
            raftsArrivedCounter += 1;
        }

        emit ShipArrived(userStake.owner, userStake.tokenIds[0], userStake.tokenIds, block.timestamp);
    }

    function isWaterproof(uint16 _index) public view returns(bool) {
        return waterproof[_index];
    }

    function isWaterproofMany(uint16[] calldata _tokensIds) public view returns(bool[] memory) {
        bool[] memory valid = new bool[](_tokensIds.length);

        for (uint i = 0; i < _tokensIds.length; i++) {
            valid[i] = waterproof[_tokensIds[i]];
        }

        return valid;
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function onERC721Received(
        address,
        address from,
        uint,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to this contact directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}
