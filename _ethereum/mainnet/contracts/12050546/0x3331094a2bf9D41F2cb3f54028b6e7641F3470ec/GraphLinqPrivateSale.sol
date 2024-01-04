// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IExtendedERC20.sol";

contract GraphLinqPrivateSale {
    using SafeMath for uint256;


    address private                         _owner;
    IExtendedERC20 private                  _glqToken;
    mapping(address => uint256) private     _wallets_investment;

    uint256 public                          _ethSolded;
    uint256 public                          _glqSolded;
    uint256 public                          _glqPerEth;
    uint256 public                          _maxethPerWallet;
    bool public                             _paused = false;
    bool public                             _claim = false;

    event NewAmountPresale (
        uint256 srcAmount,
        uint256 glqPereth,
        uint256 totalGlq
    );

    /*
    ** Description: constructing the contract basic informations, containing the GLQ token addr, the ratio price eth:GLQ
    ** and the max authorized eth amount per wallet
    */
    constructor(address graphLinqTokenAddr, uint256 glqPereth, uint256 maxethPerWallet)
    {
        _owner = msg.sender;
        _ethSolded = 0;
        _glqPerEth = glqPereth;
        _glqToken = IExtendedERC20(graphLinqTokenAddr);
        _maxethPerWallet = maxethPerWallet;
    }

    /*
    ** Description: Check that the transaction sender is the GLQ owner
    */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can do this action");
        _;
    }

    /*
    ** Receive eth payment for the presale raise
    */
    receive() external payable {
        require(_paused == false, "Presale is paused");
        uint256 totalInvested = _wallets_investment[address(msg.sender)].add(msg.value);
        require(totalInvested <= _maxethPerWallet, "You depassed the limit of max eth per wallet for the presale.");
        _transfertGLQ(msg.value);
    }

    /*
    ** Description: Set the presale in pause state (no more deposits are accepted once it's turned back)
    */
    function setPaused(bool value) public payable onlyOwner {
        _paused = value;
    }

    /*
    ** Description: Set the presale claim mode 
    */
    function setClaim(bool value) public payable onlyOwner {
        _claim = value;
    }

    /*
    ** Description: Claim the GLQ once the presale is done
    */
    function claimGlq() public
    {
        require(_claim == true, "You cant claim your GLQ yet");
        uint256 srcAmount =  _wallets_investment[address(msg.sender)];
        require(srcAmount > 0, "You dont have any GLQ to claim");
        
        uint256 glqAmount = (srcAmount.mul(_glqPerEth)).div(10 ** 18);
         require(
            _glqToken.balanceOf(address(this)) >= glqAmount,
            "No GLQ amount required on the contract"
        );
        _wallets_investment[address(msg.sender)] = 0;
        _glqToken.transfer(msg.sender, glqAmount);
    }


    /*
    ** Description: Return the amount raised from the Presale (as ETH)
    */
    function getTotalRaisedEth() public view returns(uint256) {
        return _ethSolded;
    }

        /*
    ** Description: Return the amount raised from the Presale (as GLQ)
    */
    function getTotalRaisedGlq() public view returns(uint256) {
        return _glqSolded;
    }

    /*
    ** Description: Return the total amount invested from a specific address
    */
    function getAddressInvestment(address addr) public view returns(uint256) {
        return  _wallets_investment[addr];
    }

    /*
    ** Description: Transfer the specific GLQ amount to the payer address
    */
    function _transfertGLQ(uint256 _srcAmount) private {
        uint256 glqAmount = (_srcAmount.mul(_glqPerEth)).div(10 ** 18);
        emit NewAmountPresale(
            _srcAmount,
            _glqPerEth,
            glqAmount
        );

        require(
            _glqToken.balanceOf(address(this)) >= glqAmount.add(_glqSolded),
            "No GLQ amount required on the contract"
        );

        _ethSolded += _srcAmount;
        _glqSolded += glqAmount;
        _wallets_investment[address(msg.sender)] += _srcAmount;
    }

    /*
    ** Description: Authorize the contract owner to withdraw the raised funds from the presale
    */
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        _glqToken.transfer(msg.sender, _glqToken.balanceOf(address(this)));
    }
}