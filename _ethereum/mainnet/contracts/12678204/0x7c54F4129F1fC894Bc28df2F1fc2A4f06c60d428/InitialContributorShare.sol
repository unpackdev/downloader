// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC1155Holder.sol";
import "./IERC1155.sol";
import "./ERC1155Burnable.sol";
import "./MiningPool.sol";
import "./ERC1155BurnMiningV1.sol";
import "./ITokenEmitter.sol";

contract InitialContributorShare is ERC1155BurnMiningV1 {
    using SafeMath for uint256;

    uint256 private _projId;

    function initialize(address tokenEmitter_, address baseToken_)
        public
        override
    {
        super.initialize(tokenEmitter_, baseToken_);
        _registerInterface(ERC1155BurnMiningV1(0).burn.selector);
        _registerInterface(ERC1155BurnMiningV1(0).exit.selector);
        _registerInterface(ERC1155BurnMiningV1(0).dispatchableMiners.selector);
        _registerInterface(ERC1155BurnMiningV1(0).erc1155BurnMiningV1.selector);
        _registerInterface(
            InitialContributorShare(0).initialContributorShare.selector
        );
        _projId = ITokenEmitter(tokenEmitter_).projId();
    }

    function burn(uint256 amount) public {
        burn(_projId, amount);
    }

    function burn(uint256 projId_, uint256 amount) public override {
        require(_projId == projId_);
        super.burn(_projId, amount);
    }

    function exit() public {
        exit(_projId);
    }

    function exit(uint256 projId_) public override {
        require(_projId == projId_);
        super.exit(_projId);
    }

    /**
     * @dev override this function if you customize this mining pool
     */
    function dispatchableMiners(uint256 id)
        public
        view
        override
        returns (uint256 numOfMiner)
    {
        if (_projId == id) return 1;
        else return 0;
    }

    function projId() public view returns (uint256) {
        return _projId;
    }

    function initialContributorShare() external pure returns (bool) {
        return true;
    }
}
