// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./IOrcs.sol";

contract OrcSales is Ownable {
    using SafeMath for uint256;
    IOrcs public orcs;

    uint256 public beginningOfSale;
    address private oracleEthUsd;

    mapping(address => uint256) public mintedByAddress;

    constructor(
        address _orcs,
        uint256 _beginningOfSale,
        address _oracleEthUsd
    ) {
        orcs = IOrcs(_orcs);
        beginningOfSale = _beginningOfSale;
        oracleEthUsd = _oracleEthUsd;
    }

    // fallback function can be used to mint non-fungibles
    receive() external payable {
        uint256 numOfOrcs = msg.value.div(getCurrentPrice());

        mintNFT(numOfOrcs);
    }

    function getCurrentPrice() public view returns (uint256) {
        if (block.timestamp <= beginningOfSale.add(48 hours)) {
            return uint256(4e16).add(calculateFee()); // 0.04 ETH + 10 USD in ETH
        } else {
            return uint256(5e16).add(calculateFee()); // 0.05 ETH + 10 USD in ETH
        }
    }

    function getCurrentAmountPerTx() public view returns (uint256) {
        if (block.timestamp <= beginningOfSale.add(48 hours)) {
            return 10;
        } else {
            return 20;
        }
    }

    /**
     * @dev Main sale function
     */
    function mintNFT(uint256 numberOfOrcs) public payable {
        require(block.timestamp >= beginningOfSale, "sale not open");

        require(
            numberOfOrcs <= getCurrentAmountPerTx(),
            "Exceeds number of mints per transaction"
        );

        require(
            getCurrentPrice().mul(numberOfOrcs) == msg.value,
            "Ether value sent is incorrect"
        );

        for (uint256 i; i < numberOfOrcs; i++) {
            orcs.mint(msg.sender);
        }

        forwardFee(calculateFee());
    }

    // owner mode
    function removeFunds() external onlyOwner {
        uint256 funds = address(this).balance;

        // uint256 pShare = funds.mul(20).div(100);
        (bool success2, ) = 0xC3423dc8457653e935C18BFA02F4fB6E427Dba5f.call{
            value: funds.mul(20).div(100)
        }("");

        // uint256 kShare = funds.mul(2).div(100);
        (bool success3, ) = 0x1aB8E192EE4b8BEa632f61623bd5Af42fb518cb1.call{
            value: funds.mul(2).div(100)
        }("");

        // uint256 nShare = funds.mul(4).div(100);
        (bool success4, ) = 0xeb3853d765870fF40318CF37f3b83B02Fd18b46C.call{
            value: funds.mul(4).div(100)
        }("");

        // uint256 fShare = funds.mul(4).div(100);
        (bool success5, ) = 0xCE1f60EC76a7bBacED41816775b842067d8D17B3.call{
            value: funds.mul(4).div(100)
        }("");

        // uint256 communityWalletShare = funds.mul(10).div(100);
        (bool success6, ) = 0x66A6DF0126F79D85bb829a40cC1315cB4196A154.call{
            value: funds.mul(10).div(100)
        }("");

        // uint256 costsWalletShare = funds.mul(10).div(100);
        (bool success7, ) = 0xf05F6CAa6ebDe3d00644F16B3D86802feb6a6516.call{
            value: funds.mul(10).div(100)
        }("");

        // uint256 mShare = funds.mul(20).div(100);
        (bool success8, ) = 0x0a5C052c275cEdbE01Ab18FfB71c4c7fEB5cAB8c.call{
            value: funds.mul(20).div(100)
        }("");

        // uint256 myolShare = funds.mul(10).div(100);
        (bool success9, ) = 0x12AAb452F7896F4f2d3D14cB7ddcAbCA78f4F092.call{
            value: funds.mul(10).div(100)
        }("");

        // reamining to owner. 20%
        (bool success, ) = owner().call{value: address(this).balance}("");

        require(
            success &&
                success2 &&
                success3 &&
                success4 &&
                success5 &&
                success6 &&
                success7 &&
                success8 &&
                success9,
            "funds were not sent properly"
        );
    }

    function calculateFee() public view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(oracleEthUsd)
            .latestRoundData();
        uint256 currentETHPriceInUSD = uint256(price).div(10**8); // price comes in 8 decimals

        uint256 take = 10;
        uint256 res = take.mul(10000).div(currentETHPriceInUSD) * 10**18; // ETH has 18 decimals

        return res.div(10000);
    }

    function forwardFee(uint256 fee) internal {
        uint256 firstFeeSplit = fee.mul(70).div(100);
        uint256 secondFeeSplit = fee.sub(firstFeeSplit);

        (bool success, ) = 0x239f007d328B36ae3332545061916eBA9d15dC3C.call{
            value: firstFeeSplit
        }("");
        (bool success2, ) = 0x519B8faF8b4eD711F4Aa2B01AA1E3BaF3B915ac9.call{
            value: secondFeeSplit
        }("");

        require(success && success2, "fee was not sent properly");
    }
}
