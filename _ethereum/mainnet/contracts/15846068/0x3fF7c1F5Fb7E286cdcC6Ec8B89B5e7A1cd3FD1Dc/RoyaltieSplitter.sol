// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./Genkei.sol";
import "./ReentrancyGuard.sol";


contract RoyaltieSplitter is Ownable, ReentrancyGuard {

uint256[] public _royalals;
uint256[] public _mixed;
Genkei public _token;
address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;

    /*
     * set the Genkei Contract
    */
    function bindTokenContract(address payable token) external onlyOwner{
        // don't forget to set owner of the token contract to this contract!
        _token = Genkei(token);
    }

    /*
     * set the Royal Id's
    */
    function setRoyals(uint256[] memory royalals) external onlyOwner{
        _royalals=royalals;
    }

    /*
     * set the Mixed Id's
    */
    function setMixed(uint256[] memory mixed) external onlyOwner{
        _mixed=mixed;
    }

    /*
    * Witdraw to split the royalties. Note that ANYBODY can call that.
    * Method is nonReentrant.
    */
    function withdraw() external nonReentrant{
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        uint length = _royalals.length;
        uint256 payout = (balance/4)/length;
        for(uint256 i; i < length;){
            if (_token.exists(_royalals[i])){
                _withdraw(_token.ownerOf(_royalals[i]), payout);
            }
            unchecked{ i++;}
        }
        length = _mixed.length;
        payout = (balance/20)/length;
        for(uint256 i; i < length;){
            if (_token.exists(_mixed[i])){
                _withdraw(_token.ownerOf(_mixed[i]), payout);
            } 
            unchecked{ i++;}
        }
        _withdraw(FRANK, balance/20);       
        _withdraw(owner(), address(this).balance);
    }

    /*
    * Withdraw function, for when something would go wrong with the splitter.
    */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(owner(), address(this).balance);
    }

    /**
    * Helper method to allow ETH withdraws.
    */
    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to withdraw Ether");
    }

    // contract can recieve Ether
    receive() external payable { }

}