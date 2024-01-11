// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title NCCoin
 **/
contract NCCoin is ERC20, Ownable {
    using SafeMath for uint256;
    address[] approvedContracts;

    /**
     * @dev Total supply of 1 billion tokens gets minted. 950 million go to hardcoded wallet address and remaining 50 million
            will stay on contract balance and will get distributed through sendCoins() function by approved contracts
     **/
    constructor() ERC20("NCCoin", "NCC") {
        _mint(address(this), 50000000 ether);
        _mint(
            address(0x12ea4A07Cd993f1708c1E8c4EE33a004109BbCd1),
            950000000 ether
        );
    }

    modifier onlyApprovedContracts() {
        bool approved;
        for (uint256 i = 0; i < approvedContracts.length; i++) {
            if (approvedContracts[i] == msg.sender) {
                approved = true;
                break;
            }
        }
        require(approved, "Function caller is not an approved contract!");
        _;
    }

    function sendCoins(uint256 _amount, address _to)
        public
        onlyApprovedContracts
    {
        require(this.balanceOf(address(this)) - _amount >= 0, "Out of coins!");
        bool success = this.transfer(_to, _amount);
        require(success, "Transfer not successful!");
    }

    function updateApprovedContracts(address[] calldata _newAddresses)
        external
        onlyOwner
    {
        approvedContracts = _newAddresses;
    }
}
