pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./BrokeBoyz.sol";


contract BigBoyGenerator is Ownable, IERC721Receiver {

    BrokeBoyz brokeBoyz;
    uint256 public burnAmount;

    constructor(address _brokeBoyz) { 
        brokeBoyz = BrokeBoyz(_brokeBoyz);
        burnAmount = 4;
    }

    function setBurnAmount(uint256 newBurnAmount) external onlyOwner {
        burnAmount = newBurnAmount;
    }

    function burnFourBblocks(uint256[] calldata tokenIds) external {
        require(tokenIds.length == burnAmount, "Exactly BURNAMOUNT tokens must be sent! check in contract"); 

        for (uint i = 0; i < tokenIds.length; i++) {
            require(brokeBoyz.ownerOf(tokenIds[i]) == _msgSender(), "Token isn't yours!");
        }

        for (uint i = 0; i < tokenIds.length; i++) {
            // TODO will need transfer privilage for this
            brokeBoyz.transferFrom(_msgSender(), address(this), tokenIds[i]);
            brokeBoyz.burn(tokenIds[i]);
        }
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cant mint to this address");
      return IERC721Receiver.onERC721Received.selector;
    }

    
}