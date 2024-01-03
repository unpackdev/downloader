// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./console.sol";
import "./ITerminal.sol";
import "./IARVO.sol";

contract Terminal is ITerminal, Ownable {
    using SafeMath for uint256;

    IARVO private ARVO;

    address private stakingContract;
    address private farmingContract;
    address private nodesContract;

    uint256 public maximumSupply = 200000 * 10**18; // 20000 Arvo

    modifier onlyFarmingOrStakingOrNodes() {
        require(
            (farmingContract == _msgSender() ||
                stakingContract == _msgSender() ||
                nodesContract == _msgSender()),
            '[2502] TERMINAL: the caller is not farming or staking or nodes contracts'
        );
        _;
    }

    constructor(address _arvoToken) public Ownable() {
        ARVO = IARVO(_arvoToken);
    }

    // emergency change the contract address will be expired with burn the owner address
    function changeStakingContract(address _stakingContract)
        external
        onlyOwner
    {
        console.log("dubagging contract: ", _stakingContract);
        require(
            _stakingContract != address(0),
            '[2501] TERMINAL: the caller from the zero address'
        );
        stakingContract = _stakingContract;
    }

    // emergency change the contract address will be expired with burn the owner address
    function changeFarmingContract(address _farmingContract)
        external
        onlyOwner
    {
        require(
            _farmingContract != address(0),
            '[2501] TERMINAL: the caller from the zero address'
        );
        farmingContract = _farmingContract;
    }

    // emergency change the contract address will be expired with burn the owner address
    function changeNodesContract(address _nodesContract) external onlyOwner {
        require(
            _nodesContract != address(0),
            '[2501] TERMINAL: the caller from the zero address'
        );
        nodesContract = _nodesContract;
    }

    function mint(address _beneficiary, uint256 _amount)
        external
        override
        onlyFarmingOrStakingOrNodes
    {
        uint256 finalTotalSupply = _amount.add(ARVO.totalSupply());
        if (
            finalTotalSupply > maximumSupply &&
            ARVO.totalSupply() < maximumSupply
        ) {
            _amount = maximumSupply.sub(ARVO.totalSupply());
        } else if (ARVO.totalSupply() >= maximumSupply) {
            revert('[2500] TERMINAL: you exceeded the limit');
        }

        ARVO.mint(_beneficiary, _amount);
    }

    function burn(address _beneficiary, uint256 _amount)
        external
        override
        onlyFarmingOrStakingOrNodes
    {
        ARVO.burn(_beneficiary, _amount);
    }

    function personalBurn(uint256 _amount) external override {
        ARVO.burn(address(msg.sender), _amount);
    }

    function getMaximumSupply() public override view returns (uint256) {
        return maximumSupply;
    }
}
