// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "./ERC721Tradable.sol";
import "./IRestore.sol";
import "./Ownable.sol";
import "./Counters.sol";

// ██████╗ ███████╗    ███████╗████████╗ ██████╗ ██████╗ ███████╗
// ██╔══██╗██╔════╝    ██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
// ██████╔╝█████╗█████╗███████╗   ██║   ██║   ██║██████╔╝█████╗  
// ██╔══██╗██╔══╝╚════╝╚════██║   ██║   ██║   ██║██╔══██╗██╔══╝  
// ██║  ██║███████╗    ███████║   ██║   ╚██████╔╝██║  ██║███████╗
// ╚═╝  ╚═╝╚══════╝    ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝

contract Restore is ERC721Tradable, Ownable, IRestore {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // A mapping of all frozen tokens
    mapping(uint256 => address) buyers;

    // A reference to the Justice contract for security checks
    address public justice;

    constructor(
        address _proxyRegistryAddress
    ) ERC721Tradable('Restore', 'REST', _proxyRegistryAddress) {}

    /**
     * @dev Link to contract metadata
    */
    function contractURI() external pure returns (string memory) {
        return "https://arweave.net/2IKze9wYKp_cgwVh19oazm08Zj4uMyRmGcUPv1aT7do";
    }

    /** @notice Set the royalties for the whole contract. Our intention is to set it to 10% in perpetuity.
     *  @param recipient the royalties recipient - will always be pr1s0nart, for regulatory reasons.
     *  @param value royalties value (between 0 and 10000)
    */
    function setRoyalties(address recipient, uint256 value) 
        external 
        onlyOwner
    {
        _setRoyalties(recipient, value);
    }

    /**
     * @dev Safely mints a token to an address with a tokenURI.
     * @notice this mints the NFT to this contract so that we can ensure only the buyer can receive the first transfer and
     *         prove contractually that no-one else can.
     * @param creator this will likely be pr1s0n.art, but may be others in the future. Included here for proper attribution.
     * @param uri full URI to token metadata
     */
    function mintForAuction(address creator, string memory uri)
        external
        override
        onlyOwner
        returns (uint256 tokenId)
    {
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(creator, address(this), newTokenId);
        _setTokenURI(newTokenId, uri);
        _tokenIdCounter.increment();
        onERC721Received(creator, address(0), newTokenId, bytes("New token ready for auction"));
        emit ReadyForAuction(address(this), newTokenId, uri);
        return(newTokenId);
    }

    /**
     * @notice sends 'frozen' NFT to the winning bidder by attaching the receipt. Protected only to ensure no random
     *         data is uploaded on the transfer.
     * @param data URI to receipt metadata that will be added to the NFT
     */
    function transferToBuyer(uint256 tokenId, bytes memory data)
        external
        override
        onlyOwner
    {
        emit ArtTransferred(buyers[tokenId], tokenId, data);
        _safeTransfer(address(this), buyers[tokenId], tokenId, data);
    }

    /**
     * @notice called when an auction is settled, sets the frozenToken struct.
     * @param buyer address of winning bid
     * @param tokenId index of the NFT bought in the auction
     */
    function freeze(address buyer, uint256 tokenId) 
        external
        override
    {
        require(msg.sender == justice, "Restore: auctioned piece must be frozen by owner via Justice");
        buyers[tokenId] = buyer;
        emit ArtFrozen(buyer, tokenId);
    }

    /**
     * @notice called by the owner to make sure the checks in freeze and transferToBuyer pass correctly
     * @param _justice the address of the justice contract
     */
    function setJustice(address _justice) 
        external 
        onlyOwner 
    {
        justice =_justice;
    }

    /**
     * @notice called by Justice to ensure that this token exists and can be auctioned before creating an auction
     * @param tokenId the tokenId to be checked for auction
     */
    function auctionable(uint256 tokenId) 
        external 
        view 
        override
        returns (bool) 
    {
        require(_exists(tokenId), "Restore: unknown token");
        return address(0) == buyers[tokenId];
    }

}
