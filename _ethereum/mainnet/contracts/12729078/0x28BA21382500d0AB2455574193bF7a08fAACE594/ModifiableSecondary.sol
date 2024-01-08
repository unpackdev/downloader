// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./IModifiableMain.sol";
import "./Ownable.sol";

contract ModifiableSecondary is ERC20, Ownable {
    using SafeMath for uint256;

    // amount of CMDFT you get after NT purhase
    uint256 public constant DEFAULT_ALOTMENT = 1024 * (10 ** 18);
    address public _pieceAddress;

    // CMDFT related
    uint256 public emissionStart;
    uint256 public emissionEnd; 
    mapping(uint256 => uint256) private _lastClaim;
    
    constructor (uint256 saleStart, string memory name, string memory symbol) ERC20(name, symbol){
        emissionStart = saleStart;
        // in 1024 days
        emissionEnd = saleStart.add(86400 * 1024);
    }

    /**
     * @dev Called right after deployment of Main contract
     */
    function setPieceAddress(address pieceAddress) onlyOwner public {
        require(_pieceAddress == address(0), "Already set");
        _pieceAddress = pieceAddress;
    }

    /**
     * @dev When accumulated last CMDFT.
     */
    function lastClaim(uint256 tokenId) public view returns (uint256) {
        require(IModifiableMain(_pieceAddress).ownerOf(tokenId) != address(0), "Owner cannot be 0 address");
        require(tokenId < IModifiableMain(_pieceAddress).totalSupply(), "NFT at index has not been minted yet");
        require(tokenId > 0, "NFT pieceId (tokenId) numerations starts with 1");
        uint256 lastClaimed = _lastClaim[tokenId] != 0 ? _lastClaim[tokenId] : emissionStart;
        return lastClaimed;
    }
    
    /**
     * @dev Accumulated CMDFT for each NFT piece.
     */
    function accumulated(uint256 tokenId) public view returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");
        require(IModifiableMain(_pieceAddress).ownerOf(tokenId) != address(0), "Owner cannot be 0 address");
        require(tokenId < IModifiableMain(_pieceAddress).totalSupply(), "NFT at index has not been minted yet");
        require(tokenId > 0, "NFT pieces start with index 0");

        uint256 lastClaimed = lastClaim(tokenId);

        // Sanity check if last claim was after emission end
        if (lastClaimed >= emissionEnd){
            return 0;
        }

        uint256 accumulationPeriodFinishTs = block.timestamp < emissionEnd ? block.timestamp : emissionEnd; // Getting the min value of both
        uint256 tokenArea;
        uint256 color;
        if (IModifiableMain(_pieceAddress).startingIndex() == 0){
            // before the reveal the area of ownable token is unknown -> use mean area == 11
            tokenArea = 11;
        } else {
            (tokenArea, color) = IModifiableMain(_pieceAddress).getTraitsOfTokenId(tokenId);
        }
        
        // acumulated is proportional to token Area
        uint256 totalAccumulated = (accumulationPeriodFinishTs.sub(lastClaimed)).mul(10**18).mul(tokenArea).div(86400);

        // If claim hasn't been done before for the index, add initial allotment (plus prereveal multiplier if applicable)
        if (lastClaimed == emissionStart) {
            uint256 initialAllotment = IModifiableMain(_pieceAddress).isMintedBeforeReveal(tokenId) == true ? 
                DEFAULT_ALOTMENT.mul(2) : DEFAULT_ALOTMENT;
            totalAccumulated = totalAccumulated.add(initialAllotment);
        }

        return totalAccumulated;
    }

    /**
     * @dev Claim mints CMDFT and supports multiple NFT piece tokens indices at once.
     */
    function claim(uint256[] memory tokenIds) public returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            // only allowed for NFT pieces, not masterpiece
            require(tokenIds[i] > 0, "NFT pieces start with index 0");
            // Sanity check for non-minted index
            require(tokenIds[i] < IModifiableMain(_pieceAddress).totalSupply(), "NFT at index has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token index");
            }

            uint tokenId = tokenIds[i];
            require(IModifiableMain(_pieceAddress).ownerOf(tokenId) == msg.sender, "Sender is not the owner");

            uint256 claimQty = accumulated(tokenId);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenId] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "No accumulated CMDFT");
        _mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }

    /**
     * @dev Burns CMDFT quantity of tokens held by the caller. Only allowed
     * to call from main contract. So if for some reason you need to burn CMDFT
     * - go to main contract and call funtion with same name - "burnCMDFT"
     */
    function burnCMDFT(uint256 burnQuantity, address user) public returns (bool) {
        // msg.sender - is address of contract
        require(_pieceAddress != address(0), "Main contract address should be set");
        require(msg.sender == _pieceAddress, "Could only be called from main contract");
        
        // we passing user as pararmeter
        _burn(user, burnQuantity);
        return true;
    }
}


