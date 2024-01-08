// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IStrayCat.sol";

contract StrayCatSale is Ownable {
    using SafeMath for uint256;
    IStrayCat public strayCat;

    uint256 public catsGivenAway;
    uint256 public beginningOfSale;
    uint256 public constant MAX_SUPPLY = 8000;
    uint256 public constant PRICE = 6e16; // 0.06 ETH
    uint256 public constant GIVE_AWAY_ALLOCATION = 300;
    address payable public treasury;

    constructor(
        address _strayCat,
        address payable _treasury,
        uint256 _beginningOfSale
    ) {
        strayCat = IStrayCat(_strayCat);

        beginningOfSale = _beginningOfSale;
        treasury = _treasury;
    }

    // fallback function can be used to mint StrayCats
    receive() external payable {
        uint256 numOfStrayCats = msg.value.div(PRICE);

        mintNFT(numOfStrayCats);
    }

    /**
     * @dev Main sale function. Mints StrayCats
     */
    function mintNFT(uint256 numberOfStrayCats) public payable {
        require(block.timestamp >= beginningOfSale, "Sale has not started");

        require(strayCat.totalSupply() <= MAX_SUPPLY, "Sale has already ended");

        require(
            strayCat.totalSupply().add(numberOfStrayCats) <= MAX_SUPPLY,
            "Exceeds MAX_SUPPLY"
        );

        require(
            PRICE.mul(numberOfStrayCats) == msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i; i < numberOfStrayCats; i++) {
            strayCat.mint(msg.sender);
        }

        forwardFunds(msg.value);
    }

    function forwardFunds(uint256 funds) internal {
        (bool success, ) = treasury.call{value: funds}("");
        require(success, "funds were not sent to treasury");
    }

    // owner mode
    function setTreasury(address payable _treasury) public onlyOwner {
        require(_treasury != address(0), "!_treasury");

        treasury = _treasury;
    }

    function mintGiveAwayCatsWithAddresses(address[] calldata supporters)
        external
        onlyOwner
    {
        require(
            catsGivenAway.add(supporters.length) <= GIVE_AWAY_ALLOCATION,
            "Exceeded giveaway supply"
        );

        // Reserved for people who helped this project and giveaways
        for (uint256 index; index < supporters.length; index++) {
            strayCat.mint(supporters[index]);
            catsGivenAway = catsGivenAway.add(1);
        }
    }

    function mintGiveAwayCats(
        uint256 numberOfStrayCats // only used if we do not have all helper's addresses by sale time
    ) external onlyOwner {
        require(
            catsGivenAway.add(numberOfStrayCats) <= GIVE_AWAY_ALLOCATION,
            "Exceeded giveaway supply"
        );

        // Reserved for people who helped this project and giveaways
        for (uint256 index; index < numberOfStrayCats; index++) {
            strayCat.mint(owner());
            catsGivenAway = catsGivenAway.add(1);
        }
    }
}
