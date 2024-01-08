pragma solidity ^0.8.0;

import "./IERC1155Receiver.sol";
import "./IERC1155.sol";

contract CitizenApp is IERC1155Receiver {
    address contractAddress = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    uint256 tokenAddress = 23487195805935260354348650824724952235377320432154855752878351301067508033245;
     address citydao = 0x33eD481F752f05A292346C71E16aFbB0fE548656;
    //  address contractAddress = 0x765Edd758Df2E7b7bd72b46c258e17Ec03B59772;
    //  uint256 tokenAddress = 0;
     uint256 tokens;
    
      function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) {
          tokens = tokens + value;
          return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
        }
    
    
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns(bytes4) {
            return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256,uint256,bytes)"));
        }
    function buyNFT() payable public {
        require(tokens > 0, "out of NFTs");
        require(msg.value == 0.25 ether, "Send exactly 0.25 ETH");
        citydao.call{value: 0.25 ether}("");
        IERC1155 nft = IERC1155(contractAddress);
        nft.safeTransferFrom(address(this), msg.sender, tokenAddress, 1, "");
        tokens--;
    }
    function supportsInterface(bytes4 interfaceID) override external view returns (bool) {
    return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }
    function tokensCount() public view returns (uint) { 
        return tokens;
    }

}