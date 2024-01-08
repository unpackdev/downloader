//                        ROGUE TITANS
//
// MMMMMMXk;.;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:':kNMMMMMM
// MMWXkl;.   .,lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMWXko;.   .;oOXWMM
// 0xc'.         ..:d0NMMMMMMMMMMMMMMMMMMMMN0xc'.         .'cxK
// .                 .,lkXWMMMMMMMMMMMMWXOo;.                 .
//                      .'cx0NMMMMMMWKxc'.                     
//                          .:kNNKOo;.                         
//          ;dc'.         .,cllc'..              ..:o;         
//         .lNWXOo;.   .;clc;.                .,lkXWNl.        
//         .lNMMMMN0dlllc,.               ..:d0NMMMMWl.        
//         .lNMMMMN0d:..               .,cllld0NMMMMNl.        
//         .lNWXkl,.                .;llc;..  .;okXWNl.        
//          ;o:..              .,;cllc,.         .'cd;         
//                          .;oONWNk:.                         
//                      .'cxKWMMMMMMN0xc'.                     
// .                 .;oOXWMMMMMMMMMMMMWXkl,.                 .
// Kxc'.         .'cxKWMMMMMMMMMMMMMMMMMMMMN0d:..         .'cd0
// MMWXOo;.   .;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,.   .,lkXWMM
// MMMMMMNk:':kXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx;.:kXMMMMMM
//                                                                                            
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721URIStorage.sol";
import "./ERC1155.sol";
import "./IERC20.sol";

contract Temple is ERC721URIStorage, ReentrancyGuard, Ownable {
    
    using Strings for uint256;

    event Activate();
    event Deactivate();
    event Initialize();

    bool public isSaleActive = false;

    uint256 constant public maxMintAtOnce = 50;
    address constant public traceBurnAddress = 0x0000000000000000000000000000000000000000;
    address constant public fragmentBurnAddress = 0x000000000000000000000000000000000000dEaD;

    // For Trace usage
    address public traceContract;
    uint256 constant public tracePerTemple = 100;

    // For Fragment usage
    address public fragmentContract;
    uint256 constant public fragmentPerTemple = 1;
    uint256 constant public fragmentId = 1;

    uint256 constant public maxTemplesFromFragments = 1477;
    uint256 constant public maxTemplesFromTrace = 9706;

    uint256 public currFragmentTempleIDPointer = 0;
    uint256 public currTraceTempleIDPointer = maxTemplesFromFragments;

    string public baseURI;
    
    constructor() ERC721("Temple", "TMPL") {
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    // Toggle Activate/Deactivate ability to smelt fragments
    function toggleSale() public onlyOwner {
        isSaleActive = !isSaleActive;

        if (isSaleActive == true) {
            emit Activate();
        } else {
            emit Deactivate();
        }
    }

    // Initialize the sale
    function initializeSale(address traceContract_, address fragmentContract_, string memory baseURI_) public onlyOwner {
        require(!isSaleActive, "First disable Temple Minting to re-initialize.");

        traceContract = traceContract_;
        fragmentContract = fragmentContract_;
        baseURI = baseURI_;

        emit Initialize();
    }

    // Mint a temple using Fragments
    function mintTempleWithFragments(uint256 numTemplesToMint) external nonReentrant {
        ERC1155 fragmentTokenImpl = ERC1155(fragmentContract);
        uint256 fragmentBurnAmount = numTemplesToMint * fragmentPerTemple;

        require(isSaleActive, "Sale is not active at this time.");
        require(numTemplesToMint > 0 && numTemplesToMint <= maxMintAtOnce, "Must mint between 1 and 50 Temples");

        require((currFragmentTempleIDPointer + numTemplesToMint) <= maxTemplesFromFragments, "Requested count for Fragment Temples exceeds the maximum number of Fragment Temples.");
    
        require(fragmentTokenImpl.balanceOf(msg.sender, fragmentId) >= (fragmentBurnAmount), "You do not have enough Fragments to mint your Temples.");
        
        try fragmentTokenImpl.safeTransferFrom(msg.sender, address(fragmentBurnAddress), fragmentId, fragmentBurnAmount, "0x") {
        } catch (bytes memory) {
            revert("Burn failure");
        }
    
        for (uint i = 0; i < numTemplesToMint; i++) {
            currFragmentTempleIDPointer++;
            _safeMint(msg.sender, currFragmentTempleIDPointer);
            _setTokenURI(currFragmentTempleIDPointer, Strings.toString(currFragmentTempleIDPointer));
        }
    }

    // Mint a temple using Trace
    function mintTempleWithTrace(uint256 numTemplesToMint) external nonReentrant {
        IERC20 traceTokenImpl = IERC20(traceContract);
        uint256 traceBurnAmount = numTemplesToMint * tracePerTemple;

        require(isSaleActive, "Sale is not active at this time.");
        require(numTemplesToMint > 0 && numTemplesToMint <= maxMintAtOnce, "Must mint between 1 and 50 Temples");
        
        require((currTraceTempleIDPointer + numTemplesToMint - maxTemplesFromFragments) <= maxTemplesFromTrace, "Requested count for Trace Temples exceeds the maximum number of Trace Temples.");

        require(traceTokenImpl.balanceOf(msg.sender) >= (traceBurnAmount), "You do not have enough $TRCE to mint your Temples.");
        
        try traceTokenImpl.transferFrom(msg.sender, address(traceBurnAddress), traceBurnAmount) {
        } catch (bytes memory) {
            revert("Failed to burn $TRCE - Please verify that you have approved the correct number of tokens. Reverting.");
        }

        for (uint i = 0; i < numTemplesToMint; i++) {
            currTraceTempleIDPointer++;
            _safeMint(msg.sender, currTraceTempleIDPointer);
            _setTokenURI(currTraceTempleIDPointer, Strings.toString(currTraceTempleIDPointer));
        }
    }
}