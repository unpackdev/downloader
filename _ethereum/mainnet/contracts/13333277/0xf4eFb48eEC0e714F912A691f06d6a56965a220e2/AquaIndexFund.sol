// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "./SafeERC20.sol";
import "./IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

contract IndexFund {
    using SafeERC20 for IERC20Burnable;

    uint256 private constant PRECISION = 10**18;
    address public constant AQUA_ADDRESS = 0xD34a24006b862f4E9936c506691539D6433aD297;

    mapping(bytes32 => bool) private withdraws;
    bool public isIndexFundActive;
    address public timelock;
    address payable public indexFundV2;

    event TimelockUpdated(address oldTimelock, address newTimelock);
    event IndexFundV2(address indexFundV2);

    constructor(address _timelock) {
        _updateTimelock(_timelock);
        isIndexFundActive = true;
    }

    modifier hasPermission() {
        require(msg.sender == timelock, "IndexFund:: No permission");
        _;
    }

    modifier isActive() {
        require(isIndexFundActive == true, "IndexFund:: Contract migrated.");
        _;
    }

    function burnAndWithdraw(address[] memory _tokenAddresses, uint256 _burnAmount) external isActive {
        require(_tokenAddresses.length < 200, "IndexFund:: Batch limit exceeded");

        address payable sender = payable(msg.sender);

        uint256 aquaSupply = IERC20Burnable(AQUA_ADDRESS).totalSupply();
        IERC20Burnable(AQUA_ADDRESS).burnFrom(sender, _burnAmount);
        uint256 aquaPercentage = (_burnAmount * PRECISION) / aquaSupply;

        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            bytes32 withdrawnId = keccak256(abi.encode(_tokenAddresses[i], sender, block.timestamp));
            require(withdraws[withdrawnId] == false, "IndexFund:: Token already withdrawn");
            withdraws[withdrawnId] = true;

            if (_tokenAddresses[i] == address(0)) {
                uint256 amount = (address(this).balance * aquaPercentage) / PRECISION;
                sender.transfer(amount);
            } else {
                uint256 balance = IERC20Burnable(_tokenAddresses[i]).balanceOf(address(this));
                uint256 amount = (balance * aquaPercentage) / PRECISION;
                IERC20Burnable(_tokenAddresses[i]).safeTransfer(sender, amount);
            }
        }
    }

    fallback() external payable {}

    receive() external payable {}

    function migrate(address[] calldata _tokens) external hasPermission {
        require(indexFundV2 != address(0), "IndexFund:: Migration not started");

        for (uint256 i; i < _tokens.length; i++) {
            if (_tokens[i] == address(0)) {
                indexFundV2.transfer(address(this).balance);
            } else {
                uint256 balance = IERC20Burnable(_tokens[i]).balanceOf(address(this));
                IERC20Burnable(_tokens[i]).transfer(indexFundV2, balance);
            }
        }

        isIndexFundActive = false;
    }

    function withdrawWithPermission(address[] calldata _tokens, uint256[] calldata _amounts) external hasPermission {
        require(indexFundV2 != address(0), "IndexFund:: Address not set.");

        for (uint256 i; i < _tokens.length; i++) {
            if (_tokens[i] == address(0)) {
                indexFundV2.transfer(_amounts[i]);
            } else {
                IERC20Burnable(_tokens[i]).transfer(indexFundV2, _amounts[i]);
            }
        }
    }

    function withdrawNftWithPermission(
        address[] calldata _tokens,
        uint256[] calldata _tokensId,
        address recipient
    ) external hasPermission {
        require(recipient != address(0), "IndexFund:: Zero address.");
        for (uint256 i; i < _tokens.length; i++) {
            IERC20Burnable(_tokens[i]).safeTransferFrom(address(this), recipient, _tokensId[i]);
        }
    }

    function _updateTimelock(address _timelock) internal {
        emit TimelockUpdated(timelock, _timelock);
        timelock = _timelock;
    }

    function updateTimelock(address _timelock) external hasPermission {
        _updateTimelock(_timelock);
    }

    function setIndexFundV2(address payable _indexFundV2) external hasPermission {
        indexFundV2 = _indexFundV2;
        emit IndexFundV2(_indexFundV2);
    }
}
