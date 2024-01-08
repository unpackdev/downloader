// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.4.25;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ICERC20.sol";
import "./IWETH.sol";
import "./ReentrancyGuard.sol";

contract Bread is Ownable, ERC20, ERC20Detailed, ReentrancyGuard {
    using SafeMath for uint256;
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IERC20 public reserveToken;
    ICERC20 public cReserveToken;
    uint256 public totalReserve;

    event Minted(address sender, uint256 amount);
    event Burned(address sender, uint256 amount);

    constructor(
        address _reserveTokenAddress,
        address _cReserveTokenAddress
    ) public ERC20Detailed("Breadchain Stablecoin", "BREAD", 18) {
        reserveToken = IERC20(_reserveTokenAddress);
        cReserveToken = ICERC20(_cReserveTokenAddress);
    }

    function mint(uint256 _amount) public {
        _handleMint(_amount);
        require(reserveToken.transferFrom(msg.sender, address(this), _amount), "mint() ERC20.transferFrom failed.");
        require(reserveToken.approve(address(cReserveToken), _amount), "mint() ERC20.approve failed.");
        require(cReserveToken.mint(_amount) == 0, "mint() cERC20.mint failed.");
        totalReserve = totalReserve.add(_amount);
    }

    function burn(uint256 _amount) public nonReentrant {
        _handleBurn(_amount);
        require(cReserveToken.redeemUnderlying(_amount) == 0, "burn() cERC20.redeemUnderlying failed.");
        totalReserve = totalReserve.sub(_amount);
        require(reserveToken.transfer(msg.sender, _amount), "burn() ERC20.transfer failed.");
    }

    function withdrawInterest(uint256 _amount) public onlyOwner nonReentrant {
        require(_amount > 0, "withdrawInterest() cannot withdraw 0");
        uint256 interest = interestAvailable();
        require(interest >= _amount, "withdrawInterest() interest accrued is below withdraw amount");
        require(cReserveToken.redeemUnderlying(_amount) == 0, "withdrawInterest() cERC20.redeemUnderlying failed.");
        require(reserveToken.transfer(owner(), _amount), "withdrawInterest() ERC20.transfer failed.");
    }

    function withdrawToken(address _tokenAddress, uint256 _amount) public onlyOwner nonReentrant {
        require(_tokenAddress != address(cReserveToken), "withdrawToken() cannot withdraw collateral token.");
        if (_tokenAddress == ETH) {
            require(address(this).balance >= _amount, "withdrawToken() balance too low");
            owner().transfer(_amount);
        } else {
            require(IERC20(_tokenAddress).transfer(owner(), _amount), "withdrawToken() ERC20.transfer failed.");
        }
    }

    function interestAvailable() public view returns (uint256) {
        return cReserveToken.balanceOfUnderlying(address(this)).sub(totalReserve);
    }

    function _handleMint(uint256 _amount) internal {
        require(_amount > 0, "Deposit must be non-zero.");
        _mint(msg.sender, _amount);
        emit Minted(msg.sender, _amount);
    }

    function _handleBurn(uint256 _amount) internal {
        require(_amount > 0, "Amount must be non-zero.");
        require(balanceOf(msg.sender) >= _amount, "Insufficient tokens to burn.");

        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }

    function () external payable {}
}