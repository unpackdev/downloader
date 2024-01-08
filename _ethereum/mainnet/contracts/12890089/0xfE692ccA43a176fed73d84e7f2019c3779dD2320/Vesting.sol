// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./AccessControlUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./TransferHelper.sol";
import "./IERC20.sol";
import "./Manageable.sol";
import "./Migrateable.sol";

contract Vesting is AccessControlUpgradeable, Manageable, Migrateable {
    event ItemCreated(address indexed token, uint256 amount);
    event BonusWithdrawn(address indexed vester, string name, uint256 amount);
    event VesterCreated(address indexed vester, string name, uint256 amount);
    event InitialWithdrawn(address indexed vester, string name, uint256 amount);
    event UnlockWithdrawn(address indexed vester, string name, uint256 amount, uint256 count);

    struct AddMultipleVesters {
        string[] _name;
        address[] _vester;
        uint104[] _amount;
        uint8[] _percentInitialAmount;
        uint8[] _percentAmountPerWithdraw;
        uint8[] _percentBonus;
    }

    struct Vested {
        // 1 words
        uint104 amount;
        uint104 totalWithdrawn;
        uint8 percentInitial;
        uint8 percentAmountPerWithdraw;
        uint8 percentBonus;
        uint8 withdrawals;
        uint8 status;
        bool bonusWithdrawn;
    }

    struct Item {
        address token;
        string name;
        uint256 amount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 timeBetweenUnlocks;
        uint256 bonusUnlockTime;
        address signer;
    }

    struct VestedItem {
        Vested record;
        Item item;
    }

    mapping(address => mapping(string => Vested)) public records;
    mapping(address => string[]) userVests;
    mapping(string => Item) public items;
    string[] internal names;

    function addItem(
        address _token,
        string memory _name,
        uint256 _amount,
        uint256 _startTime,
        uint256 _cliffTime,
        uint256 _timeBetweenUnlocks,
        uint256 _bonusUnlockTime,
        address _signer
    ) external onlyManager {
        require(items[_name].amount == 0, 'VESTING: Item already exists');

        TransferHelper.safeTransferFrom(address(_token), msg.sender, address(this), _amount);

        names.push(_name);
        items[_name] = Item({
            token: _token,
            name: _name,
            amount: _amount,
            startTime: _startTime,
            cliffTime: _cliffTime,
            timeBetweenUnlocks: _timeBetweenUnlocks,
            bonusUnlockTime: _bonusUnlockTime,
            signer: _signer
        });

        emit ItemCreated(_token, _amount);
    }

    function addVester(
        string memory _name,
        address _vester,
        uint8 _percentInitialAmount,
        uint8 _percentAmountPerWithdraw,
        uint8 _percentBonus,
        uint104 _amount
    ) internal {
        // ensure that the record does not already exist for vester && ensure the item exist
        require(records[_vester][_name].amount == 0, 'VESTING: Record already exists');
        require(items[_name].amount != 0, 'VESTING: Item does not exist');

        userVests[_vester].push(_name);
        records[_vester][_name] = Vested({
            amount: _amount,
            totalWithdrawn: 0,
            percentAmountPerWithdraw: _percentAmountPerWithdraw,
            percentInitial: _percentInitialAmount,
            percentBonus: _percentBonus,
            withdrawals: 0,
            status: 0,
            bonusWithdrawn: false
        });

        emit VesterCreated(_vester, _name, _amount);
    }

    function addMultipleVesters(AddMultipleVesters calldata vester) external onlyManager {
        for (uint256 i = 0; i < vester._name.length; i++) {
            addVester(
                vester._name[i],
                vester._vester[i],
                vester._percentInitialAmount[i],
                vester._percentAmountPerWithdraw[i],
                vester._percentBonus[i],
                vester._amount[i]
            );
        }
    }

    function addVesterCryptography(
        bytes memory signature,
        string memory _name,
        uint8 _percentInitialAmount,
        uint8 _percentAmountPerWithdraw,
        uint8 _percentBonus,
        uint104 _amount
    ) external {
        bytes32 messageHash =
            sha256(
                abi.encode(
                    _name,
                    _percentInitialAmount,
                    _percentAmountPerWithdraw,
                    _percentBonus,
                    _amount,
                    msg.sender
                )
            );
        bool recovered = ECDSAUpgradeable.recover(messageHash, signature) == items[_name].signer;

        require(recovered == true, 'VESTING: Record not found');

        addVester(
            _name,
            msg.sender,
            _percentInitialAmount,
            _percentAmountPerWithdraw,
            _percentBonus,
            _amount
        );

        if (items[_name].startTime < block.timestamp) {
            withdraw(_name);
        }
    }

    function withdraw(string memory name) public {
        Item memory record = items[name];
        Vested storage userRecord = records[msg.sender][name];
        require(userRecord.amount != 0, 'VESTING: User Record does not exist');

        // Initial withdraw */
        if (userRecord.withdrawals == 0) {
            userRecord.withdrawals++;
            // Ensure initial withdraw is allowed */
            // console.log('Start time %s', record.startTime);
            require(record.startTime < block.timestamp, 'VESTING: Has not begun yet');

            // Get amount to withdraw with some percentage magic */
            uint256 amountToWithdraw =
                (uint256(userRecord.percentInitial) * uint256(userRecord.amount)) / 100;

            // set withdrawn first */
            userRecord.totalWithdrawn += uint104(amountToWithdraw);
            // Ensure our managers aren't allowing users to get more then they should */
            require(
                userRecord.totalWithdrawn <= userRecord.amount,
                'VESTING: Exceeds allowed amount'
            );

            // Finally transfer and call it a day */
            IERC20(record.token).transfer(msg.sender, amountToWithdraw);

            emit InitialWithdrawn(msg.sender, name, amountToWithdraw);
        } else {
            // Ensure time started */

            // console.log('Start time + cliff time %s', record.startTime + record.cliffTime);
            require(
                record.startTime + record.cliffTime < block.timestamp,
                'VESTING: Withdrawal not allowed at this time'
            );

            uint256 maxNumberOfWithdrawals =
                ((100 - userRecord.percentInitial) / userRecord.percentAmountPerWithdraw) + 1; //example for 15% initial and 17% for 5 months, the max number will end up being 6

            // Get number of allowed withdrawals by doing some date magic */
            uint256 numberOfAllowedWithdrawals =
                ((block.timestamp - (record.startTime + record.cliffTime)) /
                    record.timeBetweenUnlocks) + 1; // add one for initial withdraw

            numberOfAllowedWithdrawals = numberOfAllowedWithdrawals < maxNumberOfWithdrawals
                ? numberOfAllowedWithdrawals
                : maxNumberOfWithdrawals;

            // Ensure the amount of withdrawals a user has is less then numberOfAllowed */
            uint256 withdrawalsToPay = numberOfAllowedWithdrawals - userRecord.withdrawals;

            require(withdrawalsToPay != 0, 'VESTING: No withdrawals to pay at this time');

            uint256 amountToWithdraw =
                ((uint256(userRecord.percentAmountPerWithdraw) * uint256(userRecord.amount)) /
                    100) * withdrawalsToPay;

            // set withdrawn first */
            userRecord.totalWithdrawn += uint104(amountToWithdraw);
            userRecord.withdrawals += uint8(withdrawalsToPay);

            // Finally transfer and call it a day */
            IERC20(record.token).transfer(msg.sender, amountToWithdraw);

            emit UnlockWithdrawn(msg.sender, name, amountToWithdraw, userRecord.withdrawals);
        }
    }

    function bonus(string memory name) external {
        Item memory record = items[name];
        Vested storage userRecord = records[msg.sender][name];

        require(record.bonusUnlockTime < block.timestamp, 'VESTING: Bonus is not unlocked yet');
        require(userRecord.bonusWithdrawn == false, 'VESTING: Bonus already withdrawn');

        userRecord.bonusWithdrawn = true;

        // Withdraw bonus
        IERC20(record.token).transfer(
            msg.sender,
            (uint256(userRecord.percentBonus) * uint256(userRecord.amount)) / 100
        );

        emit BonusWithdrawn(
            msg.sender,
            name,
            (uint256(userRecord.percentBonus) * uint256(userRecord.amount)) / 100
        );
    }

    // Getters && Setters ------------------------------------------------------------------ */
    function getNamesLength() public view returns (uint256) {
        return names.length;
    }

    function getNames(uint256 from, uint256 to) public view returns (string[] memory) {
        string[] memory _names = new string[](to - from);

        uint256 count = 0;
        for (uint256 i = from; i < to; i++) {
            _names[count] = names[i];
            count++;
        }

        return _names;
    }

    function getItems(uint256 from, uint256 to) public view returns (Item[] memory) {
        Item[] memory _items = new Item[](to - from);

        uint256 count = 0;
        for (uint256 i = from; i < to; i++) {
            _items[count] = items[names[i]];
            count++;
        }

        return _items;
    }

    function getAllItems() public view returns (Item[] memory) {
        uint256 length = getNamesLength();

        Item[] memory _items = new Item[](length);

        for (uint256 i = 0; i < length; i++) {
            _items[i] = items[names[i]];
        }

        return _items;
    }

    function getUserVestsLength(address user) public view returns (uint256) {
        return userVests[user].length;
    }

    function getUserItems(
        address user,
        uint256 from,
        uint256 to
    ) public view returns (VestedItem[] memory) {
        VestedItem[] memory _items = new VestedItem[](to - from);
        string[] memory keys = userVests[user];

        uint256 count = 0;
        for (uint256 i = from; i < to; i++) {
            _items[count].item = items[keys[i]];
            _items[count].record = records[user][keys[i]];
            count++;
        }

        return _items;
    }

    // Initialize ------------------------------------------------------------------ */
    function initialize(address _manager, address _migrator) external initializer {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
    }
}
