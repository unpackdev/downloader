// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract MultiSend is Ownable {
    using SafeMath for uint256;

    /**
     * @dev airdrop to address
     * @param _tokenAddr address the erc20 token address
     * @param dests address[] addresses to airdrop
     * @param values uint256[] value(in ether) to airdrop
     */
    function sendERC20(
        address _from,
        address _tokenAddr,
        address[] calldata dests,
        uint256[] calldata values
    ) public returns (bool) {
        for (uint256 index = 0; index < dests.length; index++) {
            ERC20(_tokenAddr).transferFrom(
                _from,
                dests[index],
                values[index].mul(10**18)
            );
        }
        return true;
    }

    /*
     * @dev airdrop to address
     * @param dests address payable[] addresses to airdrop
     * @param values uint256[] value(in ether) to airdrop
     */
    function sendEth(
        address payable[] calldata dests,
        uint256[] calldata values
    ) public payable returns (bool) {
        uint256 sendVal = msg.value;
        uint256 sumVal;
        for (uint256 index = 0; index < values.length; index++) {
            sumVal = sumVal.add(values[index]);
        }
        require(sendVal >= sumVal, "Exceed eth amount");
        for (uint256 addrIndex = 0; addrIndex < dests.length; addrIndex++) {
            dests[addrIndex].transfer(values[addrIndex]);
        }
        return true;
    }

    function claim(address token, uint256 val) public onlyOwner {
        address contractAddress = address(this);
        address payable owner = address(uint160(owner()));
        if (token == address(0)) {
            require(contractAddress.balance >= val, "Exceed amount");
            owner.transfer(val);
        } else {
            uint256 balance = ERC20(token).balanceOf(contractAddress);
            ERC20(token).transfer(owner, balance);
        }
    }
}
