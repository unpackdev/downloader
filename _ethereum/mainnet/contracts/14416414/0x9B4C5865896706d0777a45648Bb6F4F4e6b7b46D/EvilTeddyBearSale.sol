// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IEvilTeddyBearClub.sol";
import "./IEvilCoin.sol";
import "./AggregatorV3Interface.sol";

contract EvilTeddyBearSale is Ownable {
    using SafeMath for uint256;
    IEvilTeddyBearClub public evilTeddyBear;
    IEvilCoin public evilCoinAddress;

    uint256 public maxSupply = 6666;
    uint256 public price = 3e16; // 0.03 ETH
    uint256 public priceTeddyCoin = 1000 ether;
    bool public saleIsActive = false;
    address payable[2] public treasury;
    address private oracleEthUsd;

    constructor(
        IEvilTeddyBearClub _evilTeddyBear,
        IEvilCoin _evilCoinAddress,
        address payable[2] memory _treasury,
        address _oracleEthUsd
    ) {
        evilTeddyBear = IEvilTeddyBearClub(_evilTeddyBear);
        evilCoinAddress = IEvilCoin(_evilCoinAddress);
        treasury = _treasury;
        oracleEthUsd = _oracleEthUsd;
    }

    // fallback function can be used to mint EvilTeddyBears
    receive() external payable {
        uint256 numOfEvilTeddyBears = msg.value.div(price);
        mintNFT(numOfEvilTeddyBears);
    }

    function mintNFT(uint256 numberOfEvilTeddyBears) public payable {
        require(saleIsActive == true, "Sale has not started");
        require(evilTeddyBear.totalSupply() <= maxSupply, "Max Supply Reached");
        require(evilTeddyBear.totalSupply().add(numberOfEvilTeddyBears) <= maxSupply, "Exceeds max supply");
        require(price.mul(numberOfEvilTeddyBears).add(calculateFee(numberOfEvilTeddyBears)) == msg.value, "Ether value sent is not correct");

        for (uint256 i; i < numberOfEvilTeddyBears; i++) {
            evilTeddyBear.mint(msg.sender);
        }

        uint256 fee = calculateFee(numberOfEvilTeddyBears);
        sendFee(fee);
        forwardFunds(msg.value.sub(fee));
    }

    function forwardFunds(uint256 funds) internal {
        uint256 ownerShare = funds.div(2);
        uint256 partnerTwoShare = funds.sub(ownerShare);

        (bool success,) = treasury[0].call{value : ownerShare}("");
        require(success, "funds were not sent properly to treasury");

        (bool success2,) = treasury[1].call{value : partnerTwoShare}("");
        require(success2, "funds were not sent properly to treasury");
    }

    function sendFee(uint256 fee) internal {
        uint256 devFee = fee.mul(39).div(100); //39 % from 8 dollars in eth
        uint256 communityWalletFee = fee.sub(devFee);

        (bool success,) = 0x519B8faF8b4eD711F4Aa2B01AA1E3BaF3B915ac9.call{value : devFee}("");
        require(success, "dev fee was not sent properly");

        (bool success2,) = 0x4476B95F799AD707aD4cD6dEe7383297b2E1C6D6.call{value : communityWalletFee}("");
        require(success2, "community wallet fee was not sent properly");
    }

    function setTreasury(address payable[2] memory _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function removeDustFunds(address _treasury) public onlyOwner {
        (bool success,) = _treasury.call{value : address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
    }

    function mintWithEvilCoins(uint256 numberOfEvilTeddyBears) public payable {
        require(saleIsActive == true, "Sale has not started");
        require(evilTeddyBear.totalSupply() <= maxSupply, "Max Supply Reached");
        require(evilCoinAddress.balanceOf(msg.sender) >= priceTeddyCoin.mul(numberOfEvilTeddyBears), "You dont have $EVIL enough");
        require(evilTeddyBear.totalSupply().add(numberOfEvilTeddyBears) <= maxSupply, "Exceeds max supply");

        evilCoinAddress.burn(msg.sender, priceTeddyCoin.mul(numberOfEvilTeddyBears));

        for (uint256 i; i < numberOfEvilTeddyBears; i++) {
            evilTeddyBear.mint(msg.sender);
        }

        sendFee(calculateFee(numberOfEvilTeddyBears));
    }

    function mintGiveAwayWithAddresses(address[] calldata supporters) external onlyOwner
    {
        require(evilTeddyBear.totalSupply() <= maxSupply, "Max Supply Reached");

        require(evilTeddyBear.totalSupply().add(supporters.length) <= maxSupply, "Exceeds max supply");

        for (uint256 index; index < supporters.length; index++) {
            evilTeddyBear.mint(supporters[index]);
        }
    }

    function changeSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function changeMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function getCurrentPrice() public view returns (uint256) {
        return uint256(price).add(calculateFee(1)); // 0.03 ETH + 8 USD in ETH (3 for maintenance and 5 for community wallet)
    }

    function calculateFee(uint256 numberOfEvilTeddyBears) public view returns (uint256) {
        (, int256 price, , ,) = AggregatorV3Interface(oracleEthUsd)
        .latestRoundData();
        uint256 currentETHPriceInUSD = uint256(price).div(10 ** 8); // price comes in 8 decimals
        uint256 take = numberOfEvilTeddyBears.mul(8); //8 dollars
        uint256 res = take.mul(10000).div(currentETHPriceInUSD) * 10 ** 18; // ETH has 18 decimals
        return res.div(10000);
    }
}