// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IJavaJelly.sol";

contract JavaJellySale is Ownable {
    using SafeMath for uint256;
    IJavaJelly public javaJelly;

    bool public hasSaleStarted = false;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public price;
    address payable public treasury;

    constructor(address _javaJelly, address payable _treasury) {
        javaJelly = IJavaJelly(_javaJelly);
        treasury = _treasury;
        price = 0.04 ether;
    }

    /**
     * @dev Main sale function. Mints JavaJellies
     */
    function mintNFT(uint256 numberOfJavaJellies) public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(
            javaJelly.totalSupply().add(numberOfJavaJellies) <= MAX_SUPPLY,
            "Exceeds MAX_SUPPLY"
        );
        require(
            price.mul(numberOfJavaJellies) == msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i; i < numberOfJavaJellies; i++) {
            javaJelly.mint(msg.sender);
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

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function mintJelliesToAddresses(address[] calldata receivers)
        external
        onlyOwner
    {
        for (uint256 index; index < receivers.length; index++) {
            javaJelly.mint(receivers[index]);
        }
    }

    function mintJellyTo(address receiver) external onlyOwner {
        javaJelly.mint(receiver);
    }

    function totalSupply() external view returns (uint256) {
        return javaJelly.totalSupply();
    }
}
