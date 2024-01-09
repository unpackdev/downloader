// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./CROWDValidator.sol";
import "./ICROWDToken.sol";

contract CrowdBridge is Ownable, CROWDValidator {
    mapping(address => bool) public registContract;

    //Don't accept ETH or BNB
    receive() external payable {
        revert("Don't accept ETH");
    }

    function registContrac(address from_address) public onlyOwner {
        require(isContract(from_address) == true, "from_address is not contract.");
        registContract[from_address] = true;
    }

    event LogTransferToNetwork(address indexed to_account, uint256 amount, string to_network);
    event LogTransferFromNetwork(string from_network, bytes32 indexed txhash, address indexed to_account, uint256 indexed amount);

    function transferToNetwork(
        address contract_address,
        address to_account,
        uint256 amount,
        string memory to_network
    ) public {
        require(registContract[contract_address], "not registed contract");

        ICROWDToken(contract_address).burnFrom(msg.sender, amount);

        emit LogTransferToNetwork(to_account, amount, to_network);
    }

    function transferFromNetwork(
        address contract_address,
        uint256 id,
        string memory from_network,
        bytes32 txhash,
        uint256 amount,
        uint256 expired_at,
        bytes memory signature
    ) public {
        require(registContract[contract_address], "not regited contract");

        //verify signature
        verify("transferFromNetwork", id, msg.sender, amount, contract_address, expired_at, getValidator(contract_address), signature);

        ICROWDToken(contract_address).mint(msg.sender, amount);

        emit LogTransferFromNetwork(from_network, txhash, msg.sender, amount);
    }
}
