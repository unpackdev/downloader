//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IERC721.sol";

import "./AllowlistRaffleBase.sol";

interface IKaiju is IERC721 {}

interface IRWaste {
    function burn(address user, uint256 amount) external;
}

contract AllowlistRaffle is AllowlistRaffleBase {
    uint256 public constant OWNER_MULTIPLIER = 2;
    IKaiju public immutable KAIJU;
    IRWaste public immutable RWASTE;
    uint256 public fee;

    constructor(
        uint256 _fee,
        IKaiju kaiju,
        IRWaste rwaste,
        uint256 numberOfWinners,
        uint256 maxUniqueEntrants,
        uint256 maxEntriesPerEntrant,
        uint256 maxTotalEntries,
        address vrfCoordinator
    )
        AllowlistRaffleBase(
            numberOfWinners,
            maxUniqueEntrants,
            maxEntriesPerEntrant,
            maxTotalEntries,
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
     * @notice Check if an address owns a KAIJU
     * @param user Address to check the owner status of
     * @return bool Flag indicating if user owns a KAIJU
     */
    function ownsKaiju(address user) private view returns (bool) {
        return KAIJU.balanceOf(user) > 0;
    }

    /**
     * @inheritdoc AllowlistRaffleBase
     */
    function enter(uint256 amount) public override payable {
        AllowlistRaffleBase.enter(
            ownsKaiju(_msgSender()) ? amount * OWNER_MULTIPLIER : amount
        );
    }

    /**
     * @inheritdoc AllowlistRaffleBase
     */
    function pay(uint256 amount) internal override {
        RWASTE.burn(
            _msgSender(),
            (ownsKaiju(_msgSender()) ? fee / OWNER_MULTIPLIER : fee) * amount
        );
    }
}