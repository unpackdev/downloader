// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721.sol";
import "./ECDSA.sol";

contract Ox is ERC721 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    address public owner;
    uint8 public limit;
    
    constructor(address _owner) ERC721("Year of the 0x", "OX") {
        owner = _owner;
        limit = 100;
        _setBaseURI("https://app.oneofthefew.net/ox/");
    }

    function mint(address to) public payable {
        require(totalSupply() < limit, "sold_out");
        require(msg.value >= 1 ether, "invalid_amount");

        string memory suffix = ".json";
        uint256 index = totalSupply() + 1;

        _mint(to, index);
        _setTokenURI(index, string(abi.encodePacked(uint2str(index), suffix)));
    }

    function withdraw(IERC20 token, uint256 amount) public {
        require(owner == msg.sender, "unauthorized");
        token.safeTransfer(msg.sender, amount);
    }

    function withdrawETH(uint256 amount) public {
        require(owner == msg.sender, "unauthorized");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "transfer_failed");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}