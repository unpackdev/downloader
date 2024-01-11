// SPDX-License-Identifier: MIT
/**
  __  __              _   _                          _     _____                ____  
 |  \/  |            | | (_)                        | |   |  __ \      /\      / __ \ 
 | \  / |   ___    __| |  _    ___  __   __   __ _  | |   | |  | |    /  \    | |  | |
 | |\/| |  / _ \  / _` | | |  / _ \ \ \ / /  / _` | | |   | |  | |   / /\ \   | |  | |
 | |  | | |  __/ | (_| | | | |  __/  \ V /  | (_| | | |   | |__| |  / ____ \  | |__| |
 |_|  |_|  \___|  \__,_| |_|  \___|   \_/    \__,_| |_|   |_____/  /_/    \_\  \____/ 
                                                                                      
 */
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721Upgradeable.sol";

import "./IL1CrossDomainMessenger.sol";

import "./MedievalAccessControlled.sol";
import "./IMedievalNFT721.sol";

contract L1NFTBridge is Initializable, MedievalAccessControlled {
    IL1CrossDomainMessenger public immutable ovmL1CrossDomainMessenger;
    IMedievalNFT721 public immutable medievalNFT;
    address public l2NFT;

    function initialize(
        address _controlCenter
    ) initializer public {
        _setControlCenter(_controlCenter, tx.origin); 
    }

    constructor(
        IL1CrossDomainMessenger _ovmL1CrossDomainMessenger,
        IMedievalNFT721 _medievalNFT
    ) initializer {
        ovmL1CrossDomainMessenger = _ovmL1CrossDomainMessenger;
        medievalNFT = _medievalNFT;
    }

    function setL2NFT(address _l2NFT) external onlyAdmin {
        l2NFT = _l2NFT;
    }

    function releaseNFT(address to, uint256 tokenId) external {
        require(
        msg.sender == address(ovmL1CrossDomainMessenger)
            && ovmL1CrossDomainMessenger.xDomainMessageSender() == l2NFT
        );
        
        medievalNFT.transferFrom(address(this), to, tokenId);
    }

    function bridgeToL2(uint256 tokenId) external {
        medievalNFT.transferFrom(msg.sender, address(this), tokenId);
        require(l2NFT != address(0), "L1NFTBridge: L2NFT hasn't beent set");
        
        ovmL1CrossDomainMessenger.sendMessage(
            l2NFT,
            abi.encodeWithSignature(
                "mint(address,uint256,uint256,uint16,uint256)",
                msg.sender,
                tokenId,
                medievalNFT.seed(tokenId),
                medievalNFT.tokenOccupation(tokenId),
                medievalNFT.tokenLevel(tokenId)
            ),
            1000000 // use whatever gas limit you want
        );
    }
}

