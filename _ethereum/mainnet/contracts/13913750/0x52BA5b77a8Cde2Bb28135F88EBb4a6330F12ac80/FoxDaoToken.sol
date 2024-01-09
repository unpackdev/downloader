// SPDX-License-Identifier: MIT
pragma solidity =0.6.11;

import "./ERC20.sol";
import "./IFoxDaoToken.sol";


contract FoxDaoToken is ERC20, IFoxDaoToken {

    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 1e14 * 1e18;
    uint256 public constant MINT_DEADLINE = 1648771200;

    uint256 public constant AMOUNT_OF_LP = MAX_SUPPLY / 10000;
    address public constant LP_ADDRESS = address(0xDF030ce3eD17653d6207bcF296F57b63BecBfebF);

    uint256 public constant AMOUNT_OF_FOX_DAO = (MAX_SUPPLY * 20 / 100) - AMOUNT_OF_LP;
    uint256 public constant AMOUNT_OF_STABLE_COIN = MAX_SUPPLY * 20 / 100;
    uint256 public constant AMOUNT_OF_VESTING_STAKING = MAX_SUPPLY * 10 / 100;


    address public manager;
    address public distributor;

    constructor (
        address foxDaoReceiver,
        address stableCoinReceiver,
        address vestingStakingReceiver
    ) ERC20("Fox DAO", "FOX") public {
        manager = msg.sender;
        _mint(foxDaoReceiver, AMOUNT_OF_FOX_DAO);
        _mint(stableCoinReceiver, AMOUNT_OF_STABLE_COIN);
        _mint(vestingStakingReceiver, AMOUNT_OF_VESTING_STAKING);
        _mint(LP_ADDRESS, AMOUNT_OF_LP);
    }

    function setDistributor(address _distributor) external {
        require(msg.sender == manager, "FoxDaoToken: not manager");
        distributor = _distributor;
        manager = address(0);
    }

    function mint(address account, uint256 amount) external override {
        require(block.timestamp <= MINT_DEADLINE, "FoxDaoToken: can not mint anymore");
        require(msg.sender == distributor, "FoxDaoToken: not distributor");

        uint256 currentSupply = totalSupply();
        if (currentSupply.add(amount) > MAX_SUPPLY) {
            amount = MAX_SUPPLY.sub(currentSupply);
        }
        _mint(account, amount);
    }
}
