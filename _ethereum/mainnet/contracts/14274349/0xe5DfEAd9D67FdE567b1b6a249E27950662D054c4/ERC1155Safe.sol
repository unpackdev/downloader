pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC1155.sol";
import "./ERC1155MinterBurnerPauser.sol";

/**
    @title Manages deposited ERC1155s.
    @author ChainSafe Systems.
    @notice This contract is intended to be used with ERC1155Handler contract.
 */
contract ERC1155Safe {
    using SafeMath for uint256;

    /**
        @notice Used to transfer tokens into the safe to fund proposals.
        @param tokenAddress Address of ERC1155 contract address.
        @param owner Address of current token owner.
        @param tokenID ID of token to transfer.
        @param amount The amount of a specific tokenID to send
        @param extraData The required data param on transfers (not used by all 1155's)
     */
    function fundERC1155(address tokenAddress, address owner, uint tokenID, uint amount, bytes memory extraData) public {
        IERC1155 erc1155 = IERC1155(tokenAddress);
        erc1155.safeTransferFrom(owner, address(this), tokenID, amount, extraData);
    }

    /**
        @notice Used to gain custoday of deposited token.
        @param tokenAddress Address of ERC1155 contract address.
        @param owner Address of current token owner.
        @param recipient Address to transfer token to.
        @param tokenID ID of token to transfer.
        @param amount The amount of a specific tokenID to send
        @param extraData The required data param on transfers (not used by all 1155's)

     */
    function lockERC1155(address tokenAddress, address owner, address recipient, uint tokenID, uint amount, bytes memory extraData) internal {
        IERC1155 erc1155 = IERC1155(tokenAddress);
        erc1155.safeTransferFrom(owner, recipient, tokenID, amount, extraData);
    }

    /**
        @notice Transfers custody of token to recipient.
        @param tokenAddress Address of ERC1155 contract address.
        @param owner Address of current token owner.
        @param recipient Address to transfer token to.
        @param tokenID ID of token to transfer.
        @param amount The amount of a specific tokenID to send
        @param extraData The required data param on transfers (not used by all 1155's)
     */
    function releaseERC1155(address tokenAddress, address owner, address recipient, uint256 tokenID, uint amount, bytes memory extraData) internal {
        IERC1155 erc1155 = IERC1155(tokenAddress);
        erc1155.safeTransferFrom(owner, recipient, tokenID, amount, extraData);
    }

    /**
        @notice Used to create new ERC1155s.
        @param tokenAddress Address of ERC1155 to mint.
        @param recipient Address to mint token to.
        @param tokenID ID of token to mint.
        @param extraData Optional data to send along with mint call.
     */
    function mintERC1155(address tokenAddress, address recipient, uint256 tokenID, uint amount, bytes memory metadata, bytes memory extraData) internal {
        ERC1155MinterBurnerPauser erc1155 = ERC1155MinterBurnerPauser(tokenAddress);
        erc1155.mint(recipient, tokenID, amount, string(metadata), extraData);
    }

    /**
        @notice Used to burn ERC1155s.
        @param tokenAddress Address of ERC1155 to burn.
        @param owner Address of account that owns the tokens being burnt.
        @param tokenID ID of token to burn.
        @param amount of tokenID to burn.
     */
    function burnERC1155(address tokenAddress, address owner, uint256 tokenID, uint amount) internal {
        ERC1155MinterBurnerPauser erc1155 = ERC1155MinterBurnerPauser(tokenAddress);
        erc1155.burn(owner, tokenID, amount);
    }

    // Accept transfers from ERC1155 contracts; part of the spec.
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4) {
        // From the spec: 
        // This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        
        // Should we be more choosy here? If someone sends the handler a token without first going through
        // the bridge they'll need admin intervention to get it back.
        return 0xf23a6e61;
    }
}
