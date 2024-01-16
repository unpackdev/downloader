// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./ICVXToken.sol";
import "./IAPContract.sol";
import "./IHexUtils.sol";
import "./IRewards.sol";
import "./IConvex.sol";

//TODO make upgradeable
contract ConvexCurveBalance {
    address public owner;
    address public APContract;
    address internal convexBoosterDeposit =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address internal CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    uint256[] public supportedConvexCurvePools;

    constructor() {
        owner = msg.sender;
        APContract = address(0x8C1c01a074f8C321d568fd083AFf84Fd020c033D);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    /// @dev Function to set address of Owner.
    /// @param _owner Address of new owner.
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function getCVXBalance(address _vault) public view returns (uint256) {
        //use current supply to gauge cliff
        //this will cause a bit of overflow into the next cliff range
        //but should be within reasonable levels.
        //requires a max supply check though

        uint256 _amount = getCRVBalance(_vault);
        ICVXToken cvx = ICVXToken(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
        uint256 supply = cvx.totalSupply();
        uint256 reductionPerCliff = cvx.reductionPerCliff();
        uint256 totalCliffs = cvx.totalCliffs();
        uint256 maxSupply = cvx.maxSupply();
        uint256 cliff = supply / reductionPerCliff;
        //mint if below total cliffs
        if (cliff < totalCliffs) {
            //for reduction% take inverse of current cliff
            uint256 reduction = totalCliffs - cliff;
            //reduce
            _amount = (_amount * reduction) / totalCliffs;
            //supply cap check
            uint256 amtTillMax = maxSupply - supply;
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }
        }

        // uint256 tokenUSD = IAPContract(APContract).getUSDPrice(
        //     0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B
        // );
        // uint256 totalCVXPrice = (tokenUSD * _amount) / (1e18);
        return _amount;
    }

    function getCRVBalance(address _vault) public view returns (uint256) {
        uint256 crvEarned;

        for (
            uint256 index = 0;
            index < supportedConvexCurvePools.length;
            index++
        ) {
            (, , , address baseRewards, , ) = IConvex(convexBoosterDeposit)
                .poolInfo(supportedConvexCurvePools[index]);
            uint256 rewardsEarned = IRewards(baseRewards).earned(_vault);
            crvEarned = crvEarned + rewardsEarned;
        }
        return crvEarned;
    }

    function getExtraRewardBalance(address _vaultAddress)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 counter;

        for (
            uint256 index = 0;
            index < supportedConvexCurvePools.length;
            index++
        ) {
            (, , , address baseRewards, , ) = IConvex(convexBoosterDeposit)
                .poolInfo(supportedConvexCurvePools[index]);
            uint256 balance = IRewards(baseRewards).balanceOf(_vaultAddress);
            if (balance > 0) {
                counter++;
            }
        }

        address[] memory assets = new address[](counter);
        uint256[] memory balances = new uint256[](counter);

        for (
            uint256 index = 0;
            index < supportedConvexCurvePools.length;
            index++
        ) {
            uint256 tempCounter;
            (, , , address baseRewards, , ) = IConvex(convexBoosterDeposit)
                .poolInfo(supportedConvexCurvePools[index]);
            uint256 extraRewardsLength = IRewards(baseRewards)
                .extraRewardsLength();
            for (uint256 index = 0; index < extraRewardsLength; index++) {
                address rewardContract = IRewards(baseRewards).extraRewards(
                    index
                );
                uint256 rewardsEarned = IRewards(rewardContract).earned(_vaultAddress);
                if (rewardsEarned > 0) {
                    address rewardToken = IRewards(rewardContract)
                        .rewardToken();
                    assets[tempCounter] = rewardToken;
                    balances[tempCounter] = rewardsEarned;
                    ++tempCounter;
                }
            }

            return (assets, balances);
        }
    }

    function getConvexStakeBalance(address _vault)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 counter;

        for (
            uint256 index = 0;
            index < supportedConvexCurvePools.length;
            index++
        ) {
            (, , , address baseRewards, , ) = IConvex(convexBoosterDeposit)
                .poolInfo(supportedConvexCurvePools[index]);
            uint256 balance = IRewards(baseRewards).balanceOf(_vault);
            if (balance > 0) {
                counter++;
            }
        }

        address[] memory assets = new address[](counter);
        uint256[] memory balances = new uint256[](counter);

        for (
            uint256 index = 0;
            index < supportedConvexCurvePools.length;
            index++
        ) {
            uint256 counter2;
            (, address token, , address baseRewards, , ) = IConvex(
                convexBoosterDeposit
            ).poolInfo(supportedConvexCurvePools[index]);

            uint256 balance = IRewards(baseRewards).balanceOf(_vault);
            if (balance > 0) {
                assets[counter2] = token;
                balances[counter2] = balance;
                counter2++;
            }
        }
        return (assets, balances);
    }

    function setSupportedConvexCurvePool(uint256 _poolid) public onlyOwner {
        supportedConvexCurvePools.push(_poolid);
    }

    function setSupportedConvexCurvePoolsBatch(uint256[] calldata _poolids)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < _poolids.length; index++) {
            setSupportedConvexCurvePool(_poolids[index]);
        }
    }

    function removeSupportedConvexCurvePool(uint256 _index) public onlyOwner {
        supportedConvexCurvePools[_index] = supportedConvexCurvePools[
            supportedConvexCurvePools.length
        ];
        supportedConvexCurvePools.pop();
    }

    function removeSupportedConvexCurvePoolsBatch(uint256[] calldata _indices)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < _indices.length; index++) {
            removeSupportedConvexCurvePool(_indices[index]);
        }
    }
}
