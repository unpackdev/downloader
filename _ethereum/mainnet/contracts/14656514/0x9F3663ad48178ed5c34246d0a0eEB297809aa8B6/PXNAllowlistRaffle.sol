//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IERC721.sol";

import "./OpenAllowlistRaffleBase.sol";

interface IKaiju is IERC721 {}

interface IRWaste {
    function burn(address user, uint256 amount) external;
}

contract PXNAllowlistRaffle is OpenAllowlistRaffleBase {
    uint256 public constant OWNER_MULTIPLIER = 2;
    IKaiju public immutable KAIJU;
    IRWaste public immutable RWASTE;
    uint256 public fee;

    constructor(
        uint256 _fee,
        IKaiju kaiju,
        IRWaste rwaste,
        uint256 numberOfWinners,
        address vrfCoordinator
    )
        OpenAllowlistRaffleBase(
            numberOfWinners,
            vrfCoordinator
        )
    {
        fee = _fee;
        KAIJU = kaiju;
        RWASTE = rwaste;
    }

    /**
     * @notice Set fee to purchase a single raffle entry
     * @param _fee Cost of a raffle entry
     */
    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    /**
     * @inheritdoc OpenAllowlistRaffleBase
     */
    function enter(uint256 amount) public override payable {
        RWASTE.burn(_msgSender(), amount * fee);

        OpenAllowlistRaffleBase.enter(
            KAIJU.balanceOf(_msgSender()) > 0 ? amount * OWNER_MULTIPLIER : amount
        );
    }
}