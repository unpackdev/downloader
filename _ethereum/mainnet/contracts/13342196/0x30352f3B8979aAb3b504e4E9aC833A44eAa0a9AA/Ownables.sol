//SPDX-License-Identifier: Unlicense
pragma solidity ^ 0.8.0;
import "./Ownable.sol";
import "./SafeMath.sol";


abstract contract Ownables is Ownable {

    using SafeMath for uint256;

    address private _secondOwner;

    modifier onlySecondOwner() {
        require(secondOwner() == _msgSender(), "Not second owner");
        _;
    }

    modifier onlyOwners () {
         require(
            owner() == _msgSender() || secondOwner() == _msgSender(), 
            "Owners only");
        _;
    }

    function transferSecondOwnership(address newSecondOwner_) public virtual onlySecondOwner {
        require(newSecondOwner_ != address(0), "zero address owner");
       _setSecondOwner(newSecondOwner_);
    }

    function renounceSecondOwnership() public virtual onlySecondOwner {
        _setSecondOwner(address(0));
    }
    
    function _setSecondOwner(address newSecondOwner_) internal {
         _secondOwner = newSecondOwner_;
    }
    
    function secondOwner() public view virtual returns (address) {
        return _secondOwner;
    }

    function withdraw() public onlyOwners {

        uint256 balance = address(this).balance;
        uint256 share = balance.div(2);

        payable(owner()).transfer(share);
        payable(secondOwner()).transfer(share);

    }


}
