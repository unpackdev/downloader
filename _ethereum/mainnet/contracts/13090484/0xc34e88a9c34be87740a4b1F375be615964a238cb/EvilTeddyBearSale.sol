// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IEvilTeddyBear.sol";

contract EvilTeddyBearSale is Ownable {
    using SafeMath for uint256;
    IEvilTeddyBear public evilTeddyBear;

    uint256 public catsGivenAway;
    uint256 public beginningOfSale;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRICE = 3e16; // 0.03 ETH
    uint256 public constant GIVE_AWAY_ALLOCATION = 100;
    address payable[3] public treasury;

    constructor(
        address _evilTeddyBear,
        address payable[3] memory _treasury,
        uint256 _beginningOfSale
    ) {
        evilTeddyBear = IEvilTeddyBear(_evilTeddyBear);

        beginningOfSale = _beginningOfSale;
        treasury = _treasury;
    }

    // fallback function can be used to mint EvilTeddyBears
    receive() external payable {
        uint256 numOfEvilTeddyBears = msg.value.div(PRICE);

        mintNFT(numOfEvilTeddyBears);
    }

    /**
     * @dev Main sale function. Mints EvilTeddyBears
     */
    function mintNFT(uint256 numberOfEvilTeddyBears) public payable {
        require(block.timestamp >= beginningOfSale, "Sale has not started");

        require(
            evilTeddyBear.totalSupply() <= MAX_SUPPLY,
            "Sale has already ended"
        );

        require(
            evilTeddyBear.totalSupply().add(numberOfEvilTeddyBears) <=
                MAX_SUPPLY,
            "Exceeds MAX_SUPPLY"
        );

        require(
            PRICE.mul(numberOfEvilTeddyBears) == msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i; i < numberOfEvilTeddyBears; i++) {
            evilTeddyBear.mint(msg.sender);
        }

        forwardFunds(msg.value);
    }

    function forwardFunds(uint256 funds) internal {
        uint256 ownerShare = funds.div(2);
        uint256 partnerOneShare = (funds.div(2)).mul(30).div(100);
        uint256 partnerTwoShare = funds.sub(ownerShare).sub(partnerOneShare);

        (bool successOwnerShare, ) = treasury[0].call{value: ownerShare}("");
        require(successOwnerShare, "funds were not sent properly to treasury");

        (bool successPartnerOneShare, ) = treasury[1].call{
            value: partnerOneShare
        }("");
        require(
            successPartnerOneShare,
            "funds were not sent properly to treasury"
        );

        (bool success, ) = treasury[1].call{value: partnerTwoShare}("");
        require(success, "funds were not sent properly to treasury");
    }

    // owner mode
    function setTreasury(address payable[3] memory _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function removeDustFunds(address _treasury) public onlyOwner {
        (bool success, ) = _treasury.call{value: address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
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
            evilTeddyBear.mint(supporters[index]);
            catsGivenAway = catsGivenAway.add(1);
        }
    }

    function mintGiveAwayCats(
        uint256 numberOfEvilTeddyBears // only used if we do not have all helper's addresses by sale time
    ) external onlyOwner {
        require(
            catsGivenAway.add(numberOfEvilTeddyBears) <= GIVE_AWAY_ALLOCATION,
            "Exceeded giveaway supply"
        );

        // Reserved for people who helped this project and giveaways
        for (uint256 index; index < numberOfEvilTeddyBears; index++) {
            evilTeddyBear.mint(owner());
            catsGivenAway = catsGivenAway.add(1);
        }
    }
}
