// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IWETH.sol";
import "./UselessNFT.sol";


contract UselessRoyaltyReceiver {
    using SafeERC20 for IERC20;

    event PlatinumRoyaltyShareNumeratorSet(uint256 platinumRoyaltyShareNumerator);

    uint256 public constant ROYALTY_SHARE_DENOMINATOR = 10000;

    UselessNFT public uselessNFT;
    IWETH public weth;
    uint256 public platinumRoyaltyShareNumerator;

    constructor(
        address payable _uselessNFT,
        address _weth
    ) public {
        uselessNFT = UselessNFT(_uselessNFT);
        weth = IWETH(_weth);
        platinumRoyaltyShareNumerator = 5000;
    }

    receive() external payable {
        // do nothing
    }

    function withdrawETH() public {
        // wrap the ETH first to prevent payable transfer failures that can occur since transfers always succeed
        uint ethBalance = address(this).balance;
        if (ethBalance > 0) {
            weth.deposit{value : ethBalance}();
            withdrawToken(address(weth));
        }
    }

    function withdrawToken(
        address _token
    ) public {
        uint platinumTokenId = uselessNFT.getPlatinumTokenId();
        require(
            platinumTokenId != uint(- 1),
            "council is not set up yet"
        );

        uint balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).safeTransfer(
                uselessNFT.ownerOf(platinumTokenId),
                balance * platinumRoyaltyShareNumerator / ROYALTY_SHARE_DENOMINATOR
            );

            // we can do unsafe subtraction because platinumRoyaltyShareNumerator is always <= 5000
            IERC20(_token).safeTransfer(
                uselessNFT.council(),
                balance * (ROYALTY_SHARE_DENOMINATOR - platinumRoyaltyShareNumerator) / ROYALTY_SHARE_DENOMINATOR
            );
        }
    }

    /**
     * @dev The platinum NFT holder can elect to lower the % of royalties received to 0 and can raise them to no more
     *      than 50%.
     */
    function setPlatinumRoyaltyShareNumerator(uint256 _platinumRoyaltyShareNumerator) public {
        uint platinumTokenId = uselessNFT.getPlatinumTokenId();
        require(
            platinumTokenId != uint(- 1),
            "sale is not over yet"
        );
        require(
            msg.sender == uselessNFT.ownerOf(platinumTokenId),
            "invalid sender"
        );
        require(_platinumRoyaltyShareNumerator <= 5000, "invalid platinum royalty share numerator");

        platinumRoyaltyShareNumerator = _platinumRoyaltyShareNumerator;
        emit PlatinumRoyaltyShareNumeratorSet(_platinumRoyaltyShareNumerator);
    }

}
