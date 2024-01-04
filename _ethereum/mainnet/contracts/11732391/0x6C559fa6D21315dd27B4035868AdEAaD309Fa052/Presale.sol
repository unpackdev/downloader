// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Constants.sol";
import "./TXST.sol";

contract Presale is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;
    XStable token;
    // Presale stuff below
    uint256 private _presaleMint;
    uint256 public presaleTime;
    uint256 public presalePrice;
    mapping (address => uint256) private _presaleParticipation;
    bool public presale;

    constructor (address tokenAdd) public {
        token = XStable(tokenAdd);
        presaleTime = 1611571238;
    }

    function setPresaleTime(uint256 time) external onlyOwner() {
        require(token.isPresaleDone() == false, "This cannot be modified after the presale is done");
        presaleTime = time;
    }

    function setPresaleFlag(bool flag) external onlyOwner() {
        require(!token.isPresaleDone(), "This cannot be modified after the presale is done");
        if (flag == true) {
            require(presalePrice > 0, "Sale price has to be greater than 0");
        }
        presale = flag;
    }
    

    function setPresalePrice(uint256 priceInWei) external onlyOwner() {
        require(!presale && !token.isPresaleDone(),"Can only be set before presale starts");
        presalePrice = priceInWei;
    }

    // Presale function
    function buyPresale() external payable {
        require(presale, "Presale is inactive");
        require(!token.isPresaleDone(), "Presale is already completed");
        require(presaleTime <= now, "Presale hasn't started yet");
        require(_presaleParticipation[_msgSender()].add(msg.value) <= Constants.getPresaleIndividualCap(), "Crossed individual cap");
        require(presalePrice != 0, "Presale price is not set");
        require(msg.value > 0, "Cannot buy without sending any eth mate!");
        require(!Address.isContract(_msgSender()),"no contracts");
        require(tx.gasprice <= Constants.getMaxPresaleGas(),"gas price above limit");
        uint256 amountToMint = msg.value.div(presalePrice);
        require(_presaleMint.add(amountToMint) <= Constants.getPresaleCap(), "Presale max cap already reached");
        token.mint(_msgSender(),amountToMint);
        payable(owner()).transfer(msg.value.mul(0xa).div(45));
        _presaleParticipation[_msgSender()] = _presaleParticipation[_msgSender()].add(msg.value);
        _presaleMint = _presaleMint.add(amountToMint);
    }

    function presaleDone() external onlyOwner() {
        require(!token.isPresaleDone(), "Presale is already completed");
        token.setPresaleDone{value:address(this).balance}();
    }

    function emergencyWithdraw() external onlyOwner() {
        require(!token.isPresaleDone(), "Presale is already completed");
        _msgSender().transfer(address(this).balance);
    }
}