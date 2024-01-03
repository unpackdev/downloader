// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./ERC20.sol";
import "./console.sol";

contract KOTH is ERC20 {
    using SafeMath for uint256;

    address payable public teamWallet;
    address public devWallet;
    address public kingKOTH;
    address public wizardDAO;
    address public unicrypt;
    address public executioner;

    address[] public adminAddresses;
    address[] public excludedAddresses;

    uint256 public slaughterInitLockedUntil;

    uint256 public slaughterLockedUntil;

    uint256 public slaughterPriceETHMantissa;

    event InitSlaughter(
        address slaughterer,
        uint256 blockNumber,
        uint256 timestamp
    );

    event Slaughter(
        uint256 totalLoot,
        uint256 lootSplit,
        uint256 blockNumber,
        uint256 timestamp
    );

    event AddressExcluded(address addr, uint256 blockNumber, uint256 timestamp);

    event AddressReincluded(
        address addr,
        uint256 blockNumber,
        uint256 timestamp
    );

    event InitSlaughterPriceChanged(
        uint256 slaughterPriceETHMantissa,
        uint256 blockNumber,
        uint256 timestamp
    );

    constructor(
        address payable _teamWallet,
        address _devWallet,
        address _kingKOTH,
        address _wizardDAO,
        address _unicrypt,
        address _executioner,
        uint256 _slaughterTimelockStart,
        uint256 _slaughterPriceETHMantissa
    ) public ERC20("King of the Hill", "KOTH") {
        _mint(_teamWallet, 1000000 ether);
        devWallet = _devWallet;
        teamWallet = _teamWallet;
        kingKOTH = _kingKOTH;
        wizardDAO = _wizardDAO;
        unicrypt = _unicrypt;
        executioner = _executioner;

        adminAddresses.push(_devWallet);
        adminAddresses.push(_teamWallet);
        adminAddresses.push(_kingKOTH);
        adminAddresses.push(_wizardDAO);
        adminAddresses.push(_executioner);

        excludedAddresses.push(devWallet);
        excludedAddresses.push(teamWallet);
        excludedAddresses.push(kingKOTH);
        excludedAddresses.push(wizardDAO);
        excludedAddresses.push(unicrypt);
        excludedAddresses.push(executioner);

        slaughterInitLockedUntil = _slaughterTimelockStart;

        slaughterLockedUntil = _slaughterTimelockStart;

        slaughterPriceETHMantissa = _slaughterPriceETHMantissa;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Cannot transfer 0 KOTH");

        _beforeTokenTransfer(sender, recipient, amount);

        // 3% burn
        uint256 burnAmount = 0;
        uint256 actualAmount = amount;

        if (!isAddressExcluded(sender)) {
            burnAmount = amount.mul(3).div(100);
            actualAmount = amount - burnAmount;
            _burn(sender, burnAmount);
        }

        _balances[sender] = _balances[sender].sub(
            actualAmount,
            "ERC20: transfer amount exceeds balance"
        );

        _balances[recipient] = _balances[recipient].add(actualAmount);
        emit Transfer(sender, recipient, actualAmount);
    }

    function initSlaughter() public payable {
        require(
            block.timestamp >= slaughterInitLockedUntil,
            "Init slaughter locked"
        );
        require(
            msg.value >= slaughterPriceETHMantissa,
            "Insufficient ETH payed"
        );

        slaughterInitLockedUntil = block.timestamp + getRandom(30 days);

        emit InitSlaughter(msg.sender, block.number, block.timestamp);
    }

    function slaughter(address[] memory peasants, address[] memory champions)
        public
    {
        require(isAdmin(msg.sender), "Caller is not a manager");
        require(block.timestamp >= slaughterLockedUntil, "Slaughter locked");

        address currAddress;
        uint256 totalLoot;
        uint256 lootOrBurnAmount;
        uint256 balance;
        uint256 lootSplit;

        // raid peasants
        for (uint256 i = 0; i < peasants.length; i++) {
            currAddress = peasants[i];

            balance = balanceOf(currAddress);
            if (balance < 1 ether) {
                lootOrBurnAmount = balance;
                _balances[currAddress] = _balances[currAddress].sub(
                    lootOrBurnAmount,
                    "ERC20: loot amount exceeds balance"
                );
            } else {
                lootOrBurnAmount = balance.mul(3).div(100);
                _burn(currAddress, lootOrBurnAmount);
                _balances[currAddress] = _balances[currAddress].sub(
                    lootOrBurnAmount,
                    "ERC20: loot amount exceeds balance"
                );
            }

            totalLoot = totalLoot + lootOrBurnAmount;
        }

        // reward champions
        lootSplit = totalLoot.div(champions.length);

        for (uint256 j = 0; j < champions.length; j++) {
            currAddress = champions[j];
            _balances[currAddress] = _balances[currAddress].add(lootSplit);
        }

        slaughterLockedUntil = slaughterInitLockedUntil;
        emit Slaughter(totalLoot, lootSplit, block.number, block.timestamp);
    }

    function isAdmin(address accountAddress)
        public
        view
        returns (bool _isAdmin)
    {
        bool isAccountAdmin = false;
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            if (accountAddress == adminAddresses[i]) {
                isAccountAdmin = true;
                break;
            }
        }
        return isAccountAdmin;
    }

    function isAddressExcluded(address accountAddress)
        public
        view
        returns (bool _isExcluded)
    {
        bool isExcluded = false;
        for (uint256 i = 0; i < excludedAddresses.length; i++) {
            if (accountAddress == excludedAddresses[i]) {
                isExcluded = true;
                break;
            }
        }
        return isExcluded;
    }

    function excludedAddressesLength() public view returns (uint256 length) {
        return excludedAddresses.length;
    }

    function excludeAddress(address addr) public {
        require(
            msg.sender == devWallet ||
                msg.sender == teamWallet ||
                msg.sender == kingKOTH ||
                msg.sender == wizardDAO,
            "Non admin access."
        );

        excludedAddresses.push(addr);
        emit AddressExcluded(addr, block.number, block.timestamp);
    }

    function reincludeAddress(address addr) public {
        require(
            msg.sender == devWallet ||
                msg.sender == teamWallet ||
                msg.sender == kingKOTH ||
                msg.sender == wizardDAO,
            "Non admin access."
        );

        uint256 arrayLength = excludedAddresses.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (addr == excludedAddresses[i]) {
                excludedAddresses[i] = excludedAddresses[arrayLength - 1];

                excludedAddresses.pop();
                break;
            }
        }

        emit AddressReincluded(addr, block.number, block.timestamp);
    }

    function setInitSlaughterPrice(uint256 _slaughterPriceETHMantissa) public {
        require(
            msg.sender == devWallet ||
                msg.sender == teamWallet ||
                msg.sender == kingKOTH ||
                msg.sender == wizardDAO,
            "Non admin access."
        );

        slaughterPriceETHMantissa = _slaughterPriceETHMantissa;
        emit InitSlaughterPriceChanged(
            slaughterPriceETHMantissa,
            block.number,
            block.timestamp
        );
    }

    function withdrawETH() public {
        require(
            msg.sender == devWallet ||
                msg.sender == teamWallet ||
                msg.sender == kingKOTH ||
                msg.sender == wizardDAO,
            "Non admin access."
        );

        teamWallet.transfer(address(this).balance);
    }

    function getRandom(uint256 upperbound) private view returns (uint256) {
        uint256 randomHash =
            uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return randomHash % upperbound;
    }
}
