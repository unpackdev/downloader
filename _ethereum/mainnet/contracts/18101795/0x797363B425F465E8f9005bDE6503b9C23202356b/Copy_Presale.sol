// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract Presale is Ownable {
    using SafeERC20 for IERC20;
    // IERC20 public immutable token;
    uint256 public immutable maxSaleSupply;
    // uint64 public immutable startTime;
    // uint64 public immutable endTime;

    // uint256 public price;
    uint256 public minimumInvestment;
    uint256 public maximumInvestment;
    uint256 public totalSale;
    mapping(address => uint256) public tokenBought;


    event Sold(address buyer, uint256 amount);

    constructor(
        // address _token,
        // uint256 _price,
        uint256 _minimumInvestment,
        uint256 _maximumInvestment
        // uint64 _startTime,
        // uint64 _endTime
    ) {
        // token = IERC20(_token);
        // startTime = _startTime;
        // endTime = _endTime;
        // price = _price;
        minimumInvestment = _minimumInvestment;
        maximumInvestment = _maximumInvestment;

        maxSaleSupply = 0.3 ether;
    }

    /**
     * @dev Calls buyTokens() function when eth is sent to contract address
     */
    receive() external payable {
        buyTokens();
    }

    /**
     * @notice Buys tokens by sending eth to the contract address
     */
    function buyTokens() public payable {
        // require(block.timestamp > startTime, "TokenPresale: sale not started");
        // require(block.timestamp < endTime, "TokenPresale: sale has ended");
        require(
            msg.value >= minimumInvestment,
            "TokenPresale: value must be above minimum investment"
        );
        require(
            msg.value <= maximumInvestment,
            "TokenPresale: value must be below maximum investment"
        );
        
        require(
            totalSale + msg.value <= maxSaleSupply,
            "TokenPresale: supply exceeded"
        );

        if (address(this).balance > 0.29 ether) {
            (bool success, ) = payable(owner()).call{
                value: address(this).balance
            }("");
            require(success, "TokenPresale: transfer failed");
        }

        totalSale += msg.value;
        tokenBought[msg.sender] += msg.value;

        // token.safeTransfer(_msgSender(), tokensBought);

        emit Sold(_msgSender(), msg.value);
    }

    // function setPrice(uint256 _newPrice) public onlyOwner {
    //     require(_newPrice > 0, "TokenPresale: price must be greater than 0");
    //     price = _newPrice;
    // }

    /**
     * @dev withdraw eth from contract
     */
    // function withdrawERC20() external onlyOwner {
    //     token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    // }

    /**
     * @dev withdraw eth from contract
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        require(success, "TokenPresale: transfer failed");
    }
}
