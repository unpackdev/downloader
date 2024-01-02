// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./emitter.sol";
import "./helper.sol";

contract Airdrop is ReentrancyGuard, Helper {
    address public emitterContractAddress;
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(address _emitterContractAddress) {
        emitterContractAddress = _emitterContractAddress;
        owner = msg.sender;
    }

    function updateEmitterAddress(
        address _emitterContractAddress
    ) external onlyOwner {
        if (address(0) == _emitterContractAddress) {
            revert AddressInvalid(
                "_emitterContractAddress",
                _emitterContractAddress
            );
        }
        emitterContractAddress = _emitterContractAddress;
    }

    function airDropToken(
        address _airdropTokenAddress,
        uint256[] memory _airdropAmountArray,
        address[] memory _members
    ) external {
        uint256 amountArrLen = _airdropAmountArray.length;
        uint256 totalMembers = _members.length;

        if (amountArrLen != totalMembers)
            revert ArrayLengthMismatch(amountArrLen, totalMembers);

        uint256 _holdings = IERC20(_airdropTokenAddress).balanceOf(msg.sender);

        uint256 _minimumRequired = 0;

        for (uint256 j = 0; j < amountArrLen; ) {
            _minimumRequired = _minimumRequired + _airdropAmountArray[j];
            unchecked {
                ++j;
            }
        }

        if (!(_holdings >= _minimumRequired)) revert InsufficientFunds();

        uint256 allowance = IERC20(_airdropTokenAddress).allowance(
            msg.sender,
            address(this)
        );

        if (!(_minimumRequired <= allowance))
            revert InsufficientAllowance(_minimumRequired, allowance);

        for (uint256 i = 0; i < totalMembers; ) {
            IERC20(_airdropTokenAddress).transferFrom(
                msg.sender,
                _members[i],
                _airdropAmountArray[i]
            );
            Emitter(emitterContractAddress).airDropToken(
                msg.sender,
                _airdropTokenAddress,
                _members[i],
                _airdropAmountArray[i]
            );
            unchecked {
                ++i;
            }
        }
    }
}
