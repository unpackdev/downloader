pragma solidity ^0.6.0;

// forked Wafflemkr NIFTY TOOLS
// github.com/verynifty/verynifty-tools/blob/master/contracts/NiftyTools.sol
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IMuseToken.sol";
import "./IVNFT.sol";

contract MultiVnft is Ownable {
    using SafeMath for uint256;

    bool paused = false;

    IVNFT public vnft;
    IMuseToken public muse;
    uint256 public maxIds = 20;

    constructor(IVNFT _vnft, IMuseToken _muse) public {
        vnft = _vnft;
        muse = _muse;
    }

    modifier notPaused() {
        require(!paused, "PAUSED");
        _;
    }

    /**
       @notice claim MUSE tokens from multiple vNFTs
        @dev contract should be whitelisted as caretaker beforehand
     */
    function claimMultiple(uint256[] calldata ids) external notPaused {
        require(ids.length <= maxIds, "Too much vNFT passed");

        for (uint256 i = 0; i < ids.length; i++) {
            require(vnft.ownerOf(ids[i]) == msg.sender);
            vnft.claimMiningRewards(ids[i]);
        }
        // Send muse to user
        require(muse.transfer(msg.sender, muse.balanceOf(address(this))));
    }

     function _checkReward(uint256[] memory _nftIds)
        public
        view
        returns (uint256 totalAmt)
    {
        for (uint256 i = 0; i < _nftIds.length; i++) {
            totalAmt = totalAmt.add(vnft.getRewards(_nftIds[i]));
        }
    }

    function _checkAmount(uint256[] memory _itemIds)
        public
        view
        returns (uint256 totalAmt)
    {
        for (uint256 i = 0; i < _itemIds.length; i++) {
            totalAmt = totalAmt.add(vnft.itemPrice(_itemIds[i]));
        }
    }

    /**
        @notice feed multiple vNFTs with items/gems
        @dev contract should be whitelisted as caretaker beforehand   
        @dev contract should have MUSE allowance  
     */
    function feedMultiple(uint256[] calldata ids, uint256[] calldata itemIds)
        external
        notPaused
    {
        require(ids.length <= maxIds, "Too much vNFT passed");
        uint256 museCost = _checkAmount(itemIds);
        require(
            muse.transferFrom(msg.sender, address(this), museCost),
            "MUSE:Items"
        );

        require(muse.approve(address(vnft), museCost), "MUSE:approve");

        for (uint256 i = 0; i < ids.length; i++) {
            require(vnft.ownerOf(ids[i]) == msg.sender);
            vnft.buyAccesory(ids[i], itemIds[i]);
        }
    }

    /** NIFTY TOOLS  */

    function setMaxIds(uint256 _maxIds) public onlyOwner {
        maxIds = _maxIds;
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }
}
