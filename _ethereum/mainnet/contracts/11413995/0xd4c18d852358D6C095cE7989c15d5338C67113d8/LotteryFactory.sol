//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./AskoLotteryToken.sol";
import "./IAskoStaking.sol";
import "./console.sol";

contract LotteryFactory is AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _currLotteryRoundCounter;

    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router02;

    IAskoStaking public askoStaking;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    address payable public admin;

    address[] public lotteryAddresses;

    address[] public registeredStakers;
    Counters.Counter private _registeredStakersLengthCounter;

    event NewLottery(address lotteryAddress);

    constructor(
        address payable _admin,
        address _askoStaking,
        address _uniswapV2Factory,
        address _uniswapV2Router02
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MANAGER_ROLE, _admin);
        admin = _admin;
        askoStaking = IAskoStaking(_askoStaking);
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Factory);
        uniswapV2Router02 = IUniswapV2Router02(_uniswapV2Router02);
    }

    function startLotteryPresale(
        string memory _lotteryTokenName,
        string memory _lotteryTokenSymbol,
        uint256 _lotteryTokenPrice,
        uint256 _lotteryTokenMaxSupply,
        uint256 _ETHMaxSupply,
        uint256 _uniswapTokenSupplyPercentNumerator,
        uint256 _stakerETHRewardsPercentNumerator,
        uint256 _adminFeesETHPercentNumerator
    ) public {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");

        AskoLotteryToken newLotteryToken = new AskoLotteryToken(
            [
                address(uniswapV2Factory),
                address(uniswapV2Router02),
                address(askoStaking),
                address(this)
            ],
            admin,
            _lotteryTokenName,
            _lotteryTokenSymbol,
            _lotteryTokenPrice,
            _lotteryTokenMaxSupply,
            _ETHMaxSupply,
            _uniswapTokenSupplyPercentNumerator,
            _stakerETHRewardsPercentNumerator,
            _adminFeesETHPercentNumerator,
            _currLotteryRoundCounter.current()
        );

        lotteryAddresses.push(address(newLotteryToken));

        _currLotteryRoundCounter.increment();

        emit NewLottery(address(newLotteryToken));
    }

    function currentLotteryRound() public view returns (uint256 currRound) {
        return _currLotteryRoundCounter.current();
    }

    function isStakerRegistered(address staker)
        public
        view
        returns (bool registered)
    {
        for (
            uint256 i = 0;
            i < _registeredStakersLengthCounter.current();
            i++
        ) {
            if (registeredStakers[i] == staker) {
                return true;
            }
        }
        return false;
    }

    function registerStaker() public {
        require(
            isStakerRegistered(msg.sender) == false,
            "Staker has already been registered"
        );
        registeredStakers.push(msg.sender);
        _registeredStakersLengthCounter.increment();
    }

    function getRegisteredStakersLength() public view returns (uint256 length) {
        return _registeredStakersLengthCounter.current();
    }
}
