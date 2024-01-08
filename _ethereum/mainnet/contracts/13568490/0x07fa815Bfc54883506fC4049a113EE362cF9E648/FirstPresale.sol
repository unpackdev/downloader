// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ICombatDragons.sol";
import "./firstPresaleData.sol";

contract FirstPresale is Ownable {
    using SafeMath for uint256;
    ICombatDragons public cDragons;

    uint256 public beginningOfSale;
    uint256 public constant PRICE = 7e16; // 0.07 ETH
    uint256 public constant AMOUNT_PER_ADDRESS = 5;

    mapping(address => uint256) public mintedByAddress;

    constructor(address _cDragons, uint256 _beginningOfSale) {
        cDragons = ICombatDragons(_cDragons);
        beginningOfSale = _beginningOfSale.add(48 hours);
    }

    // fallback function can be used to mint cDragons
    receive() external payable {
        uint256 numOfcDragonss = msg.value.div(PRICE);

        mintNFT(numOfcDragonss);
    }

    /**
     * @dev Main sale function. Mints cDragons
     */
    function mintNFT(uint256 numberOfcDragonss) public payable {
        require(block.timestamp >= beginningOfSale, "sale not open");
        require(
            block.timestamp <= beginningOfSale.add(48 hours),
            "presale ended"
        );
        require(isWhitelisted(), "address not listed");

        require(
            mintedByAddress[msg.sender].add(numberOfcDragonss) <=
                AMOUNT_PER_ADDRESS,
            "Exceeds AMOUNT_PER_ADDRESS"
        );

        require(
            PRICE.mul(numberOfcDragonss) == msg.value,
            "Ether value sent is incorrect"
        );

        mintedByAddress[msg.sender] = mintedByAddress[msg.sender].add(
            numberOfcDragonss
        );

        for (uint256 i; i < numberOfcDragonss; i++) {
            cDragons.mint(msg.sender);
        }
    }

    function isWhitelisted() private view returns (bool) {
        address payable[432] memory listed = PresaleData.getWhitelisted();
        for (uint256 index = 0; index < listed.length; index++) {
            if (msg.sender == listed[index]) {
                return true;
            }
        }
        return false;
    }

    // owner mode
    function removeFunds() external onlyOwner {
        uint256 funds = address(this).balance;
        uint256 jShare = funds.mul(48).div(100);
        (bool success1, ) = 0x9b84a019CcaD110fA4602D9479B532Ff7D27F01B.call{
            value: jShare
        }("");

        uint256 donShare = funds.mul(15).div(100);
        (bool success2, ) = 0x7734af82A0dbeEd27903aDAe00784E69b9EB155e.call{
            value: donShare
        }("");

        uint256 pShare = funds.mul(15).div(100);
        (bool success3, ) = 0xc27aa218950d40c2cCC74241a3d0d779b52666f3.call{
            value: pShare
        }("");

        uint256 digShare = funds.mul(15).div(100);
        (bool success4, ) = 0x2f788b3074583945fE68De7CED0971EDccAd2c20.call{
            value: digShare
        }("");

        uint256 t1Share = funds.mul(5).div(100);
        (bool success5, ) = 0xfe34cDe84a4E0ebe795218448dC12165C1827B45.call{
            value: t1Share
        }("");

        uint256 nexxShare = funds.mul(2).div(100);
        (bool success6, ) = 0x005ef5716c3Fb61a9a963b2d3c7f9718676e0Ef6.call{
            value: nexxShare
        }("");

        (bool success, ) = owner().call{value: address(this).balance}("");
        require(
            success &&
                success1 &&
                success2 &&
                success3 &&
                success4 &&
                success5 &&
                success6,
            "funds were not sent properly"
        );
    }

    function removeDustFunds() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
    }
}
