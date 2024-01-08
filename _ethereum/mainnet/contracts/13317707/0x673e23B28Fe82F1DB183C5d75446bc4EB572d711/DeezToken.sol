// contracts/Cheeth.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";

contract DeezToken is ERC20Burnable, Ownable, IERC721Receiver {
    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public dystomiceAddress;
    address public dgld;

    uint256 public burnAmount = 10000000000000000000000;
    uint256 public burnAmountNonGenesis = 5000000000000000000000;

    constructor(address _dystomice, address _dgld) ERC20("DeezToken", "DEEZ") {
        dystomiceAddress = _dystomice; 
        dgld = _dgld;
    }

    function setDystomiceAddress(address _dystomiceAddress) public onlyOwner {
        dystomiceAddress = _dystomiceAddress;
        return;
    }

    function mintDeezWithDgld(uint256 amount) public {
        IERC20(dgld).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        _mint(msg.sender, amount*2);
    }
    function mintDeezWithDystoBurn(uint256[] memory _tokenIds) public {
        require(IERC721(dystomiceAddress).isApprovedForAll(_msgSender(), address(this)), "ERC721Burnable: caller is not owner nor approved");
        for (uint256 i=0; i<_tokenIds.length; i++) {
            if (_tokenIds[i] <= 3000) {
                _mint(msg.sender, burnAmount);
            }
            else {
                _mint(msg.sender, burnAmountNonGenesis);
            }
            IERC721(dystomiceAddress).safeTransferFrom(_msgSender(),address(this),_tokenIds[i]);


        }

    }
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}