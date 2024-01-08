// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.8;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
//import "./SafeMath.sol";
import "./Ownable.sol";

contract DollarToken is Context, ERC20, Ownable, ReentrancyGuard {

    //using SafeMath for uint256;

    address public treasuryAddress = 0x5cEb0921A12B78508E6373DC9CdE6522fb341499; // SET BEFORE DEPLOYMENT
    uint public taxPercent = 1000; // 1000 = 10.00%
    mapping (address => bool) private _isExcludedFromFee;
    uint private totalSupply_ = 10**10 * 10**18;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(_msgSender(), totalSupply_);
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;          
        _isExcludedFromFee[treasuryAddress] = true;          
    }

    function setTreasuryAddress(address treasuryAddress_) external onlyOwner {
        require(treasuryAddress_ != address(0), "treasuryAddress_ = 0");
        require(treasuryAddress_ != treasuryAddress, "treasuryAddress is the same");
        _isExcludedFromFee[treasuryAddress] = false;          
        treasuryAddress = treasuryAddress_;
        _isExcludedFromFee[treasuryAddress] = true;          
    }

    function setTaxPercent(uint taxPercent_) external onlyOwner {
        taxPercent = taxPercent_;
    }

    function setIsExcluded(address address_, bool excluded_) external onlyOwner {
        _isExcludedFromFee[address_] = excluded_;
    }

    function isExcluded(address address_) external view returns(bool) {
        return _isExcludedFromFee[address_];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(amount > 0, "amount = 0");
        require(amount <= balanceOf(_msgSender()));
        uint taxAmount = _isExcludedFromFee[_msgSender()] || _isExcludedFromFee[recipient] ? 0 : amount * taxPercent / 10000;
        _transfer(_msgSender(), treasuryAddress, taxAmount);
        _transfer(_msgSender(), recipient, amount - taxAmount);
        return true;
    }    

    /*******************/
    /*  GENERAL ADMIN  */
    /*******************/

    function recoverERC20InEmergency(address _token) external onlyOwner nonReentrant {
        IERC20(_token).transfer(_msgSender(), IERC20(_token).balanceOf(address(this)));
        emit Withdraw(_msgSender(), _token);
    }
    
    function recoverNativeTokenInEmergency() external onlyOwner nonReentrant {
        (bool sent, bytes memory data) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
        emit RecoverNativeTokenInEmergency(_msgSender());
    }  

    event Withdraw(address msgSender, address token);
    event RecoverNativeTokenInEmergency(address msgSender);      
}