// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./FiresaleArt.sol";
import "./RealMath.sol";


contract LITToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable
{
    using RealMath for uint256;

    FiresaleArt public firesaleContract;

    // Bonding curve constants
    // See: https://www.desmos.com/calculator/ymtgwhewle
    uint256 private constant CURVE_EXP = 500000000000000000;
    uint256 private constant CURVE_BASE = 1000000000000000000000;
    uint256 private constant CURVE_HALVING = 5000000000000000000000000;

    uint128 private _treasuryBasisPoints; // share of $LIT that goes into the treasury

    function initialize() public initializer {
        __ERC20_init("FiresaleArt", "LIT");
        __Ownable_init();
        _treasuryBasisPoints = 500;
    }

    modifier onlyFireSaleContract() {
        require(msg.sender == address(firesaleContract));
        _;
    }

    function getRate() public view returns (uint256) {
        return CURVE_EXP.rpow(totalSupply().rdiv(CURVE_HALVING)).rmul(CURVE_BASE);
    }

    function setFireSaleContract(FiresaleArt contractAddress)
        public
        virtual
        onlyOwner
    {
        firesaleContract = contractAddress;
    }

    function setTreasuryBasisPoints(uint128 basisPoints)
        public
        virtual
        onlyOwner
    {
        require(
            basisPoints < 10000,
            "NFT2ERC20: basisPoints must be less than 10000 (100%)"
        );
        _treasuryBasisPoints = basisPoints;
    }

    /**
     * @dev mint per a bonding curve
     * https://www.desmos.com/calculator/3iwuckklf1
     */
    function mint(
        address tokenContract,
        uint128 numTokens,
        address receiver
    ) public virtual onlyFireSaleContract {
        require(
            msg.sender == address(firesaleContract),
            "Only Firesale contract can call this."
        );
        uint256 rate = getRate();
        address treasury = firesaleContract.getTreasury();

        _mint(receiver, rate * numTokens);

        // Treasury gets additional minted $LIT
        if (_treasuryBasisPoints > 0 && treasury != address(0x0)) {
            uint256 treasuryRate = (rate * _treasuryBasisPoints) / 10000;
            if (treasuryRate > 0) {
                _mint(treasury, treasuryRate * numTokens);
            }
        }
    }
}