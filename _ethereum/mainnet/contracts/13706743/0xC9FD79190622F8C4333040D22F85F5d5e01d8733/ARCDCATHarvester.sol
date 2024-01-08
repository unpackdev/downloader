//SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
import "./SafeMath.sol";
import "./IVault.sol";
import "./Ownable.sol";

interface Feed {
    function latestAnswer() external view returns (uint);
}

contract ARCDCATHarvester is Ownable {
    using SafeMath for uint256;
    uint public ratePerToken;
    address public feed;
    address private _harvester;

    constructor(address feed_) {
        _harvester = msg.sender;
        feed = feed_;
    }

    function harvestVault(IVault vault, uint amount) public onlyHarvester {
        uint afterFee = vault.harvest(amount);
        uint durationSinceLastHarvest = block.timestamp.sub(vault.lastDistribution());
        IERC20Detailed from = vault.underlying();
        ratePerToken = afterFee.mul(10**(36-from.decimals())).div(vault.totalSupply()).div(durationSinceLastHarvest);
        
        uint catPriceMantissa = Feed(feed).latestAnswer();
        require(catPriceMantissa != 0, "ARCDCATHarvester: ORACLE_CATPRICE_ZERO");

        uint received = afterFee.mul(10**8).div(catPriceMantissa);
        
        IERC20 to = vault.target();
        to.approve(address(vault), received);
        vault.distribute(received);
    }

    function sweep(address token_) external onlyOwner {
        IERC20(token_).transfer(owner(), IERC20(token_).balanceOf(address(this)));
    }

    function setHavester(address harvester_) external onlyOwner {
        _harvester = harvester_;
    }

    modifier onlyHarvester() {
        require(_harvester == _msgSender(), "ARCDCATHarvester: ONLY_HARVESTER");
        _;
    }
}