//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

interface ICitizen {
    function balanceOf(address owner) external view returns (uint256);
}

interface IOuterCitizen {
    function balanceOf(address owner) external view returns (uint256);
}

interface IStakedOuterCitizen {
    function balanceOf(address owner) external view returns (uint256);
}

interface ILegacyOuterCitizen {
    function balanceOf(address owner) external view returns (uint256);
}

interface ILegacyCitizen {
    function balanceOf(address owner) external view returns (uint256);
}

interface IStakedCitizen {
    function balanceOf(address owner) external view returns (uint256);
}

interface IERC20 {
    function owner() external view returns (address);

    function balanceOf(address address_) external view returns (uint256);

    function transfer(address to_, uint256 amount_) external returns (bool);

    function transferFrom(address from_, address to_, uint256 amount_) external;

    function approve(address spender, uint256 amount) external;
}

contract NTRewardSystem {
    using SafeMath for uint256;

    error RecipientIsNotACitizen();
    error ArrayLenghtsNotEqual();
    error PercentagesMaxExceeded();
    error NotDesignedToHandle();
    error SplitPercentageHasToEqualOneHundred();
    error NotAnAdmin();
    error BlackListed();

    address public vault = 0xfdAb2c282f6481010A92d20BAc46c8becd06b012;
    ICitizen public citizenContract =
        ICitizen(0xB9951B43802dCF3ef5b14567cb17adF367ed1c0F);

    IERC20 public BYTES = IERC20(0xa19f5264F7D7Be11c451C093D8f92592820Bea86);

    IOuterCitizen public outerCitizenContract =
        IOuterCitizen(0x4481507cc228FA19D203BD42110d679571f7912E);

    IStakedCitizen public stakedCitizenContract =
        IStakedCitizen(0xd37ea75Dd3c499eDA76304f538CbF356Ed9e7Ed9);

    ILegacyCitizen public legacyCitizenContract =
        ILegacyCitizen(0xb668beB1Fa440F6cF2Da0399f8C28caB993Bdd65);

    ILegacyOuterCitizen public legacyOuterCitizenContract =
        ILegacyOuterCitizen(0x9b091d2E0Bb88acE4fe8f0faB87b93D8bA932EC4);

    bool public vaultActive;

    uint256 public vaultTax = 5 * 1 ether;

    mapping(uint8 => uint256) private _calculateReward;
    mapping(address => bool) private _controllers;
    mapping(address => bool) private _blacklisted;

    event BronzeRewarded(
        address indexed sender,
        uint256 amountInBytes,
        address[] indexed recipient
    );
    event SilverRewarded(
        address indexed sender,
        uint256 amountInBytes,
        address[] indexed recipient
    );
    event GoldRewarded(
        address indexed sender,
        uint256 amountInBytes,
        address[] indexed recipient
    );
    event PlatinumRewarded(
        address indexed sender,
        uint256 amountInBytes,
        address[] indexed recipient
    );

    event AdminAdded(address indexed msgSender, address[] indexed newAdmins);
    event AdminRemoved(address indexed msgSender, address[] indexed retiredAdmins);

    mapping(address => uint256) public userRewardsTotal;

    constructor() {
        _controllers[msg.sender] = true;
        _calculateReward[1] = 5 * 1 ether;
        _calculateReward[2] = 25 * 1 ether;
        _calculateReward[3] = 50 * 1 ether;
        _calculateReward[4] = 100 * 1 ether;
    }

    modifier onlyAdmin() {
        if (!_controllers[msg.sender]) revert NotAnAdmin();
        _;
    }

    function addAdmins(address[] calldata _controller) external onlyAdmin {
        for (uint256 i = 0; i < _controller.length; i++) {
            _controllers[_controller[i]] = true;
        }
        emit AdminAdded(msg.sender, _controller);
    }

    function removeAdmins(address[] calldata _controller) external onlyAdmin {
        for (uint256 i = 0; i < _controller.length; i++) {
            _controllers[_controller[i]] = false;
        }
        emit AdminRemoved(msg.sender, _controller);
    }

    function addBlacklistAddress(
        address[] calldata _addresses
    ) external onlyAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _blacklisted[_addresses[i]] = true;
        }
    }

    function removeBlacklistAddress(
        address[] calldata _addresses
    ) external onlyAdmin {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _blacklisted[_addresses[i]] = false;
        }
    }

    function setRewardForSpecificReward(
        uint8 _typeOfReward,
        uint256 _bytesInEther
    ) external onlyAdmin {
        _calculateReward[_typeOfReward] = _bytesInEther;
    }

    function setVault(address _newVault) external onlyAdmin {
        vault = _newVault;
    }

    function setOuterCitizenContract(
        IOuterCitizen _outerCitizenContract
    ) external onlyAdmin {
        outerCitizenContract = _outerCitizenContract;
    }

    function setCitizenContract(ICitizen _citizenContract) external onlyAdmin {
        citizenContract = _citizenContract;
    }

    function setStakedCitizenContract(
        IStakedCitizen _stakedCitizenContract
    ) external onlyAdmin {
        stakedCitizenContract = _stakedCitizenContract;
    }

    function setLegacyCitizenContract(
        ILegacyCitizen _legacyCitizenContract
    ) external onlyAdmin {
        legacyCitizenContract = _legacyCitizenContract;
    }

    function setLegacyOuterCitizenContract(
        ILegacyOuterCitizen _legacyOuterCitizenContract
    ) external onlyAdmin {
        legacyOuterCitizenContract = _legacyOuterCitizenContract;
    }

    function setBYTESContract(IERC20 _BYTES) external onlyAdmin {
        BYTES = _BYTES;
    }

    function toggleVaultActive() external onlyAdmin {
        vaultActive = !vaultActive;
    }

    function setVaultTax(uint256 _newTax) external onlyAdmin {
        vaultTax = _newTax;
    }

    function isCitizen(address _recipient) private view {
        if (
            citizenContract.balanceOf(_recipient) == 0 &&
            outerCitizenContract.balanceOf(_recipient) == 0 &&
            stakedCitizenContract.balanceOf(_recipient) == 0 &&
            legacyCitizenContract.balanceOf(_recipient) == 0 &&
            legacyOuterCitizenContract.balanceOf(_recipient) == 0
        ) {
            revert RecipientIsNotACitizen();
        }
        if (msg.sender == _recipient) {
            revert NotDesignedToHandle();
        }
    }

    function rewardBytesSpecificWithCustomSplit(
        address[] calldata _recipient,
        uint256 _amount,
        uint256[] calldata _split
    ) external {
        if (_recipient.length != _split.length) revert ArrayLenghtsNotEqual();

        if (!vaultActive) {
            if (_recipient.length == 3) {
                isCitizen(_recipient[0]);
                isCitizen(_recipient[1]);
                isCitizen(_recipient[2]);
                rewardBytesPeerToPeerHandleThreeSplit(
                    _recipient,
                    _amount,
                    _split
                );
            } else {
                if (_recipient.length == 2) {
                    isCitizen(_recipient[0]);
                    isCitizen(_recipient[1]);
                    rewardBytesPeerToPeerHandleTwoSplit(
                        _recipient,
                        _amount,
                        _split
                    );
                } else {
                    if (_recipient.length != 1) revert NotDesignedToHandle();
                    rewardBytesPeerToPeerOne(_recipient[0], _amount);
                }
            }
        } else {
            if (_recipient.length == 3) {
                isCitizen(_recipient[0]);
                isCitizen(_recipient[1]);
                isCitizen(_recipient[2]);
                rewardBytesVaultHandleThreeSplit(_recipient, _amount, _split);
            } else {
                if (_recipient.length == 2) {
                    isCitizen(_recipient[0]);
                    isCitizen(_recipient[1]);
                    rewardBytesVaultHandleTwoSplit(_recipient, _amount, _split);
                } else {
                    if (_recipient.length != 1) revert NotDesignedToHandle();
                    rewardBytesVaultOne(_recipient[0], _amount);
                }
            }
        }
    }

    function rewardBytesPeerToPeerHandleTwoSplit(
        address[] calldata _recipient,
        uint256 _amount,
        uint256[] calldata _split
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();
        uint256 splitAdded = _split[0] + _split[1];
        if (splitAdded > 100 * 1 ether)
            revert SplitPercentageHasToEqualOneHundred();
        BYTES.transferFrom(
            msg.sender,
            _recipient[0],
            _amount.mul(_split[0]).div(100 * 1 ether)
        );
        BYTES.transferFrom(
            msg.sender,
            _recipient[1],
            _amount.mul(_split[1]).div(100 * 1 ether)
        );
        userRewardsTotal[_recipient[0]] += _amount.mul(_split[0]).div(
            100 * 1 ether
        );
        userRewardsTotal[_recipient[1]] += _amount.mul(_split[1]).div(
            100 * 1 ether
        );
        if (100 * 1 ether - splitAdded > 0) {
            BYTES.transferFrom(
                msg.sender,
                _recipient[0],
                _amount.mul((100 * 1 ether - splitAdded)).div(100 * 1 ether)
            );
            userRewardsTotal[_recipient[0]] += _amount
                .mul((100 * 1 ether - splitAdded))
                .div(100 * 1 ether);
        }
        emitReward(_recipient, _amount);
    }

    function rewardBytesPeerToPeerHandleThreeSplit(
        address[] calldata _recipient,
        uint256 _amount,
        uint256[] calldata _split
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();
        uint256 splitAdded = _split[0] + _split[1] + _split[2];
        if (splitAdded > 100 * 1 ether)
            revert SplitPercentageHasToEqualOneHundred();
        BYTES.transferFrom(
            msg.sender,
            _recipient[0],
            _amount.mul(_split[0]).div(100 * 1 ether)
        );
        BYTES.transferFrom(
            msg.sender,
            _recipient[1],
            _amount.mul(_split[1]).div(100 * 1 ether)
        );
        BYTES.transferFrom(
            msg.sender,
            _recipient[2],
            _amount.mul(_split[2]).div(100 * 1 ether)
        );

        userRewardsTotal[_recipient[0]] += _amount.mul(_split[0]).div(
            100 * 1 ether
        );
        userRewardsTotal[_recipient[1]] += _amount.mul(_split[1]).div(
            100 * 1 ether
        );
        userRewardsTotal[_recipient[2]] += _amount.mul(_split[2]).div(
            100 * 1 ether
        );

        if (100 * 1 ether - splitAdded > 0) {
            BYTES.transferFrom(
                msg.sender,
                _recipient[0],
                _amount.mul((100 * 1 ether - splitAdded)).div(100 * 1 ether)
            );
            userRewardsTotal[_recipient[0]] += _amount
                .mul((100 * 1 ether - splitAdded))
                .div(100 * 1 ether);
        }

        emitReward(_recipient, _amount);
    }

    function rewardBytesVaultHandleTwoSplit(
        address[] calldata _recipient,
        uint256 _amount,
        uint256[] calldata _split
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();
        uint256 splitAdded = _split[0] + _split[1];
        if (splitAdded > 100 * 1 ether)
            revert SplitPercentageHasToEqualOneHundred();
        uint256 balance = _amount;
        uint256 executedVaultTax = balance.mul(vaultTax).div(100 * 1 ether);

        BYTES.transferFrom(msg.sender, vault, executedVaultTax);

        balance -= executedVaultTax;

        BYTES.transferFrom(
            msg.sender,
            _recipient[0],
            balance.mul(_split[0]).div(100 * 1 ether)
        );
        BYTES.transferFrom(
            msg.sender,
            _recipient[1],
            balance.mul(_split[1]).div(100 * 1 ether)
        );

        userRewardsTotal[_recipient[0]] += balance.mul(_split[0]).div(
            100 * 1 ether
        );
        userRewardsTotal[_recipient[1]] += balance.mul(_split[1]).div(
            100 * 1 ether
        );

        if (100 * 1 ether - splitAdded > 0) {
            BYTES.transferFrom(
                msg.sender,
                _recipient[0],
                balance.mul((100 * 1 ether - splitAdded)).div(100 * 1 ether)
            );
            userRewardsTotal[_recipient[0]] += balance
                .mul((100 * 1 ether - splitAdded))
                .div(100 * 1 ether);
        }

        emitReward(_recipient, _amount);
    }

    function rewardBytesVaultHandleThreeSplit(
        address[] calldata _recipient,
        uint256 _amount,
        uint256[] calldata _split
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();
        uint256 splitAdded = _split[0] + _split[1] + _split[2];
        if (splitAdded > 100 * 1 ether)
            revert SplitPercentageHasToEqualOneHundred();
        uint256 balance = _amount;
        uint256 executedVaultTax = balance.mul(vaultTax).div(100 * 1 ether);

        BYTES.transferFrom(msg.sender, vault, executedVaultTax);

        balance -= executedVaultTax;

        BYTES.transferFrom(
            msg.sender,
            _recipient[0],
            balance.mul(_split[0]).div(100 * 1 ether)
        );
        BYTES.transferFrom(
            msg.sender,
            _recipient[1],
            balance.mul(_split[1]).div(100 * 1 ether)
        );
        BYTES.transferFrom(
            msg.sender,
            _recipient[2],
            balance.mul(_split[2]).div(100 * 1 ether)
        );

        userRewardsTotal[_recipient[0]] += balance.mul(_split[0]).div(
            100 * 1 ether
        );
        userRewardsTotal[_recipient[1]] += balance.mul(_split[1]).div(
            100 * 1 ether
        );
        userRewardsTotal[_recipient[2]] += balance.mul(_split[2]).div(
            100 * 1 ether
        );

        if (100 * 1 ether - splitAdded > 0) {
            BYTES.transferFrom(
                msg.sender,
                _recipient[0],
                balance.mul((100 * 1 ether - splitAdded)).div(100 * 1 ether)
            );
            userRewardsTotal[_recipient[0]] += balance
                .mul((100 * 1 ether - splitAdded))
                .div(100 * 1 ether);
        }

        emitReward(_recipient, _amount);
    }

    function rewardBytesSpecificWithoutCustomSplit(
        address[] calldata _recipient,
        uint256 _amount
    ) external {
        if (!vaultActive) {
            if (_recipient.length == 3) {
                isCitizen(_recipient[0]);
                isCitizen(_recipient[1]);
                isCitizen(_recipient[2]);
                rewardBytesPeerToPeerHandleThree(_recipient, _amount);
            } else {
                if (_recipient.length == 2) {
                    isCitizen(_recipient[0]);
                    isCitizen(_recipient[1]);
                    rewardBytesPeerToPeerHandleTwo(_recipient, _amount);
                } else {
                    if (_recipient.length != 1) revert NotDesignedToHandle();
                    rewardBytesPeerToPeerOne(_recipient[0], _amount);
                }
            }
        } else {
            if (_recipient.length == 3) {
                isCitizen(_recipient[0]);
                isCitizen(_recipient[1]);
                isCitizen(_recipient[2]);
                rewardBytesVaultHandleThree(_recipient, _amount);
            } else {
                if (_recipient.length == 2) {
                    isCitizen(_recipient[0]);
                    isCitizen(_recipient[1]);
                    rewardBytesVaultHandleTwo(_recipient, _amount);
                } else {
                    if (_recipient.length != 1) revert NotDesignedToHandle();
                    rewardBytesVaultOne(_recipient[0], _amount);
                }
            }
        }
    }

    function rewardBytesVaultHandleTwo(
        address[] calldata _recipient,
        uint256 _amount
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();
        uint256 balance = _amount;
        uint256 executedVaultTax = balance.mul(vaultTax).div(100 * 1 ether);

        BYTES.transferFrom(msg.sender, vault, executedVaultTax);

        balance -= executedVaultTax;

        uint256 cut = balance.div(2);
        BYTES.transferFrom(msg.sender, _recipient[0], cut);
        BYTES.transferFrom(msg.sender, _recipient[1], cut);

        userRewardsTotal[_recipient[0]] += cut;
        userRewardsTotal[_recipient[1]] += cut;

        emitReward(_recipient, _amount);
    }

    function rewardBytesVaultHandleThree(
        address[] calldata _recipient,
        uint256 _amount
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();
        uint256 balance = _amount;
        uint256 executedVaultTax = _amount.mul(vaultTax).div(100 * 1 ether);

        BYTES.transferFrom(msg.sender, vault, executedVaultTax);

        balance -= executedVaultTax;
        uint256 cut = balance.div(3);
        BYTES.transferFrom(msg.sender, _recipient[0], cut);
        BYTES.transferFrom(msg.sender, _recipient[1], cut);
        BYTES.transferFrom(msg.sender, _recipient[2], cut);

        userRewardsTotal[_recipient[0]] += cut;
        userRewardsTotal[_recipient[1]] += cut;
        userRewardsTotal[_recipient[2]] += cut;

        emitReward(_recipient, _amount);
    }

    function rewardBytesPeerToPeerHandleOne(
        address[] calldata _recipient,
        uint256 _amount
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();
        BYTES.transferFrom(msg.sender, _recipient[0], _amount);
        userRewardsTotal[_recipient[0]] += _amount;

        emitReward(_recipient, _amount);
    }

    function rewardBytesPeerToPeerHandleTwo(
        address[] calldata _recipient,
        uint256 _amount
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();
        uint256 cut = _amount.div(2);
        BYTES.transferFrom(msg.sender, _recipient[0], cut);
        BYTES.transferFrom(msg.sender, _recipient[1], cut);

        userRewardsTotal[_recipient[0]] += cut;
        userRewardsTotal[_recipient[1]] += cut;

        emitReward(_recipient, _amount);
    }

    function rewardBytesPeerToPeerHandleThree(
        address[] calldata _recipient,
        uint256 _amount
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();
        uint256 cut = _amount.div(3);
        BYTES.transferFrom(msg.sender, _recipient[0], cut);
        BYTES.transferFrom(msg.sender, _recipient[1], cut);
        BYTES.transferFrom(msg.sender, _recipient[2], cut);

        userRewardsTotal[_recipient[0]] += cut;
        userRewardsTotal[_recipient[1]] += cut;
        userRewardsTotal[_recipient[2]] += cut;

        emitReward(_recipient, _amount);
    }

    function rewardBytesPeerToPeer(
        address[] calldata _recipient,
        uint256 _amount,
        uint256[] calldata _split
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();

        uint256 balance = _amount;
        uint256 temp;
        uint256 cut;

        for (uint256 j = 0; j < _recipient.length; j++) {
            isCitizen(_recipient[j]);
            cut = balance.mul(_split[j]).div(100 * 1 ether);
            temp += balance.mul(_split[j]).div(100 * 1 ether);
            BYTES.transferFrom(msg.sender, _recipient[j], cut);
            userRewardsTotal[_recipient[j]] += cut;
        }
        balance -= temp;
        if (balance > 0) {
            BYTES.transferFrom(msg.sender, _recipient[0], balance);
            userRewardsTotal[_recipient[0]] += balance;
        }
        emitReward(_recipient, _amount);
    }

    function emitReward(
        address[] calldata _recipient,
        uint256 _amount
    ) private {
        uint256 calculateRewardTwo = _calculateReward[2];
        uint256 calculateRewardThree = _calculateReward[3];
        uint256 calculateRewardFour = _calculateReward[4];

        if (_calculateReward[1] - 1 < _amount && _amount < calculateRewardTwo) {
            emit BronzeRewarded(msg.sender, _amount, _recipient);
        } else {
            if (
                calculateRewardTwo - 1 < _amount &&
                _amount < calculateRewardThree
            ) {
                emit SilverRewarded(msg.sender, _amount, _recipient);
            } else {
                if (
                    calculateRewardThree - 1 < _amount &&
                    _amount < calculateRewardFour
                ) {
                    emit GoldRewarded(msg.sender, _amount, _recipient);
                } else {
                    if (calculateRewardFour - 1 < _amount) {
                        emit PlatinumRewarded(msg.sender, _amount, _recipient);
                    }
                }
            }
        }
    }

    function rewardBytes(
        address[] calldata _recipient,
        uint256 _amount,
        uint256[] calldata _split
    ) external {
        if (_recipient.length != _split.length) revert ArrayLenghtsNotEqual();
        uint256 splitCheck;
        for (uint256 i = 0; i < _recipient.length; i++) {
            splitCheck += _split[i];
        }
        if (splitCheck > 100 * 1 ether) revert PercentagesMaxExceeded();
        if (!vaultActive) {
            rewardBytesPeerToPeer(_recipient, _amount, _split);
        } else {
            rewardBytesVault(_recipient, _amount, _split);
        }
    }

    function rewardBytesVault(
        address[] calldata _recipient,
        uint256 _amount,
        uint256[] calldata _split
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();

        uint256 balance = _amount;

        uint256 executedVaultTax = balance.mul(vaultTax).div(100 * 1 ether);

        BYTES.transferFrom(msg.sender, vault, executedVaultTax);

        balance -= executedVaultTax;
        uint256 temp;
        uint256 cut;
        for (uint256 j = 0; j < _recipient.length; j++) {
            isCitizen(_recipient[j]);
            cut = balance.mul(_split[j]).div(100 * 1 ether);
            temp += cut;
            BYTES.transferFrom(msg.sender, _recipient[j], cut);
            userRewardsTotal[_recipient[j]] += cut;
        }
        balance -= temp;
        if (balance > 0) {
            BYTES.transferFrom(msg.sender, _recipient[0], balance);
        }
        emitReward(_recipient, _amount);
    }

    function rewardBytesOne(address _recipient, uint256 _amount) external {
        if (!vaultActive) {
            rewardBytesPeerToPeerOne(_recipient, _amount);
        } else {
            rewardBytesVaultOne(_recipient, _amount);
        }
    }

    function rewardBytesPeerToPeerOne(
        address _recipient,
        uint256 _amount
    ) private {
        if (_blacklisted[msg.sender]) revert BlackListed();

        isCitizen(_recipient);

        BYTES.transferFrom(msg.sender, _recipient, _amount);

        userRewardsTotal[_recipient] += _amount;

        emitRewardOne(_recipient, _amount);
    }

    function rewardBytesVaultOne(address _recipient, uint256 _amount) private {
        isCitizen(_recipient);

        if (_blacklisted[msg.sender]) revert BlackListed();

        uint256 balance = _amount;

        uint256 executedVaultTax = balance.mul(vaultTax).div(100 * 1 ether);

        BYTES.transferFrom(msg.sender, vault, executedVaultTax);

        balance -= executedVaultTax;

        BYTES.transferFrom(msg.sender, _recipient, balance);

        userRewardsTotal[_recipient] += _amount;

        emitRewardOne(_recipient, _amount);
    }

    function emitRewardOne(address _recipient, uint256 _amount) private {
        address[] memory recipient = new address[](1);
        recipient[0] = _recipient;
        uint256 calculateRewardTwo = _calculateReward[2];
        uint256 calculateRewardThree = _calculateReward[3];
        uint256 calculateRewardFour = _calculateReward[4];

        if (_calculateReward[1] - 1 < _amount && _amount < calculateRewardTwo) {
            emit BronzeRewarded(msg.sender, _amount, recipient);
        } else {
            if (
                calculateRewardTwo - 1 < _amount &&
                _amount < calculateRewardThree
            ) {
                emit SilverRewarded(msg.sender, _amount, recipient);
            } else {
                if (
                    calculateRewardThree - 1 < _amount &&
                    _amount < calculateRewardFour
                ) {
                    emit GoldRewarded(msg.sender, _amount, recipient);
                } else {
                    if (calculateRewardFour - 1 < _amount) {
                        emit PlatinumRewarded(msg.sender, _amount, recipient);
                    }
                }
            }
        }
    }

    function isAddressBlacklisted(
        address _address
    ) external view returns (bool) {
        return _blacklisted[_address];
    }

    function whichReward(
        uint256 _amount
    ) external view returns (string memory) {
        if (
            _calculateReward[1] - 1 < _amount && _amount < _calculateReward[2]
        ) {
            return "Bronze";
        } else {
            if (
                _calculateReward[2] - 1 < _amount &&
                _amount < _calculateReward[3]
            ) {
                return "Silver";
            } else {
                if (
                    _calculateReward[3] - 1 < _amount &&
                    _amount < _calculateReward[4]
                ) {
                    return "Gold";
                } else {
                    if (_calculateReward[4] - 1 < _amount) {
                        return "Platinum";
                    }
                }
            }
        }
    }
}