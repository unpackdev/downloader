// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @author jpegmint.xyz

import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

/*
 ██████╗ ██████╗ ███████╗███╗   ███╗██╗     ██╗███╗   ██╗███████╗    ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
██╔════╝ ██╔══██╗██╔════╝████╗ ████║██║     ██║████╗  ██║██╔════╝    ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝
██║  ███╗██████╔╝█████╗  ██╔████╔██║██║     ██║██╔██╗ ██║███████╗    ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ 
██║   ██║██╔══██╗██╔══╝  ██║╚██╔╝██║██║     ██║██║╚██╗██║╚════██║    ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  
╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║███████╗██║██║ ╚████║███████║    ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   
 ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   
*/                                                                                               
abstract contract GremlinsERC721Proxy is Proxy {

    /// Storage slot with the address of the gremlins contract
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;


    //  ██████╗ ██████╗ ███╗   ██╗███████╗████████╗██████╗ ██╗   ██╗ ██████╗████████╗ ██████╗ ██████╗ 
    // ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
    // ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ██████╔╝██║   ██║██║        ██║   ██║   ██║██████╔╝
    // ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██╗██║   ██║██║        ██║   ██║   ██║██╔══██╗
    // ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║╚██████╔╝╚██████╗   ██║   ╚██████╔╝██║  ██║
    //  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

    /// Constructor
    constructor(address logic, string memory name_, string memory symbol_) {
        
        // Store logic address
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = logic;

        // Initialize contract
        bytes memory data = abi.encodeWithSignature("initialize(string,string)", name_, symbol_);
        Address.functionDelegateCall(_implementation(), data);
    }


    // ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
    // ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝
    // ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ 
    // ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  
    // ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   
    // ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   

    /**
     * @dev Returns the stored implementation address.
     */
    function _implementation() internal view virtual override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Check if function is supported via beforeFallback hook.
     */
    function _beforeFallback() internal virtual override {
        require(supportsFunction(msg.sig), "?");
        super._beforeFallback();
    }

    /**
     * @dev Returns whether function selector is in known set of proxied functions.
     */
    function supportsFunction(bytes4 functionId) public pure returns(bool) {
        return
            // ERC721 Functions
            functionId == 0x70a08231 || // _FUNCTION_ID_BALANCE_OF = bytes4(keccak256("balanceOf(address)"))
            functionId == 0x6352211e || // _FUNCTION_ID_OWNER_OF = bytes4(keccak256("ownerOf(uint256)"))
            functionId == 0x42842e0e || // _FUNCTION_ID_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256)"))
            functionId == 0xb88d4fde || // _FUNCTION_ID_SAFE_TRANSFER_FROM_DATA = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"))
            functionId == 0x23b872dd || // _FUNCTION_ID_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"))
            functionId == 0x095ea7b3 || // _FUNCTION_ID_APPROVE = bytes4(keccak256("approve(address,uint256)"))
            functionId == 0xa22cb465 || // _FUNCTION_ID_SET_APPROVAL_FOR_ALL = bytes4(keccak256("setApprovalForAll(address,bool)"))
            functionId == 0x081812fc || // _FUNCTION_ID_GET_APPROVED = bytes4(keccak256("getApproved(uint256)"))
            functionId == 0xe985e9c5 || // _FUNCTION_ID_IS_APPROVED_FOR_ALL = bytes4(keccak256("isApprovedForAll(address,address)"))

            // ERC721Metadata Functions
            functionId == 0x06fdde03 || // _FUNCTION_ID_NAME = bytes4(keccak256("name()"))
            functionId == 0x95d89b41 || // _FUNCTION_ID_SYMBOL = bytes4(keccak256("symbol()"))
            functionId == 0xc87b56dd || // _FUNCTION_ID_TOKEN_URI = bytes4(keccak256("tokenURI(uint256)"))
            functionId == 0x162094c4 || // _FUNCTION_ID_SET_TOKEN_URI = bytes4(keccak256("setTokenURI(uint256,string)"))
            functionId == 0x6c0360eb || // _FUNCTION_ID_BASE_URI = bytes4(keccak256("baseURI()"))
            functionId == 0x55f804b3 || // _FUNCTION_ID_SET_BASE_URI = bytes4(keccak256("setBaseURI(string)"))

            // ERC721Burnable Function
            functionId == 0x42966c68 || // _FUNCTION_ID_BURN = bytes4(keccak256("burn(uint256)"))

            // Ownable Functions
            functionId == 0x8da5cb5b || // _FUNCTION_ID_OWNER = bytes4(keccak256("owner()"))
            functionId == 0x715018a6 || // _FUNCTION_ID_RENOUNCE_OWNERSHIP = bytes4(keccak256("renounceOwnership()"))
            functionId == 0xf2fde38b || // _FUNCTION_ID_TRANSFER_OWNERSHIP = bytes4(keccak256("transferOwnership(address)"))

            // Royalties
            functionId == 0xbb3bafd6 || // _FUNCTION_ID_GET_ROYALTIES = bytes4(keccak256("getRoyalties(uint256)"))
            functionId == 0x2a55205a || // _FUNCTION_ID_ROYALTY_INFO = bytes4(keccak256("royaltyInfo(uint256,uint256)"))
            functionId == 0x8c7ea24b || // _FUNCTION_ID_SET_ROYALTIES = bytes4(keccak256("setRoyalties(address,uint256)"))

            // ERC165 Functions
            functionId == 0x01ffc9a7    // _FUNCTION_ID_SUPPORTS_INTERFACE = bytes4(keccak256("supportsInterface(bytes4)"))
        ;
    }
}
