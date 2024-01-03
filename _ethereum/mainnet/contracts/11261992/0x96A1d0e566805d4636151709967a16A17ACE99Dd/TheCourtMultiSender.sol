pragma solidity >=0.4.22 <0.8.0;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./EternalStorage.sol";

/**
 * @title Multi Sender, support ETH and ERC20 Tokens
 * @dev To Use this Dapp: https://bulksender.app
*/

contract TheCourtMultiSender is Ownable, EternalStorage {

    using SafeMath for uint;
    
    address dummy = 0x000000000000000000000000000000000000bEEF;
    
    /* Modifiers */
    
      modifier hasFee() {
        if (currentFee(msg.sender) > 0) {
            require(msg.value >= currentFee(msg.sender));
        }
        _;
    }
    
    /* Events */
    
    event Multisended(uint256 total, address tokenAddress);

    /* Initializers */

    constructor() public {
        require(!initialized());
        setArrayLimit(10);
        setDiscountStep(0.00005 ether);
        setFee(0 ether);
        boolStorage[keccak256("rs_multisender_initialized")] = true;
    }
    
    
    function initialized() public view returns (bool) {
        return boolStorage[keccak256("rs_multisender_initialized")];
    }
    
    
    /* Main functions */
    
    function multisendToken(address token, address payable[] memory _contributors, uint256[] memory _balances) public hasFee payable {
        if (token == dummy){
            multisendEther(_contributors, _balances);
        } else {
            uint256 total = 0;
            require(_contributors.length <= arrayLimit());
            ERC20 erc20token = ERC20(token);
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
                erc20token.transferFrom(msg.sender, _contributors[i], _balances[i]);
                total += _balances[i];
            }
            setTxCount(msg.sender, txCount(msg.sender).add(1));
            Multisended(total, token);
        }
    }
    
    function multisendEther(address payable[] memory _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 fee = currentFee(msg.sender);
        require(total >= fee);
        require(_contributors.length <= arrayLimit());
        total = total.sub(fee);
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i], "Error Total is inferior to balance");
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        setTxCount(msg.sender, txCount(msg.sender).add(1));
        Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
    }

    


    
    /* Getters */
    
        
    function currentFee(address _customer) public view returns(uint256) {
        if (fee() > discountRate(msg.sender)) {
            return fee().sub(discountRate(_customer));
        } else {
            return 0;
        }
    }
    
    
    function fee() public view returns(uint256) {
        return uintStorage[keccak256("fee")];
    }
    
     function discountRate(address _customer) public view returns(uint256) {
        uint256 count = txCount(_customer);
        return count.mul(discountStep());
    }
    
     function txCount(address customer) public view returns(uint256) {
        return uintStorage[keccak256(abi.encode("txCount", customer))];
    }
    
    function discountStep() public view returns(uint256) {
        return uintStorage[keccak256("discountStep")];
    }
    
     function arrayLimit() public view returns(uint256) {
        return uintStorage[keccak256("arrayLimit")];
    }


    
    
    /* Setters */
    
    function setOwner(address _owner) internal {
        Ownable.transferOwnership(_owner);
    }
    
     function setArrayLimit(uint256 _newLimit) internal onlyOwner {
        require(_newLimit != 0, "You can't set an arrayLimit to 0");
        uintStorage[keccak256("arrayLimit")] = _newLimit;
    }
    
    function setDiscountStep(uint256 _newStep) internal onlyOwner {
        require(_newStep != 0, "You can't discount to 0");
        uintStorage[keccak256("discountStep")] = _newStep;
    }
    
       function setFee(uint256 _newStep) internal onlyOwner {
        //require(_newStep != 0, "You can't put a 0 fee");
        uintStorage[keccak256("fee")] = _newStep;
    }
    
     function setTxCount(address customer, uint256 _txCount) internal {
        uintStorage[keccak256(abi.encode("txCount", customer))] = _txCount;
    }


}