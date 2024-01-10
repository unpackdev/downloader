// SPDX-License-Identifier: UNLICENSED
/// @title PerfectPunks
/// @notice Perfect Punks
/// @author CyberPnk <cyberpnk@perfectpunks.cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./INftRenderer.sol";
import "./RenderContractLockable.sol";
// import "./console.sol";

contract PerfectPunks is ERC721, IERC721Receiver, Ownable, ReentrancyGuard, RenderContractLockable {
    address public v1WrapperContract;
    address public v2WrapperContract;
    IERC721 v1Wrapper;
    IERC721 v2Wrapper;

    function wrap(uint16 _punkId) external nonReentrant {
        require(v1Wrapper.ownerOf(uint(_punkId)) == msg.sender && v2Wrapper.ownerOf(uint(_punkId)) == msg.sender, "Not yours");
        v1Wrapper.safeTransferFrom(msg.sender, address(this), uint(_punkId));
        v2Wrapper.safeTransferFrom(msg.sender, address(this), uint(_punkId));
        _mint(msg.sender, uint(_punkId));
    }

    function unwrap(uint16 _punkId) external nonReentrant {
        require (ownerOf(uint(_punkId)) == msg.sender, "Not yours");
        _burn(uint(_punkId));
        v1Wrapper.safeTransferFrom(address(this), msg.sender, uint(_punkId));
        v2Wrapper.safeTransferFrom(address(this), msg.sender, uint(_punkId));
    }

    function tokenURI(uint256 itemId) public view override returns (string memory) {
        return INftRenderer(renderContract).getTokenURI(itemId);
    }

    function contractURI() external view returns(string memory) {
        return INftRenderer(renderContract).getContractURI(owner());
    }

    function onERC721Received(address, address, uint256, bytes memory) override public pure returns(bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    constructor(address _v1WrapperContract, address _v2WrapperContract) ERC721("PerfectPunks","PERFECTPUNKS") Ownable() {
        v1WrapperContract = _v1WrapperContract;
        v2WrapperContract = _v2WrapperContract;
        v1Wrapper = IERC721(_v1WrapperContract);
        v2Wrapper = IERC721(_v2WrapperContract);
    }

}
