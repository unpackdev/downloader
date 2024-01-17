// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/**
 *__/\\\______________/\\\_____/\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\\___
 * _\/\\\_____________\/\\\___/\\\\\\\\\\\\\___/\\\///////\\\___\/\\\/////////\\\_
 *  _\/\\\_____________\/\\\__/\\\/////////\\\_\/\\\_____\/\\\___\/\\\_______\/\\\_
 *   _\//\\\____/\\\____/\\\__\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/__
 *    __\//\\\__/\\\\\__/\\\___\/\\\\\\\\\\\\\\\_\/\\\//////\\\____\/\\\/////////____
 *     ___\//\\\/\\\/\\\/\\\____\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________
 *      ____\//\\\\\\//\\\\\_____\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________
 *       _____\//\\\__\//\\\______\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\_____________
 *        ______\///____\///_______\///________\///__\///________\///__\///______________
 **/

// @openzeppelin
import "./AggregatorV3Interface.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
// helpers
import "./WarpBaseUpgradeable.sol";
// Interfaces
import "./IERC20Burnable.sol";
import "./IERC20Decimals.sol";
import "./IStarship.sol";

/** Pioneer index is 11 */

contract ShipMerchant is WarpBaseUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //** ====== Events ====== *//
    event BuildShip(
        address indexed to,
        address principle,
        uint256 tokenId,
        uint256 brand,
        uint256 hull,
        uint256 bridge,
        uint256 engine,
        uint256 archetype,
        uint256 cost,
        bool[] idsUsed
    );

    event MigrateShip(
        address indexed to,
        string name,
        uint256 tokenId,
        uint256 brand,
        uint256 hull,
        uint256 bridge,
        uint256 engine
    );

    event BuildDamagedShip(
        address indexed account,
        bytes signature,
        uint256 tokenId,
        uint256 brand,
        uint256 hull,
        uint256 bridge,
        uint256 engine,
        uint256 archetype,
        uint256 damage
    );

    //** ====== Struct ====== *//

    /** @notice used for getter to get all principles */
    struct Principle {
        address token;
        uint256 multiplier;
    }

    struct FactoryPart {
        string material;
        uint16 value;
        uint8 application;
    }

    //** ====== Variables ====== *//
    address fund;
    address warp;
    address starship;

    // Costs
    uint256 baseCost;
    uint256 costPerStrength;
    uint256 minStrength;
    uint256 current;

    EnumerableSetUpgradeable.AddressSet principles;

    // New variables
    AggregatorV3Interface internal priceFeed;
    bool payableAllowed;

    // Damaged ships
    mapping(bytes32 => bool) public damagedSigs;
    mapping(address => bool) verifiers;

    EnumerableSetUpgradeable.UintSet fpIds;
    mapping(uint256 => FactoryPart) factoryParts;

    /** ====== Initialize ====== */
    function initialize(
        address _fund,
        address _starship,
        address _warp,
        uint256 _current
    ) public initializer {
        __WarpBase_init();

        fund = _fund;
        starship = _starship;
        warp = _warp;
        payableAllowed = true;

        baseCost = 100.0 ether;
        costPerStrength = 0.18947 ether;
        minStrength = 250;

        current = _current;
    }

    /** @dev build damaged ship
        @param _partStrength {uint16}
        @param _archetype {uint8}
     */
    function buildDamagedShip(
        bytes calldata _signature,
        address _to,
        uint256 _chainId,
        uint256 _timestamp,
        uint16 _partStrength,
        uint16 _damage,
        uint8 _archetype
    ) external {
        require(_archetype <= 10, 'There are only 11 available archetypes');
        require(_partStrength <= 5000, 'Individual parts must have a strength <= 5000');
        // ChainId must == this chain
        require(_chainId == block.chainid, 'Incorrect chain');
        // Ensure valid signature
        bytes32 messageHash = sha256(
            abi.encode(_to, _partStrength, _damage, _archetype, _timestamp, _chainId)
        );
        require(!damagedSigs[messageHash], 'Signature already used');

        address signedAddress = ECDSAUpgradeable.recover(messageHash, _signature);
        require(verifiers[signedAddress], 'Mint: Invalid Signature.');

        damagedSigs[messageHash] = true;

        current += 1;
        IStarship(starship).mint(_to, current, _archetype == 11);
        emit BuildDamagedShip(
            msg.sender,
            _signature,
            current,
            0, // brand warp
            _partStrength,
            _partStrength,
            _partStrength,
            _archetype,
            _damage
        );
    }

    /** @dev gift ship?
        @param _hull {uint256}
        @param _bridge {uint256}
        @param _engine {uint256}
        @param _archetype {uint8}
     */
    function giftShip(
        address _to,
        uint16 _hull,
        uint16 _bridge,
        uint16 _engine,
        uint8 _archetype,
        uint8 _brand
    ) external onlyOwner {
        require(_archetype <= 10, 'There are only 11 available archetypes');
        require(_hull <= 5000, 'Individual parts must have a strength <= 5000');
        require(_bridge <= 5000, 'Individual parts must have a strength <= 5000');
        require(_engine <= 5000, 'Individual parts must have a strength <= 5000');

        current += 1;

        IStarship(starship).mint(_to, current, _archetype == 11);

        emit BuildShip(
            _to,
            address(0),
            current,
            _brand,
            _hull,
            _bridge,
            _engine,
            _archetype,
            0,
            new bool[](fpIds.length())
        );
    }

    function migrateShip(
        address _to,
        uint256 _id,
        string memory name,
        uint16 _hull,
        uint16 _bridge,
        uint16 _engine,
        uint8 _brand
    ) external onlyOwner {
        IStarship(starship).mint(_to, _id, false);

        emit MigrateShip(_to, name, _id, _brand, _hull, _bridge, _engine);
    }

    /** @dev buy ship
        @param _fpIds {uint256}
        @param _archetype {uint8}
        @param _principle {address}
     */
    function buyShip(
        uint8[] calldata _fpIds,
        uint8 _archetype,
        address _principle
    ) public whenNotPaused {
        require(_archetype <= 10, 'There are only 11 available archetypes');

        uint16 hull = 0;
        uint16 bridge = 0;
        uint16 engine = 0;
        bool[] memory idsUsed = new bool[](fpIds.length());

        for (uint256 i = 0; i < _fpIds.length; i++) {
            FactoryPart memory upgrade = factoryParts[_fpIds[i]];
            require(
                upgrade.application == 1 || upgrade.application == 2 || upgrade.application == 3,
                'Invalid Application'
            );
            require(!idsUsed[_fpIds[i]], 'Can not use same upgrade twice.');
            idsUsed[_fpIds[i]] = true;

            if (upgrade.application == 1) {
                hull += upgrade.value;
            } else if (upgrade.application == 2) {
                bridge += upgrade.value;
            } else if (upgrade.application == 3) {
                engine += upgrade.value;
            }
        }

        require(
            hull >= 250 && bridge >= 250 && engine >= 250,
            'All parts must have a strength >= 250'
        );
        require(hull <= 5000 && bridge <= 5000 && engine <= 5000, 'Max strength of 5000 exceeded');

        // Get cost
        uint256 cost = viewCost(hull, bridge, engine, _principle);

        // Transfer
        IERC20Upgradeable(_principle).safeTransferFrom(msg.sender, address(this), cost); // Transfer from sender, then deposit to treasury and sendout grwoth fee

        // Mint
        current += 1;
        IStarship(starship).mint(msg.sender, current, _archetype == 11);
        emit BuildShip(
            msg.sender,
            _principle,
            current,
            0, // brand warp
            hull,
            bridge,
            engine,
            _archetype,
            cost,
            idsUsed
        );
    }

    /** @dev buy ship payable
        @param _fpIds {uint8[]}
        @param _archetype {uint8}
     */
    function buyShipPayable(uint8[] calldata _fpIds, uint8 _archetype)
        public
        payable
        whenNotPaused
    {
        require(_archetype <= 10, 'There are only 11 available archetypes');
        require(payableAllowed, 'Payment only accepted using an allowed principle');

        uint16 hull = 0;
        uint16 bridge = 0;
        uint16 engine = 0;
        bool[] memory idsUsed = new bool[](fpIds.length());

        for (uint256 i = 0; i < _fpIds.length; i++) {
            FactoryPart memory upgrade = factoryParts[_fpIds[i]];
            require(
                upgrade.application == 1 || upgrade.application == 2 || upgrade.application == 3,
                'Invalid Application'
            );
            require(!idsUsed[_fpIds[i]], 'Can not use same upgrade twice.');
            idsUsed[_fpIds[i]] = true;

            if (upgrade.application == 1) {
                hull += upgrade.value;
            } else if (upgrade.application == 2) {
                bridge += upgrade.value;
            } else if (upgrade.application == 3) {
                engine += upgrade.value;
            }
        }

        require(
            hull >= 250 && bridge >= 250 && engine >= 250,
            'All parts must have a strength >= 250'
        );
        require(hull <= 5000 && bridge <= 5000 && engine <= 5000, 'Max strength of 5000 exceeded');

        //** Get msg.value cost */
        uint256 payment = payableUSD(msg.value);

        //** Get cost of the starship */
        uint256 totalStrength = hull + bridge + engine;
        uint256 cost = baseCost + (((totalStrength / 3) - 250) * costPerStrength);

        //** Ensure payment > cost */
        require(payment >= cost, 'Invalid cost');

        /** Build ship */
        current += 1;
        IStarship(starship).mint(msg.sender, current, _archetype == 11);
        emit BuildShip(
            msg.sender,
            address(0),
            current,
            0, // brand warp
            hull,
            bridge,
            engine,
            _archetype,
            cost,
            idsUsed
        );
    }

    /** @dev set allowed principle
        @param _principle {address}
        @param _allowed {bool}
     */
    function setAllowedPrinciples(address _principle, bool _allowed) external onlyOwner {
        if (_allowed) {
            principles.add(_principle);
        } else principles.remove(_principle);
    }

    /** @notice update fund */
    function setAddress(uint256 _idx, address _address) external onlyOwner {
        if (_idx == 0) {
            fund = _address;
        } else if (_idx == 1) {
            priceFeed = AggregatorV3Interface(_address);
        }
    }

    /** @notice sets an integer depending on idx */
    function setInteger(uint256 _idx, uint256 _value) external onlyOwner {
        if (_idx == 0) {
            baseCost = _value;
        } else if (_idx == 1) {
            costPerStrength = _value;
        } else if (_idx == 2) {
            minStrength = _value;
        } else if (_idx == 3) {
            current = _value;
        }
    }

    /** @notice Is the payable function allowed? */
    function setPayable(bool _payable) external onlyOwner {
        payableAllowed = _payable;
    }

    /** @notice Remove or add a verifier */
    function setVerifier(address _verifier, bool _isVerifier) external onlyOwner {
        verifiers[_verifier] = _isVerifier;
    }

    /** @notice View cost of starship based on ship strength */
    function viewCost(
        uint16 _hull,
        uint16 _bridge,
        uint16 _engine,
        address _principle
    ) public view returns (uint256 cost) {
        require(principles.contains(_principle), 'Unallowed principle.');

        uint16 totalStrength = _hull + _bridge + _engine;
        cost = baseCost + (((totalStrength / 3) - 250) * costPerStrength);
        // Convert to match principle decimals
        cost /= (1e18 / 10**IERC20Decimals(_principle).decimals());
    }

    /** @notice View cost based on msg.value amount */
    function payableUSD(uint256 value) public view returns (uint256) {
        if (block.chainid == 3) {
            /** Just pretend eth is 1200$ on ropsten */
            return value * 1200;
        } else {
            (, int256 basePrice, , , ) = priceFeed.latestRoundData();
            uint8 baseDecimals = priceFeed.decimals();
            uint256 payment = (uint256(basePrice) * value) / uint256(10**baseDecimals);
            return payment;
        }
    }

    /** @notice set usable factory part */
    function setFactoryPart(FactoryPart memory fp, uint256 id) public onlyOwner {
        if (fpIds.contains(id)) {
            factoryParts[id] = fp;
        } else {
            fpIds.add(id);
            factoryParts[id] = fp;
        }
    }

    /** @notice set usable factory part(s) */
    function setFactoryParts(FactoryPart[] memory _fps, uint256[] calldata _ids)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            setFactoryPart(_fps[i], _ids[i]);
        }
    }

    /** @notice remove an upgrade */
    function removeFactoryPart(uint256 id) external onlyOwner {
        require(fpIds.contains(id), 'Upgrade does not exist');

        fpIds.remove(id);
        delete factoryParts[id];
    }

    /** @notice get factoryPart */
    function getFactoryParts() public view returns (FactoryPart[] memory) {
        FactoryPart[] memory _factoryPart = new FactoryPart[](fpIds.length());

        uint256 count = 0;
        for (uint256 i = 0; i < fpIds.length(); i++) {
            _factoryPart[count] = FactoryPart({
                material: factoryParts[i].material,
                value: factoryParts[i].value,
                application: factoryParts[i].application
            });
            count++;
        }

        return _factoryPart;
    }

    /** @notice get principles */
    function getPrinciples() public view returns (address[] memory) {
        address[] memory addresses = new address[](principles.length());

        for (uint256 i = 0; i < principles.length(); i++) {
            addresses[i] = principles.at(i);
        }

        return addresses;
    }

    /** @notice view function to get values for UI */
    function getValues()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            address[] memory,
            FactoryPart[] memory
        )
    {
        return (
            baseCost,
            costPerStrength,
            minStrength,
            payableAllowed,
            getPrinciples(),
            getFactoryParts()
        );
    }

    /** @notice withdraw tokens stuck in contract */
    function withdrawTokens(address token) external onlyOwner {
        if (token == address(0)) {
            safeTransferETH(fund, address(this).balance);
        } else {
            IERC20Upgradeable(token).safeTransfer(
                fund,
                IERC20Upgradeable(token).balanceOf(address(this))
            );
        }
    }

    /** @notice safe transfer eth */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
