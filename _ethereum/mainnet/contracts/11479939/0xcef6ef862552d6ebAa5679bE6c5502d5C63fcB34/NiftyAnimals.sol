pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
// import "./IERC20.sol";
import "./VNFT.sol";
import "./MuseToken.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract NiftyAnimals is Ownable, TokenRecover {
    using SafeMath for uint256;
    VNFT public immutable vnft;
    MuseToken public immutable muse;
    uint256 public gem;

    uint256 public currentVNFT = 0;
    uint256 public addTime;

    uint256 public endTime;

    address public winner;
    // overflow
    uint256 public MAX_INT = 2**256 - 1;

    constructor(VNFT _vnft, MuseToken _muse) public {
        vnft = _vnft;
        muse = _muse;
    }

    function start(uint256 _gem, uint256 _addTime) external onlyOwner {
        gem = _gem;
        addTime = _addTime; //maybe 2 hours
        muse.approve(address(vnft), MAX_INT);
        vnft.mint(address(this));
        currentVNFT = vnft.tokenOfOwnerByIndex(
            address(this),
            vnft.balanceOf(address(this)) - 1
        );
        endTime = now.add(addTime);
    }

    function getInfos()
        public
        view
        returns (
            uint256 _museSize,
            uint256 _gem,
            uint256 _currentVNFT,
            uint256 _gemPrice,
            uint256 _endTime
        )
    {
        _museSize = muse.balanceOf(address(this));
        _gem = gem;
        _currentVNFT = currentVNFT;
        _gemPrice = vnft.itemPrice(gem);
        _endTime = endTime;
    }

    function feedPet() external {
        require(endTime >= now, "game Ended");
        uint256 lastTimeMined = vnft.lastTimeMined(currentVNFT);

        require(
            muse.transferFrom(msg.sender, address(this), vnft.itemPrice(gem))
        );
        vnft.buyAccesory(currentVNFT, gem);

        // We mine if possible
        if (lastTimeMined + 1 days < now) {
            vnft.claimMiningRewards(currentVNFT);
        }

        endTime = now.add(addTime);
        winner = msg.sender;
    }

    function claimPet() public {
        require(endTime <= now, "game still going");
        require(msg.sender == winner, "you are not winner");
        uint256 museBalance = muse.balanceOf(address(this));
        vnft.safeTransferFrom(address(this), winner, currentVNFT);
        require(muse.transfer(winner, museBalance));
    }
}
