// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.8;

import "./AxionMine.sol";
import "./Manageable.sol";
import "./TransferHelper.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./Initializable.sol";

contract AxionMineManager is Initializable, Manageable {
    address[] internal mineAddresses;

    IUniswapV2Factory internal uniswapFactory;

    address public rewardTokenAddress;
    address public liqRepNFTAddress;
    address public OG5555_25NFTAddress;
    address public OG5555_100NFTAddress;

    function createMine(
        address _lpTokenAddress,
        uint256 _rewardTokenAmount,
        uint256 _blockReward,
        uint256 _startBlock
    ) external onlyManager {
        require(_startBlock >= block.number, 'PAST_START_BLOCK');

        IUniswapV2Pair lpPair = IUniswapV2Pair(_lpTokenAddress);

        address lpPairAddress =
            uniswapFactory.getPair(lpPair.token0(), lpPair.token1());

        require(lpPairAddress == _lpTokenAddress, 'UNISWAP_PAIR_NOT_FOUND');

        TransferHelper.safeTransferFrom(
            rewardTokenAddress,
            msg.sender,
            address(this),
            _rewardTokenAmount
        );

        AxionMine mine = new AxionMine(msg.sender);

        TransferHelper.safeApprove(
            rewardTokenAddress,
            address(mine),
            _rewardTokenAmount
        );
        
        mine.initialize(
            rewardTokenAddress,
            _rewardTokenAmount,
            _lpTokenAddress,
            _startBlock,
            _blockReward,
            liqRepNFTAddress,
            OG5555_25NFTAddress,
            OG5555_100NFTAddress
        );

        mineAddresses.push(address(mine));
    }

    function deleteMine(uint256 index) external onlyManager {
        delete mineAddresses[index];
    }

    function initialize(
        address _manager,
        address _rewardTokenAddress,
        address _liqRepNFTAddress,
        address _OG5555_25NFTAddress,
        address _OG5555_100NFTAddress,
        address _uniswapFactoryAddress
    ) public initializer {
        _setupRole(MANAGER_ROLE, _manager);

        rewardTokenAddress = _rewardTokenAddress;
        liqRepNFTAddress = _liqRepNFTAddress;
        OG5555_25NFTAddress = _OG5555_25NFTAddress;
        OG5555_100NFTAddress = _OG5555_100NFTAddress;

        uniswapFactory = IUniswapV2Factory(_uniswapFactoryAddress);
    }

    function getMineAddresses() external view returns (address[] memory) {
        return mineAddresses;
    }
}
