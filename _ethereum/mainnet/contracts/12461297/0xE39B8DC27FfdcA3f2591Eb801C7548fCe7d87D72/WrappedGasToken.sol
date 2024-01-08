// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC20WithoutTotalSupply.sol";
import "./IGasToken.sol";

/**
* @dev Wrapped Gas Token is a wrapper for all gas tokens. It provides them with uniform functions and interface
* It also makes non-erc20 compliant tokens like GST1 and GST2, compliant.
*/
contract WrappedGasToken is IERC20, ERC20WithoutTotalSupply, Ownable{
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 constant public decimals = 0;
    address public wrappedTokenAddress;

    uint256 public totalMinted;
    uint256 public totalBurned;

    uint256 constant public protocolFee = 2;

    address public feeAddress;

    /**
    * @dev We set the main elements of our wrapped token here.
    * the name, symbol and fee address and address of the underlying gas token
    */
    constructor(address _tokenAddress, address _feeAddress, string memory _name, string memory _symbol) {
        feeAddress = _feeAddress;
        wrappedTokenAddress = _tokenAddress;
        name = _name;
        symbol = _symbol;
    }


    /**
    * @dev returns total supply of the wrapped gas token
    */
    function totalSupply() public view override returns(uint256) {
        return totalMinted - totalBurned;
    }

    /**
    * @dev calculates the protocol fee. This is 1 + x% of the wrapped tokens. 
    * It scales based on the number of tokens wrapped in the transaction.
    * the x% is based on the manner in which the user decided to mint the token.
    * if they minted using the discounted or burned methods from the protocol, then they have a lower %.
    */
    function calculateFee(uint256 value, uint256 feeValue) public pure returns(uint256){
        uint256 fee = 1;
        fee = fee.add(value.div(100).mul(feeValue));
        return fee;
    }

    /**
    * @dev This function mints new wrapped gas tokens.
    * This is done by transfering the gas token to this contract
    * issuing wrapped gas tokens to the user
    * issuing wrapped gas tokens equal to the fee, to the fee address.
    */
    function mint(uint256 value) public {
        require(IERC20(wrappedTokenAddress).transferFrom(msg.sender, address(this), value), "GSVE: Gas Token Wrap Transfer Failed");
        uint256 fee = calculateFee(value, protocolFee);
        uint256 valueAfterFee =  value.sub(fee, "GSVE: Minted Value must be larger than fee");
        _mint(msg.sender, valueAfterFee);
        _mint(feeAddress, fee);
        totalMinted = totalMinted + value;
    }

    /**
    * @dev This function mints new wrapped gas tokens at a discount
    * it is guided by the protocols fee and tier system 
    * as the protocol is the owner of this contract, it is the only one that can interact with it.
    * The process is the same as minting. We transfer the gas token to this contract
    * issuing wrapped gas tokens to the user
    * issuing wrapped gas tokens equal to the fee, to the fee address, if there is a fee to be paid.
    */
    function discountedMint(uint256 value, uint256 discountedFee, address recipient) public onlyOwner {
        require(IERC20(wrappedTokenAddress).transferFrom(recipient, address(this), value), "GSVE: Gas Token Wrap Transfer Failed");
        uint256 fee = 0;
        if(discountedFee>0){
            fee = calculateFee(value, discountedFee);
        }
        uint256 valueAfterFee =  value.sub(fee, "GSVE: Minted Value must be larger than fee");
        _mint(recipient, valueAfterFee);

        if(fee>0){
            _mint(feeAddress, fee);
        }
        
        totalMinted = totalMinted + value;
    }

    /**
    * @dev This function allows the user to unwrap gas tokens
    * this is done by burning wrapped gas tokens from the user
    * transfering the equivelent number of gas tokens to the user.
    */
    function unwrap(uint256 value) public {
        if(value > 0){
            _burn(msg.sender, value);
            IERC20(wrappedTokenAddress).transfer(msg.sender, value);
            totalMinted = totalMinted + value;
        }
    }


    /**
    * @dev This function burns the wrapped gas token,
    * burns the equivelent gas tokens, and frees up the gas
    */
    function free(uint256 value) public returns (uint256)  {
        if (value > 0) {
            _burn(msg.sender, value);
            totalBurned = totalBurned + value;
            IGasToken(wrappedTokenAddress).free(value);
        }
        return value;
    }

    /**
    * @dev a safe way of freeing up x number of tokens
    * up to the users balance
    */
    function freeUpTo(uint256 value) public returns (uint256) {
        return free(Math.min(value, balanceOf(msg.sender)));
    }

    /**
    * @dev This function burns the wrapped gas token from a specified address,
    * burns the equivelent gas tokens, and frees up the gas
    */
    function freeFrom(address from, uint256 value) public returns (uint256) {
        if (value > 0) {
            _burnFrom(from, value);
            totalBurned = totalBurned + value;
            IGasToken(wrappedTokenAddress).free(value);
        }
        return value;
    }

    /**
    * @dev a safe way of freeing up x number of tokens
    * up to the users balance
    */
    function freeFromUpTo(address from, uint256 value) public returns (uint256) {
        return freeFrom(from, Math.min(Math.min(value, balanceOf(from)), allowance(from, msg.sender)));
    }

    /**
    * @dev a method for updating the address that receives the fees.
    * This is set by the owner, which will be the protocol.
    */
    function updateFeeAddress(address newFeeAddress) public onlyOwner {
        feeAddress = newFeeAddress;
    }
    
}
