// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

pragma abicoder v1;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./IStepVesting.sol";

contract VestedToken is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event VestingRegistered(address indexed vesting, address indexed receiver);
    event VestingDeregistered(address indexed vesting, address indexed receiver);

    IERC20 public immutable inchToken;
    mapping (address => EnumerableSet.AddressSet) private _vestingsByReceiver;
    EnumerableSet.AddressSet private _receivers;
    mapping(address => uint256) private _vestingBalances;

    constructor(IERC20 _inchToken) {
        inchToken = _inchToken;
    }

    function name() external pure returns(string memory) {
        return "1INCH Token (Vested)";
    }

    function symbol() external pure returns(string memory) {
        return "v1INCH";
    }

    function decimals() external pure returns(uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        uint256 len = _receivers.length();
        uint256 _totalSupply;
        for (uint256 i = 0; i < len; i++) {
            _totalSupply += balanceOf(_receivers.at(i));
        }
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        EnumerableSet.AddressSet storage vestings = _vestingsByReceiver[account];
        uint256 len = vestings.length();
        uint256 balance;
        for (uint256 i = 0; i < len; i++) {
            balance += inchToken.balanceOf(vestings.at(i));
        }
        return balance;
    }

    function registerVestings(address[] calldata vestings) external onlyOwner {
        uint256 len = vestings.length;
        for (uint256 i = 0; i < len; i++) {
            address vesting = vestings[i];
            address receiver = IStepVesting(vesting).receiver();
            require(_vestingsByReceiver[receiver].add(vesting), "Vesting is already registered");
            _receivers.add(receiver);
            emit VestingRegistered(vesting, receiver);
            uint256 actualBalance = inchToken.balanceOf(vesting);
            require(actualBalance > 0, "Vesting is empty");
            _vestingBalances[vesting] = actualBalance;
            emit Transfer(address(0), receiver, actualBalance);
        }
    }

    function deregisterVestings(address[] calldata vestings) external onlyOwner {
        uint256 len = vestings.length;
        for (uint256 i = 0; i < len; i++) {
            address vesting = vestings[i];
            address receiver = IStepVesting(vesting).receiver();
            EnumerableSet.AddressSet storage receiverVestings = _vestingsByReceiver[receiver];
            require(receiverVestings.remove(vesting), "Vesting is not registered");
            if (receiverVestings.length() == 0) {
                require(_receivers.remove(receiver), "Receiver is already removed");
            }
            emit VestingDeregistered(vesting, receiver);
            uint256 storedBalance = _vestingBalances[vesting];
            if (storedBalance > 0) {
                emit Transfer(receiver, address(0), storedBalance);
                _vestingBalances[vesting] = 0;
            }
        }
    }

    function updateAllBalances() external {
        address[] memory receivers = _receivers.values();
        uint256 len = receivers.length;
        for(uint256 i = 0; i < len; i++) {
            updateBalances(_vestingsByReceiver[receivers[i]].values());
        }
    }

    function updateBalances(address[] memory vestings) public {
        uint256 len = vestings.length;
        for (uint256 i = 0; i < len; i++) {
            address vesting = vestings[i];
            address receiver = IStepVesting(vesting).receiver();
            uint256 actualBalance = inchToken.balanceOf(vesting);
            uint256 storedBalance = _vestingBalances[vesting];
            if (actualBalance < storedBalance) {
                _vestingBalances[vesting] = actualBalance;
                unchecked {
                    emit Transfer(receiver, address(0), storedBalance - actualBalance);
                }
            }
        }
    }
}
