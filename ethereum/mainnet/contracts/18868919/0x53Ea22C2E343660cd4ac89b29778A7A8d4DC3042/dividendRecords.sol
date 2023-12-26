pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

import "./EIP20Interface.sol";

contract DividendRecords{
    /// @notice ESG token
    EIP20Interface public esg;

    /// @notice Emitted when ESG is claimed 
    event EsgClaimed(address account, uint totalAmount);

    address private _marketingWalletAddress;
    uint256 public _feeRate = 5;
    mapping (address => uint256) public bonuslist;
    address public owner;

    constructor(address esgAddress, address _marketingWallet) public {
        owner = msg.sender;
        _marketingWalletAddress = _marketingWallet;
        esg = EIP20Interface(esgAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function setFeeRate(uint256 _fee) onlyOwner public {
        require(_fee > 0, "Fee must be positive");
        _feeRate = _fee;
    }

    function setEsgAmount(address[] memory _to, uint256[] memory _amount, uint256 _totalAmount) onlyOwner public returns (bool) {
        require(
            _to.length == _amount.length,
            "The length of the two arrays must be the same"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            bonuslist[_to[i]] += _amount[i];
        }

        uint256 fee = _totalAmount * _feeRate / 100;
        bonuslist[_marketingWalletAddress] += fee;

        return true;
    }

    function claim() public returns (bool) {
        require(bonuslist[msg.sender] > 0, "No locked amount.");
        uint256 totalAmount = bonuslist[msg.sender];
        bonuslist[msg.sender] = 0;
        esg.transfer(msg.sender, totalAmount);

        emit EsgClaimed (msg.sender, totalAmount); 
        return true;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}
