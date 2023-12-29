// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract SerenityShieldPresale is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    address public recipient;
    uint256 public price;
    mapping(address => uint256) public holders;
    address[] public allowedTokens;
    uint round;

    event Deposited(
        address usdTokenAddress,
        address buyer,
        uint256 usdAmount,
        uint256 tokenAmount,
        uint round
    );

    function initialize(address _recipient, uint256 _price) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __Pausable_init();

        recipient = _recipient;
        price = _price;
        round = 3;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setAllowedTokens(
        address[] memory _allowedTokens
    ) external onlyOwner {
        allowedTokens = _allowedTokens;
    }

    function setRound(uint _round) external onlyOwner {
        round = _round;
    }

    function isAllowed(address tokenAddress) internal view returns (bool) {
        for (uint idx = 0; idx < allowedTokens.length; idx++) {
            if (allowedTokens[idx] == tokenAddress) {
                return true;
            }
        }

        return false;
    }

    function deposit(
        address usdTokenAddress,
        uint256 usdAmount,
        address buyer
    ) external whenNotPaused {
        // Check token address is in allowed list
        require(isAllowed(usdTokenAddress), "Submitted token is not allowed");

        // Transfer token
        IERC20(usdTokenAddress).safeTransferFrom(
            msg.sender,
            recipient,
            usdAmount
        );
        uint256 tokenAmount = (usdAmount * price) / 10000;
        holders[msg.sender] += tokenAmount;

        emit Deposited(usdTokenAddress, buyer, usdAmount, tokenAmount, round);
    }

    function pause() public {
        _pause();
    }

    function unpause() public {
        _unpause();
    }
}
