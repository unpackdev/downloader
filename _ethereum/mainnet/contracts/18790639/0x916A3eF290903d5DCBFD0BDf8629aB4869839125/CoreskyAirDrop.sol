// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./console.sol";

contract CoreskyAirDrop is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct ApNFTDrop{
        uint256 batchNo;
        address user;
        address token;
        uint256 amount;
        uint256 searilNo;
    }

    // dropBatchNo => searilNo 
    mapping(uint256=> uint256[]) private batchNoMap;
    // searilNo => ApNFTDrop 
    mapping(uint256=> ApNFTDrop) private searilNoMap;

    // Airdrop token event
    event AirDropToken(address indexed token, address indexed to, uint256 indexed amount, uint256 time, uint256 searilNo, uint256 batchNo);

    constructor(
        address admin,
        address operator
        ) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(OPERATOR_ROLE, operator);
    }

    /**
     * batch transfer  native token
     */
    function sendNativeToken(address[] calldata _to, uint256[] calldata _value)
        public
        payable
        onlyRole(OPERATOR_ROLE)
        returns (bool _success)
    {
        assert(_to.length == _value.length);
        assert(_to.length <= 1000);
        uint256 beforeValue = msg.value;
        uint256 afterValue = 0;
        for (uint256 i = 0; i < _to.length; i++) {
            afterValue = afterValue + _value[i];
            assert(payable(_to[i]).send(_value[i]));
        }
        uint256 remainingValue = beforeValue - afterValue;
        if (remainingValue > 0) {
            assert(payable(msg.sender).send(remainingValue));
        }
        return true;
    }

    /**
     * batch transfer erc20 token
     */
    function sendERC20(
        uint256 _batchNo,
        address _tokenAddress,
        address[] calldata _to,
        uint256[] calldata _value,
        uint256[] calldata _serilNo
    ) public onlyRole(OPERATOR_ROLE) returns (bool _success) {
        require(_to.length == _value.length, "The length of array [_to] and array [_value] does not match");
        require(_to.length == _serilNo.length, "The length of array [_to] and array [_serilNo] does not match");
        require(_to.length <= 1000, "The maximum limit of 1000");
        ERC20 token = ERC20(_tokenAddress);
        
		uint256 allowed = token.allowance(msg.sender,address(this));
        uint256 total = 0;
        for (uint256 i = 0; i < _value.length; i++) {
            total += _value[i];
        }
        
		console.log("sendERC20Token allowed %s value:%s, pay total:%s",address(this), allowed, total);
        require(total <= allowed, "ERC20 Token Insufficient limit");

        for (uint256 i = 0; i < _to.length; i++) {
			uint256 amount =  _value[i];
			console.log("sendERC20Token from: %s to %s, value:%s",msg.sender, _to[i], amount);
            assert(token.transferFrom(address(msg.sender), _to[i], amount) == true);
            emitAirDropToken(_batchNo,_tokenAddress,_to[i], _value[i], _serilNo[i]);
        }
        return true;
    }

    function emitAirDropToken(
        uint256 _batchNo,
        address _tokenAddress,
        address _to,
        uint256 _value,
        uint256 _serilNo
    ) internal {
        // mapping(uint256=> uint256[]) private batchNoMap;
        batchNoMap[_batchNo].push(_serilNo);
        //mapping(uint256=> ApNFTDrop) private searilNoMap;
        searilNoMap[_serilNo] = ApNFTDrop(_batchNo,_to, _tokenAddress,_value,_serilNo);
        //  event AirDropToken(address indexed token, address indexed to, uint256 indexed amount, uint256 time, uint256 searilNo, uint256 batchNo);
        emit AirDropToken(_tokenAddress, _to, _value, block.timestamp, _serilNo, _batchNo);
    }


    function getApNFTDrop(uint256 _serilNo)
        external
        view
        returns (uint256, address, address, uint256, uint256)
    {
        ApNFTDrop storage drop = searilNoMap[_serilNo];
        return (drop.batchNo, drop.user, drop.token, drop.amount, drop.searilNo);
    }

    function getBatchSerilNo(uint256 _batchNo)
        external
        view
        returns (uint256[] memory)
    {
        return batchNoMap[_batchNo];
    }

}
