// SPDX-License-Identifier: ---DG----

pragma solidity ^0.8.9;

import "./ERC20.sol";

interface ILightDGToken {

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);
}

contract DGBagToken is ERC20 {

    ILightDGToken immutable public lightDG;
    uint256 constant public RATIO = 2;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _lightDGTokenAddress
    )
        ERC20(
            _tokenName,
            _tokenSymbol
        )
    {
        lightDG = ILightDGToken(
            _lightDGTokenAddress
        );
    }

    function getBAGTokens(
        uint256 _lightDGAmountToDeposit
    )
        external
    {
        lightDG.transferFrom(
            msg.sender,
            address(this),
            _lightDGAmountToDeposit
        );

        _mint(
            msg.sender,
            _lightDGAmountToDeposit * RATIO
        );
    }

    function returnBAGTokens(
        uint256 _lightDGAmountToReceive
    )
        external
    {
        _burn(
            msg.sender,
            _lightDGAmountToReceive * RATIO
        );

        lightDG.transfer(
            msg.sender,
            _lightDGAmountToReceive
        );
    }
}
