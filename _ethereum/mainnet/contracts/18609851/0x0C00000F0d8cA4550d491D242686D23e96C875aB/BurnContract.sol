pragma solidity 0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract BurnContract is Ownable {
    // @dev SafeERC20 unnecessary, contract to be used with known tokens

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public constant inputTokenAddress = 0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704;
    address public constant flashTokenAddress = 0xB1f1F47061A7Be15C69f378CB3f69423bD58F2F8;
    address public immutable epochTokenAddress;
    mapping(address => uint256) public redemptionRate;
    uint256 public immutable startDate;
    uint256 public endDate = 1735689600;

    constructor(
        address _epochTokenAddress,
        uint256 _flashRedemptionRate,
        uint256 _epochRedemptionRate,
        uint256 _startDate,
        address _newOwner
    ) Ownable(_newOwner) {
        epochTokenAddress = _epochTokenAddress;
        redemptionRate[flashTokenAddress] = _flashRedemptionRate;
        redemptionRate[epochTokenAddress] = _epochRedemptionRate;
        startDate = _startDate;
    }

    function setEndDate(uint256 _newEndDate) public onlyOwner {
        require(_newEndDate < endDate);
        endDate = _newEndDate;
    }

    // @notice Redeems specific number of XIO tokens
    function redeem(uint256 _tokenAmount) public {
        require(block.timestamp >= startDate, "REDEMPTION NOT STARTED");
        require(block.timestamp < endDate, "REDEMPTION ENDED");

        // Burn the input token from the user
        IERC20(inputTokenAddress).transferFrom(msg.sender, burnAddress, _tokenAmount);

        uint256 flashTokenAmount = (_tokenAmount * redemptionRate[flashTokenAddress]) / 1e18;
        uint256 epochTokenAmount = (_tokenAmount * redemptionRate[epochTokenAddress]) / 1e18;

        // Transfer both Flash and EPOCH to the user
        IERC20(flashTokenAddress).transfer(msg.sender, flashTokenAmount);
        IERC20(epochTokenAddress).transfer(msg.sender, epochTokenAmount);
    }

    // @notice Redeems all held XIO tokens
    function redeemAll() external {
        redeem(IERC20(inputTokenAddress).balanceOf(msg.sender));
    }

    // @notice After end date, allows burning of all remaining EPOCH and transfers remaining Flash to Flash treasury
    function end() external {
        require(block.timestamp > endDate, "REDEMPTION STILL ACTIVE");

        uint256 flashTokenAmount = IERC20(flashTokenAddress).balanceOf(address(this));
        uint256 epochTokenAmount = IERC20(epochTokenAddress).balanceOf(address(this));

        IERC20(flashTokenAddress).transfer(0x8603FfE7B00CCd759f28aBfE448454A24cFba581, flashTokenAmount);
        ERC20Burnable(epochTokenAddress).burn(epochTokenAmount);
    }

    // @notice After end date and once "end" has been called, deletes this contract from blockchain
    function end2() external {
        // @dev selfdestruct is deprecated and may introduce breaking changes
        // @dev therefore it has been implemented separately.
        require(block.timestamp > endDate, "REDEMPTION STILL ACTIVE");

        uint256 flashTokenAmount = IERC20(flashTokenAddress).balanceOf(address(this));
        uint256 epochTokenAmount = IERC20(epochTokenAddress).balanceOf(address(this));
        require(flashTokenAmount == 0 && epochTokenAmount == 0, "BALANCE REMAINING");

        selfdestruct(payable(address(0)));
    }
}
