pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IContraband {
    function minterMint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory data
    ) external;
}

interface IDeathrow {
    function getPoints(
        address _owner
    ) external view returns (uint256 pointsToReturn);
}

contract PrintRedeemer is Ownable, ReentrancyGuard {
    mapping(address => bool) public minted;

    bool public opened;
    IContraband private CONTRABAND =
        IContraband(0x8B669a877d5F04d7341f75BaC3a67cD41Baab635);
    IDeathrow private DEATHROW =
        IDeathrow(0xDf4255848a82949BC9386A74Ab9Fe8D744AF46AA);

    function redeemToken() external nonReentrant {
        require(opened, "Not opened");
        uint256 steaks = DEATHROW.getPoints(msg.sender);
        require(steaks >= 600, "Not enough steaks");
        require(!minted[msg.sender], "Already redeemed");

        CONTRABAND.minterMint(msg.sender, 1, 1, "");
        minted[msg.sender] = true;
    }

    function setOpened(bool _flag) external onlyOwner {
        opened = _flag;
    }

    function withdraw() external onlyOwner {
        require(payable(owner()).send(address(this).balance));
    }
}
