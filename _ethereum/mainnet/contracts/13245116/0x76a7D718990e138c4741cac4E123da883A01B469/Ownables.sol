//SPDX-License-Identifier: Unlicense
pragma solidity ^ 0.8.0;
import "./Ownable.sol";
import "./SafeMath.sol";


abstract contract Ownables is Ownable {

    using SafeMath for uint256;
    
    struct TransferController {

        uint256 amount;
        address sendToAddress;

    }

    address private _secondOwner;
    
    TransferController private _ownerController;
    TransferController private _secondOwnerController;

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

    modifier ownersAgreed () {
         require(
            isAmountAgreed() && isAddressAgreed(), 
            "Not agreed");
        _;
    }

    function transferSecondOwnership(address newSecondOwner_) public virtual onlySecondOwner {
        require(newSecondOwner_ != address(0), "zero address owner");
       _setSecondOwner(newSecondOwner_);
    }

    function renounceSecondOwnership() public virtual onlySecondOwner {
        _setSecondOwner(address(0));
    }

    function setOwnerTransaction(uint256 amount_, address sendToAddress_) public onlyOwners {

        if ( _msgSender() == owner() ) {

               _ownerController.amount = amount_; 
               _ownerController.sendToAddress = sendToAddress_;

        }

        if ( _msgSender() == secondOwner() ) {

               _secondOwnerController.amount = amount_; 
               _secondOwnerController.sendToAddress = sendToAddress_;
               
        }

    }
    
    function withdraw() public onlyOwners {

        uint256 balance = address(this).balance;
        uint256 share = balance.div(2);

        payable(owner()).transfer(share);
        payable(secondOwner()).transfer(share);

    }
    
    function withdrawTo(uint256 amount_ , address to_) public onlyOwners ownersAgreed {
        
        _resetAgreement(owner());
        _resetAgreement(secondOwner());

        payable(to_).transfer(amount_);

    }


    function resetOwnerAgreement() public onlyOwners {

        _resetAgreement(_msgSender());

    }

    function _resetAgreement(address owner_) internal {

        if ( owner_ == owner() ){
            
            _ownerController.amount = 0; 
            _ownerController.sendToAddress = address(0);
        
        }

        if( owner_ == secondOwner() ){

            _secondOwnerController.amount = 0; 
            _secondOwnerController.sendToAddress = address(0);

        }

    }

    function _setSecondOwner(address newSecondOwner_) internal {
         _secondOwner = newSecondOwner_;
    }
    
    function secondOwner() public view virtual returns (address) {
        return _secondOwner;
    }

    function isAmountAgreed() public view returns (bool) {

        bool isNotNullValue = _ownerController.amount != 0 && _secondOwnerController.amount != 0;
        bool isSameAmount = _ownerController.amount == _secondOwnerController.amount;
        
        return (isNotNullValue && isSameAmount);
        
    }
    
    function isAddressAgreed() public view returns (bool) {
        
        bool isNotZeroAddress = _ownerController.sendToAddress != address(0) && _secondOwnerController.sendToAddress != address(0);
        bool isSameAddress = _ownerController.sendToAddress == _secondOwnerController.sendToAddress;
        
        return (isNotZeroAddress && isSameAddress);
        
    }


}
