// SPDX-License-Identifier: UNLICENSED
/// @title PfpBg
/// @notice PfpBg
/// @author CyberPnk <cyberpnk@pfpbg.cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./FeeLockable.sol";
import "./DestroyLockable.sol";
import "./Ownable.sol";
import "./INftAdapter.sol";
// import "./console.sol";

contract PfpBg is Ownable, FeeLockable, DestroyLockable {

    struct Background {
        string color;
        address nftBgContract;
        uint256 nftBgTokenId;
    }

    mapping (address => address) public bgNftContractToBgAdapterContract;
    mapping (address => Background) public addressToBackground;

    event ChangeBackground(address indexed sender);

    function setColor(string memory color) external {
        require(bytes(color).length <= 6, "Length");
        addressToBackground[msg.sender].color = color;
        emit ChangeBackground(msg.sender);
    }

    function setNft(address nftBgContract, uint256 nftBgTokenId) external payable {
        require(msg.value == feeAmount, "Value");
        require(nftBgContract == address(0) || IERC721(nftBgContract).ownerOf(nftBgTokenId) == msg.sender, "Not yours");
        addressToBackground[msg.sender].nftBgContract = nftBgContract;
        addressToBackground[msg.sender].nftBgTokenId = nftBgTokenId;
        emit ChangeBackground(msg.sender);
    }

    function setBackground(string memory color, address nftBgContract, uint256 nftBgTokenId) external payable {
        require(msg.value == feeAmount, "Value");
        require(nftBgContract == address(0) || IERC721(nftBgContract).ownerOf(nftBgTokenId) == msg.sender, "Not yours");
        addressToBackground[msg.sender].color = color;
        addressToBackground[msg.sender].nftBgContract = nftBgContract;
        addressToBackground[msg.sender].nftBgTokenId = nftBgTokenId;
        emit ChangeBackground(msg.sender);
    }

    function setBgAdapterContractForBgNftContract(address bgNftContract, address bgAdapterContract) onlyOwner external {
        bgNftContractToBgAdapterContract[bgNftContract] = bgAdapterContract;
    }

    constructor() {
    }

    function getBgSvg(address pfpOwner) public view returns(string memory) {
        Background memory background = addressToBackground[pfpOwner];
        
        bytes memory color = bytes(background.color).length > 0 ? abi.encodePacked('<rect y="0" height="640" x="0" width="640" fill="#', background.color, '"/>') : bytes("");
        address bgAdapterContract = bgNftContractToBgAdapterContract[background.nftBgContract];
        string memory nft = "";
        if (bgAdapterContract != address(0)) {
            INftAdapter bgAdapter = INftAdapter(bgAdapterContract);
            if (bgAdapter.ownerOf(background.nftBgTokenId) == pfpOwner) {
                nft = bgAdapter.getEmbeddableSvg(background.nftBgTokenId);
            }
        }

        return string(abi.encodePacked(color, nft));
    }

    function withdraw() external {
        payable(feePayee).transfer(address(this).balance);
    }
}
