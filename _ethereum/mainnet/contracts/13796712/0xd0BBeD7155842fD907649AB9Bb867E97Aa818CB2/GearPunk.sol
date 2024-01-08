// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Models.sol";
import "./IBuilder.sol";
import "./IRandom.sol";
import "./IPunks.sol";

contract GearPunk is ERC721Upgradeable, OwnableUpgradeable, Models {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private tokenIds;
    CountersUpgradeable.Counter private partIds;

    mapping(uint => bytes32) private hashes;
    mapping(uint => bytes) private gadgets;
    mapping(uint => bool) private punksInCars;
    mapping(uint => Base) private bases;
    mapping(uint => Car) private cars;
    mapping(uint => mapping(PartTypes => PartWithPos[])) public availablePartsByBase;
    mapping(uint => PartWithPos[5]) public installedPartsByCar;
    mapping(uint => uint) public partIdToPartIndex;
    Part[] private parts;
    ColoredPaths[] private tires;

    IBuilder builder;
    IRandom random;
    IPunks punks;

    uint private constant PART_ID_OFFSET = 10000;
    uint private constant PROMOTIONAL_PRICE_UNITS = 500;

    uint private basePrice;
    uint16[] private PARTS_PROBABILITIES;
    uint16[] private CARS_PROBABILITIES;

    event PartAdded(uint index);
    event HopIn(uint carId, uint punkId, address sender);
    event HopOff(uint carId, uint punkId, address sender);
    event PartInstalled(uint carId, uint partId, address sender);
    event PartRemoved(uint carId, uint partId, address sender);
    event ToggleRolling(uint carId, bool isRolling);

    function initialize(address _builder, address _punks, address _random)
        public
        initializer
    {
        __ERC721_init("GearPunks", "Gpunks");
        __Ownable_init();

        builder = IBuilder(_builder);
        random = IRandom(_random);
        punks = IPunks(_punks);

        basePrice = 0.5 ether;

        PARTS_PROBABILITIES = [500, 1300, 3000, 3600, 4200];
        CARS_PROBABILITIES = [800, 1800, 4300, 6200, 7500, 8500, 9500];
    }

    function addBase(
        uint _baseId,
        uint16 _fTireIndex,
        uint16 _rTireIndex,
        string calldata _fTirePos,
        string calldata _rTirePos,
        string[] memory _rim,
        Path calldata _baseBackground,
        ColoredPaths calldata _outline,
        string calldata _punkPos
    )
        external
        onlyOwner
    {
        require(!bases[_baseId].registered, "GearPunks: base already registered");

        bases[_baseId] = Base(
            _fTireIndex,
            _rTireIndex,
            _fTirePos,
            _rTirePos,
            _rim,
            _baseBackground,
            _outline,
            _punkPos,
            true
        );
    }

    function addPart(
        uint _index,
        ColoredPaths calldata _paths,
        uint[] calldata _bases,
        string[] calldata _pos,
        PartTypes _type
    ) external onlyOwner {
        require(_index == parts.length, "GearPunks: invalid index");
        require(_bases.length == _pos.length, "GearPunks: base:pos arrays length mismatch");

        parts.push(Part(_paths, _type));

        for (uint i = 0; i < _bases.length; i++) {
            require(bases[_bases[i]].registered, "GearPunks: base not registered");
            availablePartsByBase[_bases[i]][_type].push(PartWithPos(parts.length - 1, _pos[i], false, 0));
        }

        emit PartAdded(_index);
    }

    // @todo move colors to builder
    function addTire(
        string[] memory _paths,
        string[] memory _colors
    )
        external
        onlyOwner
    {
        tires.push(ColoredPaths(_paths, _colors));
    }

    function updateBasePrice(
        uint _newPrice
    )
        external
        onlyOwner
    {
        basePrice = _newPrice;
    }

    function mint()
        external
        payable
    {
        require(msg.value >= price(), "GearPunks: insufficient funds to cover price");
        require(tokenIds.current() < PART_ID_OFFSET, "GearPunks: max number of cars reached");

        payable(owner()).transfer(address(this).balance);

        uint carId = tokenIds.current();
        uint baseId = random.drawWeightedIndex(CARS_PROBABILITIES);

        cars[carId] = Car(
            baseId, // base 
            random.drawColor(),
            0, // punkId,
            new uint[](0), // parts indexes
            true, // created
            false, // isRolling
            false // has punk
        );

        _mint(msg.sender, carId);

        for (uint i = 0; i <= random.drawWeightedIndex(PARTS_PROBABILITIES); i++) {
            // if there are compatible parts of this category for this base
            if (availablePartsByBase[baseId][PartTypes(i)].length != 0) {
                uint partsLength = availablePartsByBase[baseId][PartTypes(i)].length;
                // draw a random part from the available list
                uint randomIndex = random.drawIndex(partsLength);

                _mint(address(this), PART_ID_OFFSET + partIds.current());

                PartWithPos memory part = availablePartsByBase[baseId][PartTypes(i)][randomIndex];

                partIdToPartIndex[partIds.current()] = part.partIndex;

                _install(carId, part, PART_ID_OFFSET + partIds.current());

                partIds.increment();
            }
        }

        tokenIds.increment();
    }

    function tokenURI(uint _tokenId)
        view
        public
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (_tokenId >= PART_ID_OFFSET) {
            uint partIndex = partIdToPartIndex[_tokenId - PART_ID_OFFSET];
            Part storage part = parts[partIndex];
            return builder.buildPartMetadata(
                _tokenId,
                partIndex,
                part.paths,
                random.drawColor()
            );
        }

        Car storage car = cars[_tokenId];
        Base storage base = bases[car.baseId];

        return builder.buildCarMetadata(
            _tokenId,
            car,
            base,
            [tires[base.fTireIndex], tires[base.rTireIndex]],
            [base.fTirePos, base.rTirePos],
            base.rim,
            installedPartsByCar[_tokenId],
            parts
        );
    }

    function hopIn(uint _carId, uint16 _punkId) external {
        require(cars[_carId].created, "GearPunks: unknown car");
        require(ownerOf(_carId) == msg.sender, "GearPunks: car doesn't belong to sender");
        require(!cars[_carId].hasPunk, "GearPunks: this car already has a punk in it");
        require(punks.getPunkOwner(_punkId) == msg.sender, "GearPunks: punk does not belong to sender");
        require(!punksInCars[_punkId], "GearPunks: punk is already in a car");

        cars[_carId].punkId = _punkId;
        cars[_carId].hasPunk = true;
        cars[_carId].isRolling = true;

        punksInCars[_punkId] = true;

        emit HopIn(_carId, _punkId, msg.sender);
    }

    function hopOff(uint _carId) external {
        require(cars[_carId].created, "GearPunks: unknown car");
        require(ownerOf(_carId) == msg.sender, "GearPunks: car doesn't belong to sender");
        require(cars[_carId].hasPunk, "GearPunks: this car doesn't have a punk in it");

        punksInCars[cars[_carId].punkId] = false;

        cars[_carId].hasPunk = false;

        emit HopOff(_carId, cars[_carId].punkId, msg.sender);

        delete cars[_carId].punkId;
    }

    function install(uint _carId, uint _partId) external {
        require(ownerOf(_carId) == msg.sender, "GearPunks: car doesn't belong to sender");

        // lock token will fail if sender isn't the owner
        _transfer(msg.sender, address(this), _partId);

        uint partIndex = partIdToPartIndex[_partId - PART_ID_OFFSET];

        PartTypes slotIndex = parts[partIndex].enumType;

        require(!installedPartsByCar[_carId][uint(slotIndex)].installed, "GearPunks: slot already has a part installed");

        PartWithPos[] storage availableParts = availablePartsByBase[cars[_carId].baseId][slotIndex];

        bool found;

        // test if part is compatible with car
        for (uint i = 0; i < availableParts.length; i++) {
            if (availableParts[i].partIndex == partIndex) {
                _install(_carId, availableParts[i], _partId);
                found = true;
                break;
            }
        }

        require(found, "GearPunks: part is not compatible with car");

        emit PartInstalled(_carId, _partId, msg.sender);
    }

    function remove(uint _carId, uint _partId) external {
        require(ownerOf(_carId) == msg.sender, "GearPunks: car doesn't belong to sender");

        uint partIndex = partIdToPartIndex[_partId - PART_ID_OFFSET];
        uint slotIndex = uint(parts[partIndex].enumType);

        PartWithPos storage partWPos = installedPartsByCar[_carId][slotIndex];

        require(partWPos.installed, "GearPunks: slot is empty");

        delete installedPartsByCar[_carId][slotIndex];

        // unlock token
        _transfer(address(this), msg.sender, _partId);

        emit PartRemoved(_carId, _partId, msg.sender);
    }

    function toggleRolling(uint _carId, bool _isRolling) external {
        require(ownerOf(_carId) == msg.sender, "GearPunks: car doesn't belong to sender");
        require(cars[_carId].hasPunk, "GearPunks: no punk to drive this car");

        cars[_carId].isRolling = _isRolling;

        emit ToggleRolling(_carId, _isRolling);
    }

    function _install(uint _carId, PartWithPos memory _part, uint _partId) internal {
        uint _slotIndex = uint(parts[_part.partIndex].enumType);
        installedPartsByCar[_carId][_slotIndex] = _part;
        installedPartsByCar[_carId][_slotIndex].partId = _partId;
        installedPartsByCar[_carId][_slotIndex].installed = true;
    }

    function price() public view returns (uint) {
        return tokenIds.current() < PROMOTIONAL_PRICE_UNITS ?
            basePrice :
            basePrice * 2;
    }

}