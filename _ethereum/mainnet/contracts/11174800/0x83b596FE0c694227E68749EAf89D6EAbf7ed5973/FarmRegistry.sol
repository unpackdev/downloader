pragma solidity ^0.5.17;

import "./Farm.sol";

contract FarmRegistry is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    Farm[] public farms;
    IERC20 public crop;
    address public distributor;

    event NewFarm(address indexed farm, uint256 totalYield, uint256 start, uint256 duration);

    constructor (IERC20 _crop, address _distributor) public {
        // say farm one more time motherfucker
        farms = new Farm[](0);
        crop = _crop;
        distributor = _distributor;
    }

    function addNewFarm(Farm farm, uint256 totalYield, uint256 start, uint256 duration) public onlyOwner {
        require(totalYield <= remainingCrops(), "cant afford new farm");

        farms.push(farm);
        crop.safeTransfer(address(farm), totalYield);

        farm.initialize(start, duration);
        farm.setRewardDistribution(address(this));
        farm.notifyRewardAmount(totalYield);
        farm.setRewardDistribution(distributor);

        emit NewFarm(address(farm), totalYield, start, duration);
    }

    function remainingCrops() public returns (uint256) {
        return crop.balanceOf(address(this));
    }
}
