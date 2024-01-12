// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./IConvex.sol";
import "./IRewards.sol";
import "./IAPContract.sol";
import "./IHexUtils.sol";

contract NAVUtils {
    mapping(address => address) convexDepositCurve;
    address public convexDeposit = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public cvxRewards = 0xCF50b810E57Ac33B91dCF525C6ddd9881B139332;
    address public cvxCRVRewards = 0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
    address public owner;
    address public APContract;

    constructor(address _apContract) {
        owner = msg.sender;
        convexDepositCurve[
            0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7
        ] = 0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
        convexDepositCurve[
            0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B
        ] = 0xCF50b810E57Ac33B91dCF525C6ddd9881B139332;
        APContract = _apContract;
    }

    function changeOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }

    function changeAPS(address _APS) external {
        require(msg.sender == owner);
        APContract = _APS;
    }

    function modifyMapping (address _key, address _value) external {
        require(msg.sender == owner);
        convexDepositCurve[_key] = _value;
    }

    function addToMapping(address _base, uint256 _poolId) external {
        require(msg.sender == owner);
        (, , , address baseRewards, , ) = IConvex(convexDeposit).poolInfo(
            _poolId
        );
        convexDepositCurve[_base] = baseRewards;
    }

    function addToMappingBatch(
        address[] calldata _base,
        uint256[] calldata _poolId
    ) external {
        require(msg.sender == owner);
        for (uint256 index = 0; index < _base.length; index++) {
            (, , , address baseRewards, , ) = IConvex(convexDeposit).poolInfo(
                _poolId[index]
            );
            convexDepositCurve[_base[index]] = baseRewards;
        }
    }

    function getConvexNAV(address _assetAddress)
        external
        view
        returns (uint256)
    {
        if (convexDepositCurve[_assetAddress] != address(0)) {
            uint256 tokenUSD = IAPContract(APContract).getUSDPrice(
                _assetAddress
            );
            uint256 assetBalance = IRewards(convexDepositCurve[_assetAddress])
                .balanceOf(msg.sender);

            tokenUSD =
                ((
                    IHexUtils(IAPContract(APContract).stringUtils()).toDecimals(
                        _assetAddress,
                        assetBalance
                    )
                ) * tokenUSD) /
                (1e18);
            return tokenUSD;
        } else return 0;
    }
}
